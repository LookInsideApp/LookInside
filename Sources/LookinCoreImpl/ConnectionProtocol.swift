//
//  ConnectionProtocol.swift
//  LookinCore
//
//  What the Host and the Server agree on before anything else: the protocol
//  versions, the ports a Server listens on, the request and push types, and
//  the keys of request parameters. Shared by every Swift file in
//  LookinCoreImpl and LookinServerImpl; the Host compiles it from
//  DerivedSource as well. The request numbers and parameter keys cross the
//  wire; this was part of LookinDefines.h.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    // MARK: - Versions

    /// The connection protocol versions this build speaks.
    public enum ProtocolVersion {
        /// The connection protocol version of this LookinServer.
        public static let server: Int32 = 9

        /// The connection protocol version of this LookinClient.
        public static let client: Int32 = 9

        /// The connection protocol versions of LookinServer this LookinClient
        /// supports.
        public static let supportedServers: ClosedRange<Int32> = 8 ... 9
    }

    /// The LookinServer this is.
    public enum ServerBuild {
        /// The release version of LookinServer.
        public static let releaseVersion = "1.3.0"
    }

    // MARK: - Ports

    /// The ports a Server tries to listen on, in turn, until one is free.
    public enum ListeningPorts {
        /// On a device.
        public static let usbDevice: ClosedRange<Int32> = 47175 ... 47179

        /// In the Simulator.
        public static let simulator: ClosedRange<Int32> = 47164 ... 47169

        /// In a macOS app.
        public static let mac: ClosedRange<Int32> = 47170 ... 47174
    }

    // MARK: - Requests

    /// The type of a request frame. Request types take 200 to 299; 0 to 199
    /// belong to upstream Lookin. `Int`, as the anonymous C enum they replace
    /// was imported.
    public enum RequestType {
        /// Whether both ends can still answer.
        public static let ping = 200
        /// The app's screenshot, device model and other information.
        public static let app = 201
        /// The hierarchy.
        public static let hierarchy = 202
        /// Screenshots and attribute groups.
        public static let hierarchyDetails = 203
        /// Modifies a built-in attribute.
        public static let inbuiltAttributeModification = 204
        /// After an attribute changed, the latest screenshots and values.
        public static let attributeModificationPatch = 205
        /// Invokes a method.
        public static let invokeMethod = 206
        /// Request `["oid": …]`; reply `InspectedObject`.
        public static let fetchObject = 207
        public static let fetchImageViewImage = 208
        public static let modifyRecognizerEnable = 209
        /// The attribute group list.
        public static let allAttributeGroups = 210

        /// Encodes one window's whole layer tree with QuartzCore's
        /// CAEncodeLayerTree, the format AppKit's Dump Layer writes to `.caar`
        /// files, so the Host can draw the node images itself. Params:
        /// `RequestParameterKey.layerArchiveWindowOid`,
        /// `RequestParameterKey.layerArchiveLayerLimit`. Reply: `LayerArchive`.
        /// Only macOS Servers that report `layerArchiveProtocolVersion` 1 answer
        /// it; older Servers close the connection on a request type they do not
        /// know, so the Host checks the capability first.
        public static let layerArchive = 211

        /// Every selector name of a class in the inspected app, superclasses
        /// included.
        public static let allSelectorNames = 213
        /// Modifies a custom attribute.
        public static let customAttributeModification = 214

        /// License handshake: the Server sends a random nonce and its
        /// server_instance_id.
        public static let licenseChallenge = 220
        /// License handshake: the client returns its intermediate certificate
        /// and its signature over the nonce.
        public static let licenseVerify = 221

        /// Versioned SwiftUI gesture capture controls (start, stop, overlay,
        /// status).
        public static let gestureDebug = 222

        /// The description an `invokeMethod` reply carries when the method
        /// returns void.
        public static let invokeMethodVoidReturnDescription = "LOOKIN_TAG_RETURN_VALUE_VOID"
    }

    // MARK: - Pushes

    /// The type of a frame the Server sends without being asked. Pushes take
    /// 300 and up.
    public enum PushType {
        /// Unused since LookinServer 1.2.7 and Lookin 1.0.7.
        public static let bringForwardScreenshotTask = 303
        /// The user cancelled the hierarchy details fetch in the client.
        public static let cancelHierarchyDetails = 304
        /// The Server found a SwiftUI hosting view while it walked the
        /// hierarchy.
        public static let swiftUISupportDetected = 305
        /// JSON data carrying a versioned, bounded gesture capture batch.
        public static let gestureDebug = 306

        /// The application resigned active or became active (UIKit only), tag
        /// 0. Payload: NSDictionary, `RequestParameterKey.applicationIsActive`
        /// → NSNumber BOOL. Lets the Host tell an app in the background from a
        /// dead channel and refresh once the app is back. Hosts that predate it
        /// find no request of this type and tag waiting, refuse the frame and
        /// skip its payload (LookInside 2.3.x, 3.x and upstream Lookin all do).
        public static let applicationStateChanged = 307
    }

    // MARK: - Request parameters

    /// The keys of the dictionaries requests and pushes carry. The strings
    /// cross the wire.
    public enum RequestParameterKey {
        /// `PushType.applicationStateChanged` payload key: NSNumber boxed BOOL,
        /// true once the application became active, false when it resigned
        /// active.
        public static let applicationIsActive = "active"

        public static let viewLayerTag = "tag"

        public static let selectorName = "sn"
        public static let methodType = "mt"
        public static let selectorClassName = "scn"

        /// SwiftUI hierarchy display mode payload key on `RequestType.hierarchy`.
        ///
        /// NSNumber boxed:
        ///   - 0 → verbose
        ///   - 1 → compact
        ///   - missing → the Server falls back to verbose (forward-compatible
        ///     with old Hosts)
        ///
        /// Additive payload: the Server reads it when present and ignores it
        /// otherwise. No version bump.
        public static let swiftUIDisplayMode = "swiftUIDisplayMode"

        /// Hierarchy request (202) param: the Host takes the hierarchy the way
        /// `hierarchyAcquisitionProtocolVersion` 1 describes. The Server then
        /// builds the tree over several main-queue turns, sends progress frames
        /// before the final `HierarchyInfo`, and leaves SwiftUI nodes'
        /// screenshots and attribute groups to the detail request (203), reached
        /// through `CustomDisplayItemInfo.detailObjectOid`.
        ///
        /// NSNumber boxed BOOL. Missing (older Hosts, upstream Lookin) → the
        /// one-frame build with SwiftUI details inline, as before. Additive
        /// payload, no version bump.
        public static let asyncAcquisition = "asyncAcquisition"

        /// Layer archive request (211) param: the oid of the window to encode,
        /// as the hierarchy gave it. NSNumber boxed unsigned long.
        public static let layerArchiveWindowOid = "layerArchiveWindowOid"

        /// Layer archive request (211) param: the most layers the Server may
        /// encode. A window with more is not encoded; the reply then carries
        /// only its layer count. NSNumber boxed unsigned long.
        public static let layerArchiveLayerLimit = "layerArchiveLayerLimit"

        /// App (201) and hierarchy (202) request param: whether a macOS Server
        /// draws the window the inactive app would make key as the key window
        /// while it takes images, so they show the app as it looks in front.
        /// The Server keeps the last value it received for the connection; the
        /// requests after a 202 (203, 211, attribute edits) follow it.
        ///
        /// NSNumber boxed BOOL. Missing (older Hosts, upstream Lookin) → on.
        /// Other platforms ignore it. Additive payload, no version bump.
        ///
        /// Servers that know `keyAppearanceLevel` read that first and this only
        /// when it is missing or a level they do not know: true draws as key,
        /// false is off. A Host sends both, so an older Server falls back to
        /// drawing as key when the Host asks to treat the window as key.
        public static let keepsKeyAppearance = "keepsKeyAppearance"

        /// App (201) and hierarchy (202) request param: how far a macOS Server
        /// goes to show the inactive app as it looks in front while it takes
        /// images. As with `keepsKeyAppearance`, which the Host sends alongside,
        /// the Server keeps the last value it received for the connection.
        ///
        /// NSNumber boxed `KeyAppearanceLevel`. Missing → read
        /// `keepsKeyAppearance`; both missing → `drawsAsKey`. Other platforms
        /// ignore it. Additive payload, no version bump.
        public static let keyAppearanceLevel = "keyAppearanceLevel"

        /// Hierarchy request (202) param: the newest attribute catalog revision
        /// the Host knows. NSNumber boxed integer. The Server leaves out
        /// attributes whose `revision` is newer, so a Host never gets a group it
        /// has no title, icon or default sections for. Missing (older Hosts,
        /// upstream Lookin) → 0, the catalog as it was before revisions existed.
        /// The detail request (203) carries the same value on
        /// `StaticAsyncUpdateTask`.
        public static let attributeCatalogRevision = "attributeCatalogRevision"
    }

#endif
