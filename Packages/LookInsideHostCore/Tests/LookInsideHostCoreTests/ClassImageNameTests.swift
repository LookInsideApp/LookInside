import Foundation
@testable import LookInsideHostCore
import Testing

/// The image names the Class card shows next to each class.
@Suite("Class image names")
struct ClassImageNameTests {
    @Test("Names the framework, library or executable", arguments: [
        ("/System/Library/PrivateFrameworks/PepperUICore.framework/PepperUICore", "PepperUICore"),
        ("/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit", "AppKit"),
        ("/Library/Developer/CoreSimulator/Volumes/watchOS_24S118/Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS 27.2.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore", "UIKitCore"),
        ("/usr/lib/swift/libswiftCore.dylib", "libswiftCore"),
        ("/usr/lib/libobjc.A.dylib", "libobjc.A"),
        ("/private/var/containers/Bundle/Application/1F2E/Demo.app/Frameworks/LookInsideServer.framework/LookInsideServer", "LookInsideServer"),
        ("/private/var/containers/Bundle/Application/1F2E/Demo.app/Demo", "Demo"),
    ])
    func namesTheImage(imagePath: String, expectedName: String) {
        #expect(ClientDisplayText.imageShortName(ofImagePath: imagePath) == expectedName)
    }

    @Test("Has no name for a class the runtime could not place")
    func hasNoNameForAnEmptyPath() {
        #expect(ClientDisplayText.imageShortName(ofImagePath: "") == nil)
    }
}
