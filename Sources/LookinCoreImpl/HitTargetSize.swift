//
//  HitTargetSize.swift
//  LookinCore
//
//  The smallest comfortable hit targets and how far a measured target falls
//  short of them, shared by the Host's Suggestions and the Server's gesture
//  overlays. This was LookinHitTargetSize.h.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// The smallest comfortable hit targets, and how far a target falls short.
    public enum HitTargetSize {
        /// The smallest comfortable hit target on iPhone and iPad, in points.
        public static let minimumOnIPhone: Double = 44.0

        /// The smallest comfortable hit target on the Mac, in points.
        public static let minimumOnMac: Double = 28.0

        /// How far a `width` × `height` target falls short of `minimum`, from 0
        /// to 1. Zero means no size warning; missing, invalid, or unsupported
        /// measurements are never reported as failures.
        public static func deficit(width: Double, height: Double, minimum: Double) -> Double {
            if !width.isFinite || !height.isFinite || !minimum.isFinite
                || width <= 0 || height <= 0 || minimum <= 0
                || width > 100_000 || height > 100_000
            {
                return 0
            }
            // Window conversion can turn 44 pt into 43.99999999999994 pt.
            if width >= minimum - 0.000001, height >= minimum - 0.000001 {
                return 0
            }
            return 1.0 - min(width, height) / minimum
        }
    }

#endif
