#ifdef SHOULD_COMPILE_LOOKIN_SERVER 

//
//  LookinAppInfo.h
//  qmuidemo
//
//  Created by Li Kai on 2018/11/3.
//  Copyright © 2018 QMUI Team. All rights reserved.
//



#import "LookinDefines.h"

/// 设备类型。该枚举的原始值会经由 wire 协议传给 Lookin 客户端，因此顺序不可调整，
/// 新增的档位只能追加在末尾。上游 Lookin 只认识前三档（0–2），收到更大的值时会落到
/// 自己的 default 分支（表现为设备图标缺失，而非报错）。
typedef NS_ENUM(NSInteger, LookinAppInfoDevice) {
    LookinAppInfoDeviceSimulator,   // 0，模拟器
    LookinAppInfoDeviceIPad,    // 1，iPad 真机
    LookinAppInfoDeviceOthers,   // 2，应该视为 iPhone 真机
    LookinAppInfoDeviceMac, // 3，使用AppKit的Mac应用（非 Catalyst）
    LookinAppInfoDeviceMacCatalyst, // 4，Mac Catalyst 应用：跑在 Mac 上，但界面是 UIKit
};

@interface LookinAppInfo : NSObject <NSSecureCoding, NSCopying>

/// 每次启动 app 时都会随机生成一个 appInfoIdentifier 直到 app 被 kill 掉
@property(nonatomic, assign) NSUInteger appInfoIdentifier;
/// Optional macOS process identity. Older peers and other platforms leave these nil.
@property(nonatomic, copy) NSNumber *processIdentifier;
@property(nonatomic, copy) NSString *processStartIdentifier;
/// mac 端应该先读取该属性，如果为 YES 则表示应该使用之前保存的旧 appInfo 对象即可
@property(nonatomic, assign) BOOL shouldUseCache;
/// LookinServer 的版本
@property(nonatomic, assign) int serverVersion;
/// 类似 "1.1.9"，只在 1.2.3 以及之后的 LookinServer 版本里有值
@property(nonatomic, assign) NSString *serverReadableVersion;
/// 如果 iOS 侧使用了 SPM 或引入了 Swift Subspec，则该属性为 1
/// 如果 iOS 侧没使用，则该属性为 -1
/// 如果不知道，则该属性为 0
@property(nonatomic, assign) int swiftEnabledInLookinServer;
/// app 的当前截图
@property(nonatomic, strong) LookinImage *screenshot;
/// 可能为 nil，比如新建的 iOS 空项目
@property(nonatomic, strong) LookinImage *appIcon;
/// @"微信读书"
@property(nonatomic, copy) NSString *appName;
/// hughkli.lookin
@property(nonatomic, copy) NSString *appBundleIdentifier;
/// @"iPhone X"
@property(nonatomic, copy) NSString *deviceDescription;
/// The hardware model identifier, e.g. @"iPhone16,2", @"iPad14,3", @"Mac15,7".
/// On a simulator this is the *simulated* device's identifier, not the host CPU
/// architecture. Nil whenever the model cannot be determined, and always nil when the
/// peer runs a LookinServer predating this field — receivers must keep a fallback path.
@property(nonatomic, copy) NSString *deviceModelIdentifier;
/// @"12.1"
@property(nonatomic, copy) NSString *osDescription;
/// 返回 os 的主版本号，比如 iOS 12.1 的设备将返回 12，iOS 13.2.1 的设备将返回 13
@property(nonatomic, assign) NSUInteger osMainVersion;
/// 设备类型
@property(nonatomic, assign) LookinAppInfoDevice deviceType;
/// 屏幕的宽度
@property(nonatomic, assign) double screenWidth;
/// 屏幕的高度
@property(nonatomic, assign) double screenHeight;
/// 是几倍的屏幕
@property(nonatomic, assign) double screenScale;
@property(nonatomic, assign) NSTimeInterval cachedTimestamp;

- (BOOL)isEqualToAppInfo:(LookinAppInfo *)info;

+ (LookinAppInfo *)currentInfoWithScreenshot:(BOOL)hasScreenshot icon:(BOOL)hasIcon localIdentifiers:(NSArray<NSNumber *> *)localIdentifiers;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
