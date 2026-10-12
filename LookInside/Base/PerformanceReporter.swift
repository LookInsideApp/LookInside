//
//  PerformanceReporter.swift
//  LookInside
//

import QuartzCore

/// Timestamps of the current hierarchy reload. Nothing reads them yet; the
/// hooks stay so reload timing can be reported again.
final class PerformanceReporter: NSObject {
    private static let shared = PerformanceReporter()

    static func sharedInstance() -> PerformanceReporter {
        shared
    }

    private var reloadStartTime: CFTimeInterval = 0
    private var hierarchyFetchedTime: CFTimeInterval = 0

    func willStartReload() {
        reloadStartTime = CACurrentMediaTime()
    }

    func didFetchHierarchy() {
        hierarchyFetchedTime = CACurrentMediaTime()
    }

    func didComplete() {}
}
