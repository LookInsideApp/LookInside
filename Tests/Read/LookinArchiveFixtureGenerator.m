//
//  LookinArchiveFixtureGenerator.m
//  LookInside
//
//  Writes Fixtures/legacy-host.lookin: a `.lookin` archive encoded exactly as
//  the Objective-C LookinArchiveDocument did before the Read module moved to
//  Swift (`-[LookinArchiveDocument dataOfType:error:]` at ee0827d):
//
//      [NSKeyedArchiver archivedDataWithRootObject:hierarchyFile
//                            requiringSecureCoding:YES error:outError];
//
//  The fixture is committed; this program documents how it was made. Build
//  it the way Scripts/test-launch-toolbar-read.sh builds the tests, against
//  the LookinCore objects, and run it with the output path.
//

#import <AppKit/AppKit.h>
#import "LookinDefines.h"
#import "LookinCoreTypes.h"

// The model classes are plain Swift (`@objc(OriginalName)`, LookinCoreImpl);
// this file declares the members it sets and links against the class
// symbols Swift emits.
@interface LookinObject : NSObject
@property(nonatomic, assign) unsigned long oid;
@property(nonatomic, copy) NSString *memoryAddress;
@property(nonatomic, copy) NSArray<NSString *> *classChainList;
@end

@interface LookinAppInfo : NSObject
@property(nonatomic, copy) NSString *appName;
@property(nonatomic, copy) NSString *appBundleIdentifier;
@property(nonatomic, copy) NSString *deviceDescription;
@property(nonatomic, copy) NSString *osDescription;
@property(nonatomic, assign) NSUInteger osMainVersion;
@property(nonatomic, assign) LookinAppInfoDevice deviceType;
@property(nonatomic, assign) double screenWidth;
@property(nonatomic, assign) double screenHeight;
@property(nonatomic, assign) double screenScale;
@property(nonatomic, assign) int serverVersion;
@property(nonatomic, strong) NSImage *appIcon;
@property(nonatomic, strong) NSImage *screenshot;
@end

@interface LookinDisplayItem : NSObject
@property(nonatomic, strong) LookinObject *windowObject;
@property(nonatomic, strong) LookinObject *viewObject;
@property(nonatomic, strong) LookinObject *layerObject;
@property(nonatomic, assign) CGRect frame;
@property(nonatomic, assign) CGRect bounds;
@property(nonatomic, assign) float alpha;
@property(nonatomic, assign) BOOL representedAsKeyWindow;
@property(nonatomic, assign) BOOL isHidden;
@property(nonatomic, copy) NSString *customDisplayTitle;
@property(nonatomic, strong) NSArray<LookinDisplayItem *> *subitems;
@end

@interface LookinHierarchyInfo : NSObject
@property(nonatomic, strong) LookinAppInfo *appInfo;
@property(nonatomic, copy) NSArray<LookinDisplayItem *> *displayItems;
@property(nonatomic, assign) int serverVersion;
@property(nonatomic, copy) NSArray<NSString *> *collapsedClassList;
@property(nonatomic, copy) NSDictionary<NSString *, id> *colorAlias;
@end

@interface LookinHierarchyFile : NSObject
@property(nonatomic, assign) int serverVersion;
@property(nonatomic, strong) LookinHierarchyInfo *hierarchyInfo;
@property(nonatomic, copy) NSDictionary<NSNumber *, NSData *> *soloScreenshots;
@property(nonatomic, copy) NSDictionary<NSNumber *, NSData *> *groupScreenshots;
@end

