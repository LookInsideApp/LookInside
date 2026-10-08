//
//  InspectedObject+LookinClient.swift
//  LookInside
//

import Foundation
import LookInsideHostCore

extension InspectedObject {
    /// The demangled class name, module prefix included.
    @objc func lk_completedDemangledClassName() -> String {
        SwiftDemangler.completedParse(input: rawClassName() ?? "")
    }

    /// The demangled class name without its module prefix; generic
    /// arguments keep theirs.
    @objc func lk_simpleDemangledClassName() -> String {
        ClientDisplayText.removingModulePrefix(SwiftDemangler.simpleParse(input: rawClassName() ?? ""))
    }
}
