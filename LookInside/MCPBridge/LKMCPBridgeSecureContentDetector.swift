// LKMCPBridgeSecureContentDetector.swift
//
// Decides whether an inspected display item carries secure user content
// (passwords, OTPs, payment fields) so callers can redact the textual
// values before they cross the wire.
//
// The detector is intentionally conservative: better to over-redact than
// to leak a credential into an MCP transcript that an AI agent or its log
// store will keep indefinitely. The current safety floor matches the
// reference implementation in upstream PR #26 (LookInside repo) by
// catching every AppKit `NSSecureTextField` and its subclasses via the
// inspected object's class chain.
//
// Known gap (tracked for a follow-up server-side change):
//   UIKit `UITextField` with `isSecureTextEntry = YES` is NOT detected.
//   LookinServer does not currently surface `isSecureTextEntry` as a
//   `LookinAttr_*`, so the bridge has no reliable way to read its value.
//   PR #26 references the attribute identifier `isSecureTextEntry` but
//   LookinServer's identifier table has no matching entry — so that branch
//   silently never fires there either. The right fix is to add the
//   property to `LookinAttrIdentifiers.h` plus the iOS-side reflection in
//   `LookinServer/Server/Category/UITextField+LookinServer.m`, after which
//   this detector can opt the UIKit case in.

import Foundation

enum LKMCPBridgeSecureContentDetector {

    /// Returns `true` when the given display item represents a view that
    /// the host should treat as carrying secure user input. When `true`,
    /// callers must replace any user-visible text strings on the item's
    /// attributes with `null` (or a `kind: "redacted"` marker) before
    /// emitting them on the bridge socket.
    static func isSecure(displayItem: LookinDisplayItem) -> Bool {
        guard let classChain = displayItem.viewObject?.classChainList else {
            return false
        }
        // NSSecureTextField and any subclass: catching the whole chain
        // also redacts cases where the inspected view is a private subclass
        // (e.g. `_NSSecureTextField_FooBar`) without losing protection.
        if classChain.contains("NSSecureTextField") {
            return true
        }
        return false
    }
}