static NSData *PNGData(NSInteger side, CGFloat red) {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:side pixelsHigh:side bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    for (NSInteger x = 0; x < side; x++) {
        for (NSInteger y = 0; y < side; y++) {
            [rep setColor:[NSColor colorWithDeviceRed:red green:0.5 blue:0.25 alpha:1] atX:x y:y];
        }
    }
    return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

static LookinObject *Object(unsigned long oid, NSArray<NSString *> *classChain) {
    LookinObject *object = [LookinObject new];
    object.oid = oid;
    object.classChainList = classChain;
    object.memoryAddress = [NSString stringWithFormat:@"0x%lx", oid];
    return object;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            fprintf(stderr, "usage: %s <output.lookin>\n", argv[0]);
            return 2;
        }

        LookinAppInfo *appInfo = [LookinAppInfo new];
        appInfo.appName = @"Fixture App";
        appInfo.appBundleIdentifier = @"app.lookinside.fixture";
        appInfo.deviceDescription = @"iPhone Simulator";
        appInfo.osDescription = @"iOS 26.0";
        appInfo.osMainVersion = 26;
        appInfo.deviceType = LookinAppInfoDeviceSimulator;
        appInfo.screenWidth = 402;
        appInfo.screenHeight = 874;
        appInfo.screenScale = 3;
        appInfo.serverVersion = LOOKIN_SERVER_VERSION;
        appInfo.appIcon = [[NSImage alloc] initWithData:PNGData(4, 0.9)];
        appInfo.screenshot = [[NSImage alloc] initWithData:PNGData(6, 0.1)];

        LookinDisplayItem *window = [LookinDisplayItem new];
        window.windowObject = Object(101, @[@"UIWindow", @"UIView", @"UIResponder", @"NSObject"]);
        window.layerObject = Object(102, @[@"UIWindowLayer", @"CALayer", @"NSObject"]);
        window.frame = CGRectMake(0, 0, 402, 874);
        window.bounds = CGRectMake(0, 0, 402, 874);
        window.alpha = 1;
        window.representedAsKeyWindow = YES;

        LookinDisplayItem *view = [LookinDisplayItem new];
        view.viewObject = Object(201, @[@"UILabel", @"UIView", @"UIResponder", @"NSObject"]);
        view.layerObject = Object(202, @[@"_UILabelLayer", @"CALayer", @"NSObject"]);
        view.frame = CGRectMake(20, 100, 200, 40);
        view.bounds = CGRectMake(0, 0, 200, 40);
        view.alpha = 0.5;
        view.isHidden = NO;
        view.customDisplayTitle = @"Hello";

        LookinDisplayItem *hiddenView = [LookinDisplayItem new];
        hiddenView.viewObject = Object(301, @[@"UIView", @"UIResponder", @"NSObject"]);
        hiddenView.layerObject = Object(302, @[@"CALayer", @"NSObject"]);
        hiddenView.frame = CGRectMake(0, 0, 10, 10);
        hiddenView.bounds = CGRectMake(0, 0, 10, 10);
        hiddenView.isHidden = YES;
        hiddenView.alpha = 1;

        window.subitems = @[view, hiddenView];

        LookinHierarchyInfo *info = [LookinHierarchyInfo new];
        info.appInfo = appInfo;
        info.displayItems = @[window];
        info.serverVersion = LOOKIN_SERVER_VERSION;
        info.collapsedClassList = @[@"UITableViewCellContentView"];
        info.colorAlias = @{@"Brand": @[@1, @0, @0, @1]};

        LookinHierarchyFile *file = [LookinHierarchyFile new];
        file.serverVersion = LOOKIN_SERVER_VERSION;
        file.hierarchyInfo = info;
        // iOS captures key screenshots by the layer oid.
        file.soloScreenshots = @{@(202): PNGData(2, 0.2), @(102): PNGData(3, 0.3)};
        file.groupScreenshots = @{@(102): PNGData(5, 0.4)};

        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:file requiringSecureCoding:YES error:&error];
        if (!data) {
            fprintf(stderr, "encode failed: %s\n", error.description.UTF8String);
            return 1;
        }
        if (![data writeToFile:@(argv[1]) atomically:YES]) {
            fprintf(stderr, "write failed\n");
            return 1;
        }
        printf("wrote %lu bytes\n", (unsigned long)data.length);
    }
    return 0;
}
