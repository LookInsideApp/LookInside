//
//  AppsManager.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//
//  Finds the apps the Host can inspect. It keeps no state: each live
//  document follows its own app across reconnects (LiveDocument).
//

import Foundation
import LookInsideHostCore
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app")
@MainActor
final class AppsManager: NSObject {
    @objc(sharedInstance)
    static let shared = AppsManager()

    override private init() {
        super.init()
    }

    /// Every app that answers on a connected port, in port order.
    ///
    /// - Parameters:
    ///   - needImages: whether to fetch icons and screenshots; without them
    ///     the scan is faster.
    ///   - localInfos: app infos fetched before; a fresh one is reused when
    ///     the Server says it did not change, so its images are not sent
    ///     again.
    ///
    /// An app whose Server is too old or too new is returned with
    /// `serverVersionError` and no channel. Apps in the background, which
    /// cannot answer, and apps that require a license for app info are left
    /// out.
    func fetchAppInfos(needImages: Bool, localInfos: [InspectedAppInfo]?) async -> [InspectableApp] {
        await scanApps(needImages: needImages, localInfos: localInfos).apps
    }

    /// `fetchAppInfos` plus how many channels were connected.
    func scanApps(needImages: Bool, localInfos: [InspectedAppInfo]?) async -> (apps: [InspectableApp], channelCount: Int) {
        let now = Date().timeIntervalSince1970
        let validAppInfos = (localInfos ?? []).filter {
            AppInfoCachePolicy.isFresh(cachedTimestamp: $0.cachedTimestamp, now: now)
        }
        let localIdentifiers = NSArray(array: validAppInfos.map { NSNumber(value: $0.appInfoIdentifier) })
        let parameters = NSDictionary(
            objects: [NSNumber(value: needImages), localIdentifiers],
            forKeys: ["needImages" as NSString, "local" as NSString]
        )

        let channels = await ConnectionManager.shared.connectAllPorts()
        guard !channels.isEmpty else {
            return ([], 0)
        }
        let outcomes = await requestAppInfos(parameters: parameters, channels: channels)
        let apps = zip(outcomes, channels).compactMap { outcome, channel in
            makeApp(from: outcome, channel: channel, validAppInfos: validAppInfos)
        }
        return (apps, channels.count)
    }

    private enum AppInfoOutcome {
        /// The app is in the background or did not answer.
        case none
        case response(ConnectionResponseAttachment?)
        case versionError(NSError)
    }

    /// Sends the app info request on every channel at once, in channel
    /// order, and waits for all of them.
    private func requestAppInfos(parameters: NSDictionary, channels: [ServerChannel]) async -> [AppInfoOutcome] {
        await withCheckedContinuation { continuation in
            var outcomes = [AppInfoOutcome](repeating: .none, count: channels.count)
            var remaining = channels.count
            for (index, channel) in channels.enumerated() {
                var settled = false
                let settle: (AppInfoOutcome) -> Void = { outcome in
                    guard !settled else { return }
                    settled = true
                    outcomes[index] = outcome
                    remaining -= 1
                    if remaining == 0 {
                        continuation.resume(returning: outcomes)
                    }
                }
                let sink = ResponseSink { event in
                    switch event {
                    case let .response(attachment):
                        settle(.response(attachment))
                    case let .failure(error):
                        if error.code == LookinErrCode_ServerVersionTooHigh || error.code == LookinErrCode_ServerVersionTooLow {
                            // The launch window shows these.
                            settle(.versionError(error))
                        } else {
                            // A connected app in the background ends here.
                            settle(.none)
                        }
                    case .completion:
                        settle(.none)
                    }
                }
                ConnectionManager.shared.request(
                    type: UInt32(LookinRequestTypeApp),
                    data: parameters,
                    channel: channel,
                    sink: sink
                )
            }
        }
    }

    private func makeApp(from outcome: AppInfoOutcome, channel: ServerChannel, validAppInfos: [InspectedAppInfo]) -> InspectableApp? {
        switch outcome {
        case .none:
            return nil
        case let .versionError(error):
            let app = InspectableApp()
            app.serverVersionError = error
            return app
        case let .response(response):
            if let error = response?.error as NSError? {
                #log(.default, "LookinClient - app info request failed, domain:\(error.domain, privacy: .public), code:\(NSNumber(value: error.code), privacy: .public), description:\(error.localizedDescription, privacy: .public)")
                if error.code == LookinErrCode_LicenseRequired {
                    return nil
                }
                let app = InspectableApp()
                app.serverVersionError = error
                app.channel = channel
                return app
            }
            var receivedInfo = response?.data as? InspectedAppInfo
            receivedInfo?.cachedTimestamp = Date().timeIntervalSince1970
            if let info = receivedInfo, info.shouldUseCache,
               let localInfo = validAppInfos.first(where: { $0.appInfoIdentifier == info.appInfoIdentifier })
            {
                // The Server's info did not change; keep the one with images.
                receivedInfo = localInfo
            }
            let app = InspectableApp()
            app.appInfo = receivedInfo
            app.channel = channel
            return app
        }
    }
}
