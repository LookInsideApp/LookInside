//
//  PerformanceReporter.swift
//  LookInside
//

import QuartzCore

/// Timestamps of the current hierarchy reload. Nothing reads them yet; the
/// hooks stay so reload timing can be reported again.
@objc(LKPerformanceReporter)
final class PerformanceReporter: NSObject {
    private static let shared = PerformanceReporter()

    @objc static func sharedInstance() -> PerformanceReporter {
        shared
    }

    private var reloadStartTime: CFTimeInterval = 0
    private var hierarchyFetchedTime: CFTimeInterval = 0

    @objc func willStartReload() {
        reloadStartTime = CACurrentMediaTime()
    }

    @objc func didFetchHierarchy() {
        hierarchyFetchedTime = CACurrentMediaTime()
    }

    @objc func didComplete() {}
}
