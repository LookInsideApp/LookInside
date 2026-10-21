#!/usr/bin/env python3
"""Scenario driver for Scripts/e2e-reconnect.sh.

Runs against a DEBUG Host that already holds a live document on the target
app (LOOKINSIDE_DEBUG_E2E_KEEP_OPEN=1) and watches three sources:

  - the Host's MCPBridge socket (newline-delimited JSON frames): requests,
    and the targets.disconnected / hierarchy.reloaded events;
  - the session log (LOOKINSIDE_DEBUG_E2E_SESSION_LOG): one JSON line per
    event LiveDocument.handle(_:) applied, with the banner after it;
  - `log stream --style ndjson` of the Host process (subsystem
    com.lookinside.app).

Each scenario ends, pauses or backgrounds the app and asserts what the Host
did and how fast. Prints a PASS/FAIL table; exits 1 when a check failed.
"""

import argparse
import datetime
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time


def env_float(name, default):
    value = os.environ.get(name, "")
    try:
        return float(value) if value else default
    except ValueError:
        return default


# Every limit is configurable from the environment.
TIMEOUTS = {
    "open": env_float("E2E_OPEN_TIMEOUT", 180),
    "disconnect": env_float("E2E_DISCONNECT_TIMEOUT", 2),
    "reconnect": env_float("E2E_RECONNECT_TIMEOUT", 8),
    "background": env_float("E2E_BACKGROUND_TIMEOUT", 1),
    "foreground_refresh": env_float("E2E_FOREGROUND_REFRESH_TIMEOUT", 6),
    "stop_silence": env_float("E2E_STOP_SILENCE", 6),
    "silent_close": env_float("E2E_SILENT_CLOSE_TIMEOUT", 4),
    "pending_failure": env_float("E2E_PENDING_FAILURE_TIMEOUT", 1),
    "refresh_after_reconnect": env_float("E2E_REFRESH_AFTER_RECONNECT_TIMEOUT", 15),
    "settle": env_float("E2E_SETTLE", 3),
}


def log(message):
    stamp = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[e2e {stamp}] {message}", flush=True)


# MARK: - Sources


class MCPClient:
    """One connection to the MCPBridge socket; frames are read on a thread."""

    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(path)
        self.lock = threading.Condition()
        self.responses = {}
        self.events = []
        self.next_id = 0
        self.closed = False
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        buffer = b""
        while True:
            try:
                chunk = self.sock.recv(65536)
            except OSError:
                chunk = b""
            if not chunk:
                with self.lock:
                    self.closed = True
                    self.lock.notify_all()
                return
            buffer += chunk
            while b"\n" in buffer:
                line, buffer = buffer.split(b"\n", 1)
                if not line.strip():
                    continue
                now = time.time()
                try:
                    frame = json.loads(line)
                except ValueError:
                    continue
                with self.lock:
                    if frame.get("kind") == "response":
                        self.responses[frame.get("id")] = (now, frame)
                    elif frame.get("kind") == "event":
                        self.events.append((now, frame.get("topic"), frame.get("payload") or {}))
                    self.lock.notify_all()

    def send(self, method, params=None):
        with self.lock:
            self.next_id += 1
            identifier = f"e2e-{self.next_id}"
        frame = {"kind": "request", "id": identifier, "method": method}
        if params is not None:
            frame["params"] = params
        self.sock.sendall(json.dumps(frame).encode() + b"\n")
        return identifier

    def wait_response(self, identifier, timeout):
        deadline = time.time() + timeout
        with self.lock:
            while identifier not in self.responses:
                remaining = deadline - time.time()
                if remaining <= 0 or self.closed:
                    return None, None
                self.lock.wait(remaining)
            return self.responses.pop(identifier)

    def call(self, method, params=None, timeout=60):
        sent = time.time()
        received, frame = self.wait_response(self.send(method, params), timeout)
        return frame, (received - sent if received else None)

    def wait_event(self, predicate, since, timeout):
        deadline = time.time() + timeout
        with self.lock:
            while True:
                for event in self.events:
                    if event[0] >= since and predicate(event[1], event[2]):
                        return event
                remaining = deadline - time.time()
                if remaining <= 0:
                    return None
                self.lock.wait(remaining)


