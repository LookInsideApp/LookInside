//
//  Geometry.swift
//  LookinCore
//
//  The limits geometry from an inspected app is held to, and the preview's
//  image size limit. This was part of LookinDefines.h.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import CoreGraphics
    import Foundation

    /// The limits of the Host's preview.
    public enum PreviewLimits {
        /// The largest width and height, in pixels, of an image an SCNNode
        /// takes; SceneKit itself sets it.
        public static let maximumNodeImageLengthInPixels: Double = 16384
    }

    extension CGRect {
        /// The largest coordinate or size, in points, of a rect an inspected app
        /// reports that geometry math still takes: 2^24, the largest integer
        /// single precision holds exactly. Core Animation's render server and
        /// the host's GPU work in single precision, so geometry past it is
        /// unreliable anyway. Real views get well past the 100 000 points this
        /// used to be: an outline view 107 829 points tall went out without a
        /// frame, left the host's preview and moved its rows to the window's
        /// origin.
        public static let maximumUsableCoordinate: Double = 16_777_216

        /// Whether a rect reported by an inspected app is safe to feed into
        /// geometry math. NaN / Inf components poison every CGRect computation
        /// they touch and eventually reach layer and scene-graph geometry on the
        /// host, so they are rejected once here instead of at every call site,
        /// with anything beyond `maximumUsableCoordinate`. Reads the stored
        /// size, not the standardized one, as the C function did.
        public var isUsable: Bool {
            if isNull || isInfinite {
                return false
            }
            let originX = origin.x
            let originY = origin.y
            let width = size.width
            let height = size.height
            if originX.isNaN || originY.isNaN || width.isNaN || height.isNaN {
                return false
            }
            if originX.isInfinite || originY.isInfinite || width.isInfinite || height.isInfinite {
                return false
            }
            let maximumCoordinate = CGFloat(Self.maximumUsableCoordinate)
            if abs(originX) > maximumCoordinate || abs(originY) > maximumCoordinate
                || width < 0 || height < 0
                || width > maximumCoordinate || height > maximumCoordinate
            {
                return false
            }
            return true
        }
    }

#endif
