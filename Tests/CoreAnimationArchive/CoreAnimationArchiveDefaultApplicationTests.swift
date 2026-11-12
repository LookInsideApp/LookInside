import AppKit
import Foundation
import UniformTypeIdentifiers

/// Coverage for the Settings row that makes LookInside the default app for
/// Core Animation archives.
///
/// A stand-in workspace replaces Launch Services throughout: a test must not
/// change which app opens a file type on the machine it runs on.
@main
struct CoreAnimationArchiveDefaultApplicationTests {
    @MainActor
    static func main() async {
        testNoRegisteredApplicationReadsAsNone()
        testAnotherApplicationIsNamed()
        testThisApplicationIsRecognized()
        await testMakingTheDefaultHandsLaunchServicesThisApplication()
        await testAFailedChangeLeavesTheRowUsable()
        print("Core Animation archive default application tests passed")
    }

    private static let applicationURL = URL(fileURLWithPath: "/Applications/LookInside.app")

    @MainActor
    private static func testNoRegisteredApplicationReadsAsNone() {
        let workspace = StandInWorkspace(handlerURL: nil)
        let defaultApplication = makingDefaultApplication(workspace: workspace)
        expect(defaultApplication.handler == .none, "no registered app should read as none")
    }

    @MainActor
    private static func testAnotherApplicationIsNamed() {
        let workspace = StandInWorkspace(handlerURL: URL(fileURLWithPath: "/Volumes/RE/Mica/1.0-333/Mica.app"))
        let defaultApplication = makingDefaultApplication(workspace: workspace)
        expect(
            defaultApplication.handler == .otherApplication(name: "Mica"),
            "another app should be named without its extension, got \(defaultApplication.handler)"
        )
    }

    @MainActor
    private static func testThisApplicationIsRecognized() {
        let workspace = StandInWorkspace(handlerURL: applicationURL)
        let defaultApplication = makingDefaultApplication(workspace: workspace)
        expect(defaultApplication.handler == .lookInside, "this app should be recognized as LookInside")
    }

    @MainActor
    private static func testMakingTheDefaultHandsLaunchServicesThisApplication() async {
        let workspace = StandInWorkspace(handlerURL: URL(fileURLWithPath: "/Applications/Mica.app"))
        let defaultApplication = makingDefaultApplication(workspace: workspace)
        do {
            try await defaultApplication.makeLookInsideTheDefault()
        } catch {
            fail("making the default should succeed, got \(error)")
        }
        expect(workspace.requestedApplicationURLs == [applicationURL], "Launch Services should be handed this app")
        expect(
            workspace.requestedContentTypes == [UTType(importedAs: "com.apple.coreanimation-archive")],
            "the change should be for the Core Animation archive type"
        )
        expect(defaultApplication.handler == .lookInside, "the row should read the new default afterwards")
        expect(!defaultApplication.isChanging, "the row should be usable again")
    }

    @MainActor
    private static func testAFailedChangeLeavesTheRowUsable() async {
        let workspace = StandInWorkspace(handlerURL: URL(fileURLWithPath: "/Applications/Mica.app"))
        workspace.failure = CocoaError(.fileWriteNoPermission)
        let defaultApplication = makingDefaultApplication(workspace: workspace)
        do {
            try await defaultApplication.makeLookInsideTheDefault()
            fail("a refused change should throw")
        } catch {
            // Expected: the Settings row presents the error.
        }
        expect(defaultApplication.handler == .otherApplication(name: "Mica"), "the old default should still show")
        expect(!defaultApplication.isChanging, "the row should be usable again after a failure")
    }

    // MARK: - Helpers

    @MainActor
    private static func makingDefaultApplication(workspace: StandInWorkspace) -> CoreAnimationArchiveDefaultApplication {
        CoreAnimationArchiveDefaultApplication(
            workspace: workspace,
            applicationURL: applicationURL,
            applicationBundleIdentifier: nil
        )
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}

/// Launch Services for one content type, in memory.
@MainActor
private final class StandInWorkspace: DefaultApplicationWorkspace {
    var handlerURL: URL?
    var failure: Error?
    private(set) var requestedApplicationURLs: [URL] = []
    private(set) var requestedContentTypes: [UTType] = []

    init(handlerURL: URL?) {
        self.handlerURL = handlerURL
    }

    func urlForApplication(toOpen _: UTType) -> URL? {
        handlerURL
    }

    func makingDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws {
        requestedApplicationURLs.append(applicationURL)
        requestedContentTypes.append(contentType)
        if let failure {
            throw failure
        }
        handlerURL = applicationURL
    }
}