class JSONLinesTail:
    """Follows a JSON-lines file another process appends to."""

    def __init__(self, path, time_of):
        self.path = path
        self.time_of = time_of
        self.offset = 0
        self.partial = b""
        self.entries = []

    def poll(self):
        try:
            with open(self.path, "rb") as handle:
                handle.seek(self.offset)
                data = handle.read()
                self.offset += len(data)
        except FileNotFoundError:
            return
        data = self.partial + data
        lines = data.split(b"\n")
        self.partial = lines.pop()
        for line in lines:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if isinstance(entry, dict):
                entry["_time"] = self.time_of(entry)
                self.entries.append(entry)

    def wait_for(self, predicate, since, timeout):
        deadline = time.time() + timeout
        while True:
            self.poll()
            for entry in self.entries:
                if entry["_time"] >= since and predicate(entry):
                    return entry
            if time.time() >= deadline:
                return None
            time.sleep(0.05)

    def since(self, since):
        self.poll()
        return [entry for entry in self.entries if entry["_time"] >= since]


def session_time(entry):
    return float(entry.get("time", 0))


def os_log_time(entry):
    # "2026-10-21 12:00:00.123456+0800"
    stamp = entry.get("timestamp", "")
    try:
        return datetime.datetime.strptime(stamp, "%Y-%m-%d %H:%M:%S.%f%z").timestamp()
    except ValueError:
        return 0.0


# MARK: - Apps


class SimulatorApp:
    def __init__(self, udid, bundle_id, background_bundle_id):
        self.udid = udid
        self.bundle_id = bundle_id
        self.background_bundle_id = background_bundle_id
        self.supports_background = True

    def _simctl(self, *arguments):
        return subprocess.run(["xcrun", "simctl", *arguments], capture_output=True, text=True)

    def pid(self):
        # The app's process runs from the device's own directory, so this
        # never matches an app on another simulator.
        result = subprocess.run(
            ["pgrep", "-f", f"Devices/{self.udid}/.*/{self.bundle_executable()}.app/"],
            capture_output=True,
            text=True,
        )
        pids = [int(value) for value in result.stdout.split()]
        return pids[0] if pids else None

    def bundle_executable(self):
        return os.environ.get("E2E_APP_NAME", "LookInsideExample")

    def launch(self):
        result = self._simctl("launch", self.udid, self.bundle_id)
        if result.returncode != 0:
            raise RuntimeError(f"simctl launch failed: {result.stderr.strip()}")
        try:
            return int(result.stdout.strip().rsplit(":", 1)[1])
        except (IndexError, ValueError):
            return self.pid()

    def terminate(self):
        self._simctl("terminate", self.udid, self.bundle_id)

    def background(self):
        result = self._simctl("launch", self.udid, self.background_bundle_id)
        if result.returncode != 0:
            raise RuntimeError(f"simctl launch {self.background_bundle_id} failed: {result.stderr.strip()}")

    def foreground(self):
        return self.launch()

    def signal(self, signal_number):
        pid = self.pid()
        if pid:
            os.kill(pid, signal_number)
        return pid

    def cleanup(self):
        pid = self.pid()
        if pid:
            try:
                os.kill(pid, signal.SIGCONT)
            except OSError:
                pass


