#ifdef SHOULD_COMPILE_LOOKIN_SERVER 

//
//  LookinAppInfo.m
//  qmuidemo
//
//  Created by Li Kai on 2018/11/3.
//  Copyright © 2018 QMUI Team. All rights reserved.
//



#import "LookinAppInfo.h"
#import "LKS_MultiplatformAdapter.h"

#import <sys/sysctl.h>
#if TARGET_OS_OSX
#import <libproc.h>
#endif

#if TARGET_OS_MACCATALYST
#import <objc/message.h>
#endif

static NSString * const CodingKey_AppIcon = @"1";
static NSString * const CodingKey_Screenshot = @"2";
static NSString * const CodingKey_DeviceDescription = @"3";
static NSString * const CodingKey_OsDescription = @"4";
static NSString * const CodingKey_AppName = @"5";
static NSString * const CodingKey_ScreenWidth = @"6";
static NSString * const CodingKey_ScreenHeight = @"7";
static NSString * const CodingKey_DeviceType = @"8";

/// Reads a sysctl entry as a string, or nil when it is unavailable or empty.
static NSString *LookinAppInfoSysctlStringValue(const char *sysctlName) {
    size_t valueSize = 0;
    if (sysctlbyname(sysctlName, NULL, &valueSize, NULL, 0) != 0 || valueSize == 0) {
        return nil;
    }
    char *valueBuffer = malloc(valueSize);
    if (valueBuffer == NULL) {
        return nil;
    }
    NSString *value = nil;
    if (sysctlbyname(sysctlName, valueBuffer, &valueSize, NULL, 0) == 0) {
        value = [NSString stringWithUTF8String:valueBuffer];
    }
    free(valueBuffer);
    return value.length ? value : nil;
}

#if TARGET_OS_MACCATALYST
/// This Mac's user-facing computer name, e.g. @"JH's Mac Studio Ultra". Nil when it cannot
/// be read, which callers must tolerate.
///
/// Reached through the runtime rather than by calling NSHost directly: NSHost is declared
/// only in the AppKit-flavoured Foundation headers, which a Catalyst target does not see —
/// but the class itself is present and functional in the Foundation a Catalyst process
/// links against, so the lookup succeeds at runtime.
///
/// Needed because -[UIDevice name] answers the literal string @"iPad" on Catalyst. That
/// names a device family, not this machine, so it identifies nothing to the person reading
/// the host's device label.
static NSString *LookinAppInfoMacHostLocalizedName(void) {
    Class hostClass = NSClassFromString(@"NSHost");
    SEL currentHostSelector = NSSelectorFromString(@"currentHost");
    if (![hostClass respondsToSelector:currentHostSelector]) {
        return nil;
    }
    id currentHost = ((id (*)(id, SEL))objc_msgSend)(hostClass, currentHostSelector);
    SEL localizedNameSelector = NSSelectorFromString(@"localizedName");
    if (![currentHost respondsToSelector:localizedNameSelector]) {
        return nil;
    }
    id localizedName = ((id (*)(id, SEL))objc_msgSend)(currentHost, localizedNameSelector);
    if (![localizedName isKindOfClass:[NSString class]] || [(NSString *)localizedName length] == 0) {
        return nil;
    }
    return localizedName;
}
#endif

@implementation LookinAppInfo

