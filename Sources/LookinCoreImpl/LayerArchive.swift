//
//  LayerArchive.swift
//  LookinCore
//
//  The reply to `LookinRequestTypeLayerArchive` (211): one window's whole
//  layer tree as QuartzCore's `CAEncodeLayerTree` encodes it — the format
//  AppKit's Dump Layer writes to `.caar` files — plus what the Host needs to
//  match the decoded layers to the hierarchy's nodes.
//
//  The two per-layer lists travel as packed little-endian integers rather
//  than arrays of NSNumber: a window of 4000 layers would otherwise put 8000
//  objects into the archive.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinLayerArchive)
    public final class LayerArchive: NSObject, NSSecureCoding {
        /// `CAEncodeLayerTree`'s output for the window's root layer; nil when
        /// the window has more layers than the request allowed.
        @objc(archiveData)
        public var archiveData: Data?
        /// Every layer of the tree, depth first with sublayers in order and
        /// masks left out: the oid the Server registered for it, 0 when the
        /// hierarchy has no node for it.
        public var layerOids: [UInt] = []
        /// How many sublayers each layer has, in the order of `layerOids`. The
        /// Host checks the decoded tree against it before it trusts the oids.
        public var sublayerCounts: [UInt32] = []
        /// The number of layers in the tree, also when nothing was encoded.
        @objc(layerCount)
        public var layerCount: UInt = 0
        /// How long the encoding held the main thread, in seconds.
        @objc(encodingDuration)
        public var encodingDuration: TimeInterval = 0

        public static var supportsSecureCoding: Bool {
            true
        }

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with coder: NSCoder) {
            coder.encode(archiveData, forKey: "archiveData")
            coder.encode(Self.packing(layerOids.map { UInt64($0) }), forKey: "layerOids")
            coder.encode(Self.packing(sublayerCounts), forKey: "sublayerCounts")
            coder.encode(Int(bitPattern: layerCount), forKey: "layerCount")
            coder.encode(encodingDuration, forKey: "encodingDuration")
        }

        public required init?(coder: NSCoder) {
            archiveData = coder.decodeObject(of: NSData.self, forKey: "archiveData") as Data?
            layerOids = Self.unpacking(coder.decodeObject(of: NSData.self, forKey: "layerOids") as Data?, as: UInt64.self)
                .map { UInt(truncatingIfNeeded: $0) }
            sublayerCounts = Self.unpacking(coder.decodeObject(of: NSData.self, forKey: "sublayerCounts") as Data?, as: UInt32.self)
            layerCount = UInt(bitPattern: coder.decodeInteger(forKey: "layerCount"))
            encodingDuration = coder.decodeDouble(forKey: "encodingDuration")
            super.init()
        }

        // MARK: Packed integers

        private static func packing<Element: FixedWidthInteger>(_ values: [Element]) -> Data {
            var data = Data(capacity: values.count * MemoryLayout<Element>.size)
            for value in values {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            return data
        }

        /// The integers packed in `data`; empty when there is no data or its
        /// length is not a whole number of them.
        private static func unpacking<Element: FixedWidthInteger>(_ data: Data?, as _: Element.Type) -> [Element] {
            guard let data else { return [] }
            let elementSize = MemoryLayout<Element>.size
            guard data.count % elementSize == 0 else { return [] }
            var values: [Element] = []
            values.reserveCapacity(data.count / elementSize)
            data.withUnsafeBytes { buffer in
                var offset = 0
                while offset < buffer.count {
                    values.append(Element(littleEndian: buffer.loadUnaligned(fromByteOffset: offset, as: Element.self)))
                    offset += elementSize
                }
            }
            return values
        }
    }

#endif
