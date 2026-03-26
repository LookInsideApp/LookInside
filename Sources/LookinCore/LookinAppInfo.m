#ifdef SHOULD_COMPILE_LOOKIN_SERVER 

//
//  LookinAppInfo.m
//  qmuidemo
//
//  Created by Li Kai on 2018/11/3.
//  Copyright © 2018 QMUI Team. All rights reserved.
//



#import "LookinAppInfo.h"

static NSString * const CodingKey_AppIcon = @"1";
static NSString * const CodingKey_Screenshot = @"2";
static NSString * const CodingKey_DeviceDescription = @"3";
static NSString * const CodingKey_OsDescription = @"4";
static NSString * const CodingKey_AppName = @"5";
static NSString * const CodingKey_ScreenWidth = @"6";
static NSString * const CodingKey_ScreenHeight = @"7";
static NSString * const CodingKey_DeviceType = @"8";

@implementation LookinAppInfo

+ (Class)_adapterClass {
    return NSClassFromString(@"LKS_MultiplatformAdapter");
}

+ (id)_invokeAdapterSelector:(NSString *)selectorName {
    Class adapterClass = [self _adapterClass];
    SEL selector = NSSelectorFromString(selectorName);
    if (!adapterClass || ![adapterClass respondsToSelector:selector]) {
        return nil;
    }
    NSMethodSignature *signature = [adapterClass methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = adapterClass;
    invocation.selector = selector;
    [invocation invoke];

    const char *returnType = signature.methodReturnType;
    if (strcmp(returnType, @encode(CGRect)) == 0) {
        CGRect value = CGRectZero;
        [invocation getReturnValue:&value];
#if TARGET_OS_OSX
        return [NSValue valueWithRect:value];
#else
        return [NSValue valueWithCGRect:value];
#endif
    }
    if (strcmp(returnType, @encode(CGFloat)) == 0 || strcmp(returnType, @encode(double)) == 0) {
        CGFloat value = 0;
        [invocation getReturnValue:&value];
        return @(value);
    }
    if (strcmp(returnType, @encode(NSUInteger)) == 0) {
        NSUInteger value = 0;
        [invocation getReturnValue:&value];
        return @(value);
    }

    __unsafe_unretained id value = nil;
    [invocation getReturnValue:&value];
    return value;
}

- (id)copyWithZone:(NSZone *)zone {
    LookinAppInfo *newAppInfo = [[LookinAppInfo allocWithZone:zone] init];
    newAppInfo.appIcon = self.appIcon;
    newAppInfo.appName = self.appName;
    newAppInfo.deviceDescription = self.deviceDescription;
    newAppInfo.osDescription = self.osDescription;
    newAppInfo.osMainVersion = self.osMainVersion;
    newAppInfo.deviceType = self.deviceType;
    newAppInfo.screenWidth = self.screenWidth;
    newAppInfo.screenHeight = self.screenHeight;
    newAppInfo.screenScale = self.screenScale;
    newAppInfo.appInfoIdentifier = self.appInfoIdentifier;
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
        self.osDescription = [aDecoder decodeObjectForKey:CodingKey_OsDescription];
        self.osMainVersion = [aDecoder decodeIntegerForKey:@"osMainVersion"];
        self.deviceType = [aDecoder decodeIntegerForKey:CodingKey_DeviceType];
        self.screenWidth = [aDecoder decodeDoubleForKey:CodingKey_ScreenWidth];
        self.screenHeight = [aDecoder decodeDoubleForKey:CodingKey_ScreenHeight];
        self.screenScale = [aDecoder decodeDoubleForKey:@"screenScale"];
        self.appInfoIdentifier = [aDecoder decodeIntegerForKey:@"appInfoIdentifier"];
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
    [aCoder encodeObject:self.osDescription forKey:CodingKey_OsDescription];
    [aCoder encodeInteger:self.osMainVersion forKey:@"osMainVersion"];
    [aCoder encodeInteger:self.deviceType forKey:CodingKey_DeviceType];
    [aCoder encodeDouble:self.screenWidth forKey:CodingKey_ScreenWidth];
    [aCoder encodeDouble:self.screenHeight forKey:CodingKey_ScreenHeight];
    [aCoder encodeDouble:self.screenScale forKey:@"screenScale"];
    [aCoder encodeInteger:self.appInfoIdentifier forKey:@"appInfoIdentifier"];
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

#if TARGET_OS_IPHONE || TARGET_OS_MAC

+ (LookinAppInfo *)currentInfoWithScreenshot:(BOOL)hasScreenshot icon:(BOOL)hasIcon localIdentifiers:(NSArray<NSNumber *> *)localIdentifiers {
    NSInteger selfIdentifier = [self getAppInfoIdentifier];
    if ([localIdentifiers containsObject:@(selfIdentifier)]) {
        LookinAppInfo *info = [LookinAppInfo new];
        info.appInfoIdentifier = selfIdentifier;
        info.shouldUseCache = YES;
        return info;
    }
    
    LookinAppInfo *info = [[LookinAppInfo alloc] init];
    info.serverVersion = LOOKIN_SERVER_VERSION;
    info.serverReadableVersion = LOOKIN_SERVER_READABLE_VERSION;
#ifdef LOOKIN_SERVER_SWIFT_ENABLED
    info.swiftEnabledInLookinServer = 1;
#else
    info.swiftEnabledInLookinServer = -1;
#endif
    info.appInfoIdentifier = selfIdentifier;
    info.appName = [self appName];
    info.appBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
#if TARGET_OS_OSX
    info.deviceDescription = [self _invokeAdapterSelector:@"deviceDescription"] ?: @"Mac";
    info.deviceType = LookinAppInfoDeviceMac;
    info.osDescription = [self _invokeAdapterSelector:@"operatingSystemDescription"] ?: @"macOS";
    info.osMainVersion = [[self _invokeAdapterSelector:@"operatingSystemMainVersion"] unsignedIntegerValue];
#else
    info.deviceDescription = [UIDevice currentDevice].name;
    if ([self isSimulator]) {
        info.deviceType = LookinAppInfoDeviceSimulator;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        info.deviceType = LookinAppInfoDeviceIPad;
    } else {
        info.deviceType = LookinAppInfoDeviceOthers;
    }
    info.osDescription = [UIDevice currentDevice].systemVersion;
    NSString *mainVersionStr = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."].firstObject;
    info.osMainVersion = [mainVersionStr integerValue];
#endif
    
    CGRect screenBounds = CGRectZero;
#if TARGET_OS_OSX
    screenBounds = [(NSValue *)[self _invokeAdapterSelector:@"mainScreenBounds"] rectValue];
#else
    screenBounds = [(NSValue *)[self _invokeAdapterSelector:@"mainScreenBounds"] CGRectValue];
#endif
    CGSize screenSize = screenBounds.size;
    info.screenWidth = screenSize.width;
    info.screenHeight = screenSize.height;
    info.screenScale = [[self _invokeAdapterSelector:@"mainScreenScale"] doubleValue];

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
    NSString *name = [info objectForKey:@"CFBundleName"];
    if (displayName.length) {
        return displayName;
    }
    if (name.length) {
        return name;
    }
    return NSProcessInfo.processInfo.processName;
}

+ (LookinImage *)appIcon {
#if TARGET_OS_TV
    return nil;
#elif TARGET_OS_OSX
    NSImage *icon = [NSApp applicationIconImage];
    if (icon) {
        return icon;
    }
    NSImage *bundleIcon = [NSWorkspace.sharedWorkspace iconForFile:NSBundle.mainBundle.bundlePath];
    if (bundleIcon) {
        return bundleIcon;
    }
    return nil;
#else
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
#endif
}

+ (LookinImage *)screenshotImage {
#if TARGET_OS_OSX
    NSWindow *window = [self _invokeAdapterSelector:@"keyWindow"];
    if (!window) {
        return nil;
    }
    Class adapterClass = [self _adapterClass];
    SEL selector = NSSelectorFromString(@"screenshotForWindow:");
    if (!adapterClass || ![adapterClass respondsToSelector:selector]) {
        return nil;
    }
    NSMethodSignature *signature = [adapterClass methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = adapterClass;
    invocation.selector = selector;
    [invocation setArgument:&window atIndex:2];
    [invocation invoke];
    __unsafe_unretained NSImage *image = nil;
    [invocation getReturnValue:&image];
    return image;
#else
    UIWindow *window = [self _invokeAdapterSelector:@"keyWindow"];
    if (!window) {
        return nil;
    }
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
    
    return image;
#endif
}

+ (BOOL)isSimulator {
    if (TARGET_OS_SIMULATOR) {
        return YES;
    }
    return NO;
}

#endif

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