- (id)copyWithZone:(NSZone *)zone {
    LookinAppInfo *newAppInfo = [[LookinAppInfo allocWithZone:zone] init];
    newAppInfo.appIcon = self.appIcon;
    newAppInfo.appName = self.appName;
    newAppInfo.deviceDescription = self.deviceDescription;
    newAppInfo.deviceModelIdentifier = self.deviceModelIdentifier;
    newAppInfo.osDescription = self.osDescription;
    newAppInfo.osMainVersion = self.osMainVersion;
    newAppInfo.deviceType = self.deviceType;
    newAppInfo.screenWidth = self.screenWidth;
    newAppInfo.screenHeight = self.screenHeight;
    newAppInfo.screenScale = self.screenScale;
    newAppInfo.appInfoIdentifier = self.appInfoIdentifier;
    newAppInfo.processIdentifier = self.processIdentifier;
    newAppInfo.processStartIdentifier = self.processStartIdentifier;
    newAppInfo.cachedTimestamp = self.cachedTimestamp;
    return newAppInfo;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        
        self.serverVersion = [aDecoder decodeIntForKey:@"serverVersion"];
        self.serverReadableVersion = [aDecoder decodeObjectForKey:@"serverReadableVersion"];
        self.swiftEnabledInLookinServer = [aDecoder decodeIntForKey:@"swiftEnabledInLookinServer"];
        NSData *screenshotData = [aDecoder decodeObjectForKey:CodingKey_Screenshot];
        self.screenshot = [[LookinImage alloc] initWithData:screenshotData];
        
        NSData *appIconData = [aDecoder decodeObjectForKey:CodingKey_AppIcon];
        self.appIcon = [[LookinImage alloc] initWithData:appIconData];
        
        self.appName = [aDecoder decodeObjectForKey:CodingKey_AppName];
        self.appBundleIdentifier = [aDecoder decodeObjectForKey:@"appBundleIdentifier"];
        self.deviceDescription = [aDecoder decodeObjectForKey:CodingKey_DeviceDescription];
        self.deviceModelIdentifier = [aDecoder decodeObjectForKey:@"deviceModelIdentifier"];
        self.osDescription = [aDecoder decodeObjectForKey:CodingKey_OsDescription];
        self.osMainVersion = [aDecoder decodeIntegerForKey:@"osMainVersion"];
        self.deviceType = [aDecoder decodeIntegerForKey:CodingKey_DeviceType];
        self.screenWidth = [aDecoder decodeDoubleForKey:CodingKey_ScreenWidth];
        self.screenHeight = [aDecoder decodeDoubleForKey:CodingKey_ScreenHeight];
        self.screenScale = [aDecoder decodeDoubleForKey:@"screenScale"];
        self.appInfoIdentifier = [aDecoder decodeIntegerForKey:@"appInfoIdentifier"];
        if ([aDecoder containsValueForKey:@"processIdentifier"]) {
            self.processIdentifier = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"processIdentifier"];
        }
        if ([aDecoder containsValueForKey:@"processStartIdentifier"]) {
            self.processStartIdentifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"processStartIdentifier"];
        }
        self.shouldUseCache = [aDecoder decodeBoolForKey:@"shouldUseCache"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:self.serverVersion forKey:@"serverVersion"];
    [aCoder encodeObject:self.serverReadableVersion forKey:@"serverReadableVersion"];
    [aCoder encodeInt:self.swiftEnabledInLookinServer forKey:@"swiftEnabledInLookinServer"];
    
#if TARGET_OS_IPHONE
    NSData *screenshotData = UIImagePNGRepresentation(self.screenshot);
    [aCoder encodeObject:screenshotData forKey:CodingKey_Screenshot];
    
    NSData *appIconData = UIImagePNGRepresentation(self.appIcon);
    [aCoder encodeObject:appIconData forKey:CodingKey_AppIcon];
#elif TARGET_OS_OSX
    NSData *screenshotData = [self.screenshot TIFFRepresentation];
    [aCoder encodeObject:screenshotData forKey:CodingKey_Screenshot];
    
    NSData *appIconData = [self.appIcon TIFFRepresentation];
    [aCoder encodeObject:appIconData forKey:CodingKey_AppIcon];
