//
//  LookinObject+LookinClient.swift
//  LookInside
//

import Foundation
import LookInsideHostCore

extension LookinObject {
    /// The demangled class name, module prefix included.
    @objc func lk_completedDemangledClassName() -> String {
        LKSwiftDemangler.completedParse(input: rawClassName() ?? "")
    }

    /// The demangled class name without its module prefix; generic
    /// arguments keep theirs.
    @objc func lk_simpleDemangledClassName() -> String {
        ClientDisplayText.removingModulePrefix(LKSwiftDemangler.simpleParse(input: rawClassName() ?? ""))
    }
}