class MacApp:
    def __init__(self, executable, bundle_id, output_path):
        self.executable = executable
        self.bundle_id = bundle_id
        self.output_path = output_path
        self.process = None
        self.supports_background = False

    def pid(self):
        if self.process and self.process.poll() is None:
            return self.process.pid
        return None

    def launch(self):
        output = open(self.output_path, "ab")
        self.process = subprocess.Popen([self.executable], stdout=output, stderr=output, start_new_session=True)
        output.close()
        return self.process.pid

    def terminate(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(10)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()

    def signal(self, signal_number):
        pid = self.pid()
        if pid:
            os.kill(pid, signal_number)
        return pid

    def cleanup(self):
        if self.process and self.process.poll() is None:
            try:
                os.kill(self.process.pid, signal.SIGCONT)
            except OSError:
                pass
            self.terminate()


# MARK: - Checks


class Results:
    def __init__(self):
        self.rows = []

    def check(self, scenario, name, passed, detail=""):
        self.rows.append((scenario, name, bool(passed), detail))
        log(f"{'PASS' if passed else 'FAIL'} [{scenario}] {name}{' — ' + detail if detail else ''}")
        return bool(passed)

    def skip(self, scenario, name, detail):
        self.rows.append((scenario, name, None, detail))
        log(f"SKIP [{scenario}] {name} — {detail}")

    def print_table(self):
        print()
        print(f"{'Result':<6}  {'Scenario':<22}  {'Check':<46}  Detail")
        print("-" * 120)
        for scenario, name, passed, detail in self.rows:
            label = "SKIP" if passed is None else ("PASS" if passed else "FAIL")
            print(f"{label:<6}  {scenario:<22}  {name:<46}  {detail}")
        failures = sum(1 for row in self.rows if row[2] is False)
        print("-" * 120)
        print(f"{len(self.rows)} checks, {failures} failed")
        return failures


def process_exists(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def seconds(value):
    return "n/a" if value is None else f"{value:.2f}s"


class Driver:
    def __init__(self, arguments, app):
        self.arguments = arguments
        self.app = app
        self.bundle_id = arguments.bundle_id
        self.results = Results()
        self.session = JSONLinesTail(arguments.session_log, session_time)
        self.os_log = JSONLinesTail(arguments.os_log, os_log_time)
        self.mcp = None

    # Sources

    def wait_banner(self, banners, since, timeout):
        """The first session event at or after `since` whose banner is one of
        `banners`."""
        return self.session.wait_for(
            lambda entry: entry.get("banner") in banners and entry.get("bundleIdentifier") in ("", self.bundle_id),
            since,
            timeout,
        )

    def current_banner(self):
        entries = [entry for entry in self.session.since(0) if entry.get("bundleIdentifier") in ("", self.bundle_id)]
        return entries[-1].get("banner") if entries else None

    def wait_reloaded(self, since, timeout, initiator="host"):
        return self.mcp.wait_event(
            lambda topic, payload: topic == "hierarchy.reloaded"
            and payload.get("bundleIdentifier") == self.bundle_id
            and payload.get("initiator") == initiator,
            since,
            timeout,
        )

    def wait_disconnected(self, since, timeout):
        return self.mcp.wait_event(
            lambda topic, payload: topic == "targets.disconnected" and payload.get("bundleIdentifier") == self.bundle_id,
            since,
            timeout,
        )

    def wait_os_log(self, needle, since, timeout):
        return self.os_log.wait_for(lambda entry: needle in entry.get("eventMessage", ""), since, timeout)

    def target_identifier(self):
        frame, _ = self.mcp.call("targets.list", timeout=10)
        for target in ((frame or {}).get("result") or {}).get("targets", []):
            if target.get("bundleIdentifier") == self.bundle_id:
                return target.get("targetIdentifier")
        return None

    def wait_target(self, timeout):
        deadline = time.time() + timeout
        while time.time() < deadline:
            identifier = self.target_identifier()
            if identifier:
                return identifier
            time.sleep(0.5)
        return None

    def settle(self):
        """Lets the details sync of the last reload finish, so a scenario
        starts from an idle window."""
        time.sleep(TIMEOUTS["settle"])

    def ensure_connected(self, scenario):
        """Brings the app back between scenarios when one left it gone."""
        if self.app.pid() is None:
            self.app.launch()
        if self.current_banner() in (None, "none"):
            return True
        entry = self.wait_banner({"none"}, time.time() - 60, 20)
        if entry is None or self.current_banner() != "none":
            self.results.check(scenario, "precondition: window connected", False, f"banner is {self.current_banner()}")
            return False
        self.settle()
        return True

    # Setup

    def wait_for_host(self):
        log("waiting for the Host to open the app's live document")
        deadline = time.time() + TIMEOUTS["open"]
        while time.time() < deadline:
            try:
                with open(self.arguments.host_output, errors="replace") as handle:
                    output = handle.read()
            except FileNotFoundError:
                output = ""
            if "keeping the document open" in output:
                break
            if "[host-e2e-dump] FAIL" in output:
                raise RuntimeError("the Host failed to open the app: " + output.strip().splitlines()[-1])
            if self.arguments.host_pid and not process_exists(self.arguments.host_pid):
                raise RuntimeError("the Host exited before opening the app")
            time.sleep(0.5)
        else:
            raise RuntimeError("timed out waiting for the Host to open the app")
        deadline = time.time() + 20
        while not os.path.exists(self.arguments.socket):
            if time.time() > deadline:
                raise RuntimeError(f"the MCP socket {self.arguments.socket} never appeared")
            time.sleep(0.2)
        self.mcp = MCPClient(self.arguments.socket)
        frame, _ = self.mcp.call("ping", timeout=10)
        if not frame or not (frame.get("result") or {}).get("pong"):
            raise RuntimeError(f"MCP ping failed: {frame}")
        if not self.wait_target(10):
            raise RuntimeError(f"targets.list does not list {self.bundle_id}")
        log(f"Host ready; app pid {self.app.pid()}")
        self.settle()

    # Scenarios

    def scenario_terminate(self):
        name = "2 terminate+relaunch"
        if not self.ensure_connected(name):
            return
        old_pid = self.app.pid()
        start = time.time()
        self.app.terminate()
        disconnected = self.wait_disconnected(start, TIMEOUTS["disconnect"] + 3)
        self.results.check(
            name,
            f"targets.disconnected <= {TIMEOUTS['disconnect']:.0f}s",
            disconnected and disconnected[0] - start <= TIMEOUTS["disconnect"],
            seconds(disconnected[0] - start) if disconnected else "no event",
        )
        lost = self.wait_banner({"connectionLost"}, start, TIMEOUTS["disconnect"] + 3)
        self.results.check(
            name,
            f"banner connectionLost <= {TIMEOUTS['disconnect']:.0f}s",
            lost and lost["_time"] - start <= TIMEOUTS["disconnect"],
            f"{seconds(lost['_time'] - start)} ({lost['event']})" if lost else "never",
        )
        time.sleep(1)
        start = time.time()
        new_pid = self.app.launch()
        self.results.check(name, "relaunched with a new pid", new_pid and new_pid != old_pid, f"{old_pid} -> {new_pid}")
        self.expect_return(name, start, TIMEOUTS["reconnect"], "reconnect")

    def expect_return(self, name, start, limit, label):
        cleared = self.wait_banner({"none"}, start, limit + 10)
        self.results.check(
            name,
            f"{label}: banner none <= {limit:.0f}s",
            cleared and cleared["_time"] - start <= limit,
            f"{seconds(cleared['_time'] - start)} ({cleared['event']}, actions {cleared['actions']})" if cleared else "never",
        )
        reloaded = self.wait_reloaded(start, limit + 10)
        self.results.check(
            name,
            f"{label}: hierarchy.reloaded{{host}} <= {limit:.0f}s",
            reloaded and reloaded[0] - start <= limit,
            f"{seconds(reloaded[0] - start)}, {reloaded[2].get('nodeCount')} nodes" if reloaded else "no event",
        )
        if reloaded:
            self.settle()
        return reloaded

    def scenario_background(self):
        name = "3 background+return"
        if not self.app.supports_background:
            self.results.skip(name, "background banner", "the AppKit Server does not report its app state")
            return
        if not self.ensure_connected(name):
            return
        start = time.time()
        self.app.background()
        entry = self.wait_banner({"applicationInBackground", "connectionLost"}, start, TIMEOUTS["background"] + 5)
        self.results.check(
            name,
            f"background or lost banner <= {TIMEOUTS['background']:.0f}s",
            entry and entry["_time"] - start <= TIMEOUTS["background"],
            f"{entry['banner']} after {seconds(entry['_time'] - start)} ({entry['event']})" if entry else "never",
        )
        # Stay in the background past one probe of a pushing Server (5 s).
        time.sleep(6)
        banner = self.current_banner()
        self.results.check(name, "banner holds while in the background", banner in ("applicationInBackground", "connectionLost"), f"banner {banner}")
        start = time.time()
        self.app.foreground()
        limit = TIMEOUTS["foreground_refresh"] if banner != "connectionLost" else TIMEOUTS["reconnect"]
        self.expect_return(name, start, limit, "return")

    def scenario_stop(self):
        name = "4 SIGSTOP silent channel"
        if not self.ensure_connected(name):
            return
        pid = self.app.signal(signal.SIGSTOP)
        log(f"stopped pid {pid}; waiting {TIMEOUTS['stop_silence']:.0f}s")
        try:
            time.sleep(TIMEOUTS["stop_silence"])
            target = self.target_identifier()
            start = time.time()
            identifier = self.mcp.send("hierarchy.refresh", {"targetIdentifier": target})
            closed = self.wait_os_log("closing a silent channel", start, TIMEOUTS["silent_close"])
            self.results.check(
                name,
                f"'closing a silent channel' <= {TIMEOUTS['silent_close']:.0f}s",
                closed is not None,
                seconds(closed["_time"] - start) if closed else "not logged",
            )
            lost = self.wait_banner({"connectionLost"}, start, TIMEOUTS["silent_close"])
            self.results.check(
                name,
                f"banner connectionLost <= {TIMEOUTS['silent_close']:.0f}s",
                lost is not None,
                f"{seconds(lost['_time'] - start)} ({lost['event']})" if lost else "never",
            )
            received, frame = self.mcp.wait_response(identifier, TIMEOUTS["silent_close"])
            error = (frame or {}).get("error") or {}
            self.results.check(
                name,
                "hierarchy.refresh fails, not hangs",
                frame is not None and error,
                f"{error.get('code')} after {seconds(received - start)}" if frame else "no response",
            )
        finally:
            start = time.time()
            self.app.signal(signal.SIGCONT)
        self.expect_return(name, start, TIMEOUTS["reconnect"], "after SIGCONT")

    def scenario_pending_request(self):
        name = "5 request in flight"
        if not self.ensure_connected(name):
            return
        target = self.target_identifier()
        # Pause the app so the refresh is still waiting (on its ping) when
        # the app dies; the pause is shorter than the silence that closes a
        # channel, so only the app's end can fail the request.
        self.app.signal(signal.SIGSTOP)
        identifier = self.mcp.send("hierarchy.refresh", {"targetIdentifier": target})
        time.sleep(0.5)
        start = time.time()
        self.app.signal(signal.SIGKILL)
        received, frame = self.mcp.wait_response(identifier, 30)
        error = (frame or {}).get("error") or {}
        elapsed = received - start if received else None
        self.results.check(
            name,
            f"in-flight refresh fails <= {TIMEOUTS['pending_failure']:.0f}s of the kill",
            frame is not None and error and elapsed <= TIMEOUTS["pending_failure"],
            f"{error.get('code') or 'succeeded'} after {seconds(elapsed)}" if frame else "no response",
        )
        time.sleep(1)
        start = time.time()
        self.app.launch()
        reloaded = self.expect_return(name, start, TIMEOUTS["reconnect"], "reconnect")
        if not reloaded:
            return
        # The fetch of the dead channel must not leave the window busy.
        deadline = time.time() + TIMEOUTS["refresh_after_reconnect"]
        codes = []
        succeeded = None
        while time.time() < deadline:
            target = self.target_identifier()
            frame, elapsed = self.mcp.call("hierarchy.refresh", {"targetIdentifier": target}, timeout=60)
            error = (frame or {}).get("error")
            if frame and not error:
                succeeded = elapsed
                break
            codes.append((error or {}).get("code", "no response"))
            time.sleep(0.5)
        self.results.check(
            name,
            "MCP refresh after reconnect succeeds",
            succeeded is not None,
            f"{seconds(succeeded)}; refused first: {codes}" if succeeded is not None else f"refused: {codes}",
        )
        self.results.check(
            name,
            "not refused as alreadyInProgress",
            "refresh.alreadyInProgress" not in codes,
            f"{codes.count('refresh.alreadyInProgress')} alreadyInProgress refusals",
        )
        self.settle()

    def run(self, scenarios):
        try:
            self.wait_for_host()
        except Exception as error:  # noqa: BLE001 - reported as a failed check
            self.results.check("setup", "Host opens the app", False, str(error))
            return self.results.print_table()
        table = {
            "terminate": self.scenario_terminate,
            "background": self.scenario_background,
            "stop": self.scenario_stop,
            "pending": self.scenario_pending_request,
        }
        for scenario in scenarios:
            log(f"--- scenario {scenario}")
            try:
                table[scenario]()
            except Exception as error:  # noqa: BLE001 - reported as a failed check
                self.results.check(scenario, "scenario ran", False, f"{type(error).__name__}: {error}")
            finally:
                if self.app.pid():
                    try:
                        os.kill(self.app.pid(), signal.SIGCONT)
                    except OSError:
                        pass
        return self.results.print_table()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mode", choices=["simulator", "appkit"], required=True)
    parser.add_argument("--udid")
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--background-bundle-id", default="com.apple.Preferences")
    parser.add_argument("--app-executable", help="appkit mode: the app's executable")
    parser.add_argument("--app-output", help="appkit mode: file for the app's output")
    parser.add_argument("--socket", required=True)
    parser.add_argument("--session-log", required=True)
    parser.add_argument("--os-log", required=True)
    parser.add_argument("--host-output", required=True)
    parser.add_argument("--host-pid", type=int)
    parser.add_argument("--scenarios", default="terminate,background,stop,pending")
    arguments = parser.parse_args()

    if arguments.mode == "simulator":
        app = SimulatorApp(arguments.udid, arguments.bundle_id, arguments.background_bundle_id)
    else:
        app = MacApp(arguments.app_executable, arguments.bundle_id, arguments.app_output)
        app.launch()
    scenarios = [value.strip() for value in arguments.scenarios.split(",") if value.strip()]
    log("timeouts: " + ", ".join(f"{key}={value:g}s" for key, value in TIMEOUTS.items()))
    driver = Driver(arguments, app)
    try:
        failures = driver.run(scenarios)
    finally:
        app.cleanup()
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