#endif
    
    [aCoder encodeObject:self.appName forKey:CodingKey_AppName];
    [aCoder encodeObject:self.appBundleIdentifier forKey:@"appBundleIdentifier"];
    [aCoder encodeObject:self.deviceDescription forKey:CodingKey_DeviceDescription];
    [aCoder encodeObject:self.deviceModelIdentifier forKey:@"deviceModelIdentifier"];
    [aCoder encodeObject:self.osDescription forKey:CodingKey_OsDescription];
    [aCoder encodeInteger:self.osMainVersion forKey:@"osMainVersion"];
    [aCoder encodeInteger:self.deviceType forKey:CodingKey_DeviceType];
    [aCoder encodeDouble:self.screenWidth forKey:CodingKey_ScreenWidth];
    [aCoder encodeDouble:self.screenHeight forKey:CodingKey_ScreenHeight];
    [aCoder encodeDouble:self.screenScale forKey:@"screenScale"];
    [aCoder encodeInteger:self.appInfoIdentifier forKey:@"appInfoIdentifier"];
    [aCoder encodeObject:self.processIdentifier forKey:@"processIdentifier"];
    [aCoder encodeObject:self.processStartIdentifier forKey:@"processStartIdentifier"];
    [aCoder encodeBool:self.shouldUseCache forKey:@"shouldUseCache"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LookinAppInfo class]]) {
        return NO;
    }
    if ([self isEqualToAppInfo:object]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.appName.hash ^ self.deviceDescription.hash ^ self.osDescription.hash ^ self.deviceType;
}

- (BOOL)isEqualToAppInfo:(LookinAppInfo *)info {
    if (!info) {
        return NO;
    }
    if ([self.appName isEqualToString:info.appName] && [self.deviceDescription isEqualToString:info.deviceDescription] && [self.osDescription isEqualToString:info.osDescription] && self.deviceType == info.deviceType) {
        return YES;
    }
    return NO;
}


