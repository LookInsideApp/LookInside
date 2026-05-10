//
//  LKDeviceManager.h
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import <Foundation/Foundation.h>
#import "LKInspectableApp.h"

extern NSString *const LKInspectingAppDidEndNotificationName;

@interface LKAppsManager : NSObject

+ (instancetype)sharedInstance;

/// 获取当前所有可查看的 iOS app
/// needImages 是否需要返回截图和图标，不需要则可加快速度
/// localInfos 本地已经存在的 appInfos，传入该参数从而可增量更新
/// data 为 NSArray<LKInspectableApp *>，该方法不会 sendError
- (RACSignal *)fetchAppInfosWithImage:(BOOL)needImages localInfos:(NSArray<LookinAppInfo *> *)localInfos;

/// Phase D: globally writing this property is no longer how the app tracks
/// "currently inspected app" — each `LookinLiveDocument` owns its own
/// `LKInspectableApp`. The setter survives only as inert dead code so older
/// callsites compile, but no live code path should still write through it
/// (Phase F removes it entirely). Readers should query the document's
/// `inspectableApp` (or accept the per-controller fallback installed in
/// Phase A).
@property(nonatomic, strong) LKInspectableApp *inspectingApp __attribute__((deprecated("Phase D: setter is no longer driven by any code path; readers should query the document's inspectableApp instead. This property will be deleted in Phase F.")));

/// Phase D: only kept around because Phase F removes it together with
/// `inspectingApp`. The single subscriber (LKAppsManager auto-reconnect
/// pipeline) was removed in Phase D, so this signal currently never fires.
@property(nonatomic, strong, readonly) RACSubject *didAutoReconnectSucc __attribute__((deprecated("Phase D: no longer driven by anything. Will be deleted in Phase F together with inspectingApp.")));

@end
