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
        func removeImplicitAnimations() {
            // The keys are the property names the Objective-C original spelled
            // as NSStringFromSelector(@selector(...)).
            var actions: [String: any CAAction] = [:]
            for key in layerActionKeys {
                actions[key] = NSNull()
            }
            if isKind(of: CAShapeLayer.self) {
                for key in shapeLayerActionKeys {
                    actions[key] = NSNull()
                }
            }
            if isKind(of: CAGradientLayer.self) {
                for key in gradientLayerActionKeys {
                    actions[key] = NSNull()
                }
            }
            self.actions = actions
        }

        @available(*, deprecated, renamed: "removeImplicitAnimations()")
        func lookin_removeImplicitAnimations() {
            removeImplicitAnimations()
        }
    }

    private let layerActionKeys = [
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

    private let shapeLayerActionKeys = [
        "path",
        "fillColor",
        "strokeColor",
        "strokeStart",
        "strokeEnd",
        "lineWidth",
        "miterLimit",
        "lineDashPhase",
    ]

    private let gradientLayerActionKeys = [
        "colors",
        "locations",
        "startPoint",
        "endPoint",
    ]

#endif