+ (LookinAppInfo *)currentInfoWithScreenshot:(BOOL)hasScreenshot icon:(BOOL)hasIcon localIdentifiers:(NSArray<NSNumber *> *)localIdentifiers {
    NSInteger selfIdentifier = [self getAppInfoIdentifier];
    if ([localIdentifiers containsObject:@(selfIdentifier)]) {
        LookinAppInfo *info = [LookinAppInfo new];
        info.appInfoIdentifier = selfIdentifier;
        info.shouldUseCache = YES;
        return info;
    }
    
    LookinAppInfo *info = [[LookinAppInfo alloc] init];
    info.serverReadableVersion = LOOKIN_SERVER_READABLE_VERSION;
// Report Swift optimization as enabled whenever the Swift-aware build is
// compiled in. The CocoaPods subspec path defines LOOKIN_SERVER_SWIFT_ENABLED;
// the SwiftPM / XCFramework path defines SPM_LOOKIN_SERVER_ENABLED (which in
// turn imports LookinServerSwift and activates LOOKIN_SERVER_SWIFT_ENABLED_SUCCESSFULLY
// in LKS_TraceManager). Both imply the optimization is active, matching the
// contract documented on -swiftEnabledInLookinServer ("SPM 或 Swift Subspec → 1").
#if defined(LOOKIN_SERVER_SWIFT_ENABLED) || defined(SPM_LOOKIN_SERVER_ENABLED)
    info.swiftEnabledInLookinServer = 1;
#else
    info.swiftEnabledInLookinServer = -1;
#endif
    info.appInfoIdentifier = selfIdentifier;
    info.appName = [self appName];
#if TARGET_OS_OSX
    struct proc_bsdinfo processInformation = {0};
    if (proc_pidinfo(getpid(), PROC_PIDTBSDINFO, 0, &processInformation, sizeof(processInformation)) == sizeof(processInformation)) {
        info.processIdentifier = @(getpid());
        info.processStartIdentifier = [NSString stringWithFormat:@"%llu:%llu", processInformation.pbi_start_tvsec, processInformation.pbi_start_tvusec];
    }
#endif
#if TARGET_OS_MACCATALYST
    // Ask the Mac for its own name. -[UIDevice name] is still consulted as a last resort so
    // the field is never empty, but on Catalyst it only ever answers @"iPad".
    info.deviceDescription = LookinAppInfoMacHostLocalizedName() ?: [UIDevice currentDevice].name;
#elif TARGET_OS_IPHONE
    info.deviceDescription = [UIDevice currentDevice].name;
#elif TARGET_OS_OSX
    info.deviceDescription = [NSHost currentHost].localizedName;
#endif
    info.deviceModelIdentifier = [self currentDeviceModelIdentifier];
    info.appBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([self isSimulator]) {
        info.deviceType = LookinAppInfoDeviceSimulator;
    } else if ([LKS_MultiplatformAdapter isMacCatalyst]) {
        // Must precede the iPad check: -[UIDevice model] reports "iPad" on Catalyst, so
        // +isiPad matches a Catalyst build too and would otherwise claim it first. +isMac
        // never fires here either — TARGET_OS_OSX is 0 for the Catalyst destination.
        info.deviceType = LookinAppInfoDeviceMacCatalyst;
    } else if ([LKS_MultiplatformAdapter isiPad]) {
        info.deviceType = LookinAppInfoDeviceIPad;
    } else if ([LKS_MultiplatformAdapter isMac]) {
        info.deviceType = LookinAppInfoDeviceMac;
    } else {
        info.deviceType = LookinAppInfoDeviceOthers;
    }

#if TARGET_OS_IPHONE
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
#if TARGET_OS_MACCATALYST
    // On Catalyst -[UIDevice systemVersion] answers the *macOS* version (@"26.6" on macOS
    // 26.6), not the iOS version Catalyst maps onto. Calling that "iOS 26.6" would be wrong
    // twice over — wrong OS, and a version number that OS never shipped.
    info.osDescription = [NSString stringWithFormat:@"macCatalyst %@", systemVersion];
#else
    info.osDescription = [NSString stringWithFormat:@"iOS %@", systemVersion];
#endif
    NSString *mainVersionStr = [systemVersion componentsSeparatedByString:@"."].firstObject;
    info.osMainVersion = [mainVersionStr integerValue];
#elif TARGET_OS_OSX
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.patchVersion) {
        info.osDescription = [NSString stringWithFormat:@"macOS %ld.%ld.%ld", operatingSystemVersion.majorVersion, operatingSystemVersion.minorVersion, operatingSystemVersion.patchVersion];
    } else {
        info.osDescription = [NSString stringWithFormat:@"macOS %ld.%ld", operatingSystemVersion.majorVersion, operatingSystemVersion.minorVersion];
    }
    info.osMainVersion = operatingSystemVersion.majorVersion;
#endif
    
    
    CGSize screenSize = [LKS_MultiplatformAdapter mainScreenBounds].size;
    info.screenWidth = screenSize.width;
    info.screenHeight = screenSize.height;
    info.screenScale = [LKS_MultiplatformAdapter mainScreenScale];

    if (hasScreenshot) {
        info.screenshot = [self screenshotImage];
    }
    if (hasIcon) {
        info.appIcon = [self appIcon];
    }
    
    return info;
}

+ (NSString *)appName {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *displayName = [info objectForKey:@"CFBundleDisplayName"];
    if (displayName.length) return displayName;
    NSString *name = [info objectForKey:@"CFBundleName"];
    if (name.length) return name;
    return [NSProcessInfo processInfo].processName;
}

+ (LookinImage *)appIcon {
#if TARGET_OS_TV
    return nil;
#elif TARGET_OS_IPHONE
    NSString *imageName;
    id CFBundleIcons = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"];
    if ([CFBundleIcons respondsToSelector:@selector(objectForKey:)]) {
        id CFBundlePrimaryIcon = [CFBundleIcons objectForKey:@"CFBundlePrimaryIcon"];
        if ([CFBundlePrimaryIcon respondsToSelector:@selector(objectForKey:)]) {
            imageName = [[CFBundlePrimaryIcon objectForKey:@"CFBundleIconFiles"] lastObject];
        } else if ([CFBundlePrimaryIcon isKindOfClass:NSString.class]) {
            imageName = CFBundlePrimaryIcon;
        }
    }
    if (!imageName.length) {
        // 正常情况下拿到的 name 可能比如 “AppIcon60x60”。但某些情况可能为 nil，此时直接 return 否则 [UIImage imageNamed:nil] 可能导致 console 报 "CUICatalog: Invalid asset name supplied: '(null)'" 的错误信息
        return nil;
    }
    return [UIImage imageNamed:imageName];
#elif TARGET_OS_OSX
    return [[NSApplication sharedApplication] applicationIconImage];
#endif
}

