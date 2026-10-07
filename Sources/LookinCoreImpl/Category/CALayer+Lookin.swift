//
//  CALayer+Lookin.swift
//  LookinCore
//
//  Was CALayer+Lookin.m.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    import QuartzCore
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    public extension CALayer {
        @objc(lookin_removeImplicitAnimations)
        func lookin_removeImplicitAnimations() {
            // The keys are the property names the Objective-C original spelled
            // as NSStringFromSelector(@selector(...)).
            var actions: [String: any CAAction] = [:]
            for key in lookinLayerActionKeys {
                actions[key] = NSNull()
            }
            if isKind(of: CAShapeLayer.self) {
                for key in lookinShapeLayerActionKeys {
                    actions[key] = NSNull()
                }
            }
            if isKind(of: CAGradientLayer.self) {
                for key in lookinGradientLayerActionKeys {
                    actions[key] = NSNull()
                }
            }
            self.actions = actions
        }
    }

    private let lookinLayerActionKeys = [
        "bounds",
        "position",
        "zPosition",
        "anchorPoint",
        "anchorPointZ",
        "transform",
        "sublayerTransform",
        "masksToBounds",
        "contents",
        "contentsRect",
        "contentsScale",
        "contentsCenter",
        "minificationFilterBias",
        "backgroundColor",
        "cornerRadius",
        "borderWidth",
        "borderColor",
        "opacity",
        "compositingFilter",
        "filters",
        "backgroundFilters",
        "shouldRasterize",
        "rasterizationScale",
        "shadowColor",
        "shadowOpacity",
        "shadowOffset",
        "shadowRadius",
        "shadowPath",
    ]

    private let lookinShapeLayerActionKeys = [
        "path",
        "fillColor",
        "strokeColor",
        "strokeStart",
        "strokeEnd",
        "lineWidth",
        "miterLimit",
        "lineDashPhase",
    ]

    private let lookinGradientLayerActionKeys = [
        "colors",
        "locations",
        "startPoint",
        "endPoint",
    ]

#endif