+ (LookinImage *)screenshotImage {
    LookinWindow *window = [LKS_MultiplatformAdapter keyWindow];
#if TARGET_OS_OSX
    // macOS 上当应用失去焦点或处于后台时 keyWindow 为 nil。
    // 回退到第一个可见窗口（优先 mainWindow，其次任意已排序的窗口）。
    if (!window) {
        window = [NSApplication sharedApplication].mainWindow;
    }
    if (!window) {
        window = [NSApplication sharedApplication].windows.firstObject;
    }
#endif
    if (!window) {
        return nil;
    }
#if TARGET_OS_IPHONE
    CGSize size = window.bounds.size;
    if (size.width <= 0 || size.height <= 0) {
        // *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'UIGraphicsBeginImageContext() failed to allocate CGBitampContext: size={0, 0}, scale=3.000000, bitmapInfo=0x2002. Use UIGraphicsImageRenderer to avoid this assert.'

        // https://github.com/hughkli/Lookin/issues/21
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.4);
    [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#elif TARGET_OS_OSX
    if (!window) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // ScreenCaptureKit replacement is async and prompts for screen recording permission; keep the
    // synchronous CGWindowListCreateImage for capturing our own app window thumbnails.
    CGImageRef cgImage = CGWindowListCreateImage(CGRectZero, kCGWindowListOptionIncludingWindow, (int)window.windowNumber, kCGWindowImageBoundsIgnoreFraming);
#pragma clang diagnostic pop
    if (!cgImage) {
        return nil;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:window.frame.size];
    CGImageRelease(cgImage);
#endif
    
    return image;
}

+ (BOOL)isSimulator {
    if (TARGET_OS_SIMULATOR) {
        return YES;
    }
    return NO;
}

/// The hardware model identifier of the device this process runs on, e.g. @"iPhone16,2".
/// Returns nil when it cannot be determined, which callers must tolerate.
+ (NSString *)currentDeviceModelIdentifier {
    static dispatch_once_t onceToken;
    static NSString *modelIdentifier = nil;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_SIMULATOR
        // hw.machine reports the *host* Mac's architecture ("arm64") inside a simulator,
        // which identifies no device at all. The simulated model is only available from
        // the environment simctl prepares for the process.
        modelIdentifier = [[NSProcessInfo processInfo].environment[@"SIMULATOR_MODEL_IDENTIFIER"] copy];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
        // On macOS hw.machine is the CPU architecture; the Mac model lives in hw.model.
        modelIdentifier = LookinAppInfoSysctlStringValue("hw.model");
#else
        modelIdentifier = LookinAppInfoSysctlStringValue("hw.machine");
#endif
    });
    return modelIdentifier;
}


+ (NSInteger)getAppInfoIdentifier {
    static dispatch_once_t onceToken;
    static NSInteger identifier = 0;
    dispatch_once(&onceToken,^{
        uint64_t nowMicros = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000000.0);
        uint64_t processID = (uint64_t)NSProcessInfo.processInfo.processIdentifier;
        uint64_t randomBits = arc4random();
        identifier = (NSInteger)((nowMicros << 12) ^ (processID << 1) ^ randomBits);
        if (identifier <= 0) {
            identifier = (NSInteger)(processID ^ (randomBits ?: 1));
        }
    });
    return identifier;
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
