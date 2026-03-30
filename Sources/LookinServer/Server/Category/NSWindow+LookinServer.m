#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_OSX
//
//  NSWindow+LookinServer.m
//  LookinServer
//
//  Created by JH on 11/5/24.
//

#import "NSWindow+LookinServer.h"
#import "NSObject+LookinServer.h"
#import "LookinIvarTrace.h"
#import "NSArray+Lookin.h"


@implementation NSWindow (LookinServer)

- (NSView *)lks_rootView {
    return self.contentView.superview;
}

- (NSImage *)lks_snapshotImage {
    CGImageRef cgImage = CGWindowListCreateImage(CGRectZero, kCGWindowListOptionIncludingWindow, (int)self.windowNumber, kCGWindowImageBoundsIgnoreFraming);
    if (!cgImage) {
        return nil;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:self.frame.size];
    CGImageRelease(cgImage);
    return image;
}

- (CGRect)lks_bounds {
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    return frame;
}

- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    NSArray<NSString *> *completedList = [self lks_classChainList];
    NSUInteger endingIndex = [completedList indexOfObject:@"NSWindow"];
    if (endingIndex != NSNotFound) {
        completedList = [completedList subarrayWithRange:NSMakeRange(0, endingIndex + 1)];
    }
    [array addObject:completedList];
    if (self.windowController) {
        NSArray<NSString *> *controllerList = [self.windowController lks_classChainList];
        NSUInteger controllerEndingIndex = [controllerList indexOfObject:@"NSWindowController"];
        if (controllerEndingIndex != NSNotFound) {
            controllerList = [controllerList subarrayWithRange:NSMakeRange(0, controllerEndingIndex + 1)];
        }
        [array addObject:controllerList];
    }
    return array.copy;
}

- (NSArray<NSString *> *)lks_selfRelation {
    NSMutableArray *array = [NSMutableArray array];
    if (self.windowController) {
        [array addObject:[NSString stringWithFormat:@"(%@ *).window", NSStringFromClass(self.windowController.class)]];
    }
    if (self.delegate) {
        [array addObject:[NSString stringWithFormat:@"(%@ *) delegate", NSStringFromClass([(NSObject *)self.delegate class])]];
    }
    return array.copy;
}

#pragma mark - StyleMask Flag Accessors

- (BOOL)lks_styleMaskTitled {
    return (self.styleMask & NSWindowStyleMaskTitled) != 0;
}

- (BOOL)lks_styleMaskClosable {
    return (self.styleMask & NSWindowStyleMaskClosable) != 0;
}

- (BOOL)lks_styleMaskMiniaturizable {
    return (self.styleMask & NSWindowStyleMaskMiniaturizable) != 0;
}

- (BOOL)lks_styleMaskResizable {
    return (self.styleMask & NSWindowStyleMaskResizable) != 0;
}

- (BOOL)lks_styleMaskUnifiedTitleAndToolbar {
    return (self.styleMask & NSWindowStyleMaskUnifiedTitleAndToolbar) != 0;
}

- (BOOL)lks_styleMaskFullScreen {
    return (self.styleMask & NSWindowStyleMaskFullScreen) != 0;
}

- (BOOL)lks_styleMaskFullSizeContentView {
    return (self.styleMask & NSWindowStyleMaskFullSizeContentView) != 0;
}

- (BOOL)lks_styleMaskUtilityWindow {
    return (self.styleMask & NSWindowStyleMaskUtilityWindow) != 0;
}

- (BOOL)lks_styleMaskDocModalWindow {
    return (self.styleMask & NSWindowStyleMaskDocModalWindow) != 0;
}

- (BOOL)lks_styleMaskNonactivatingPanel {
    return (self.styleMask & NSWindowStyleMaskNonactivatingPanel) != 0;
}

- (BOOL)lks_styleMaskHUDWindow {
    return (self.styleMask & NSWindowStyleMaskHUDWindow) != 0;
}

- (void)setLks_styleMaskTitled:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskTitled;
    } else {
        self.styleMask &= ~NSWindowStyleMaskTitled;
    }
}

- (void)setLks_styleMaskClosable:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskClosable;
    } else {
        self.styleMask &= ~NSWindowStyleMaskClosable;
    }
}

- (void)setLks_styleMaskMiniaturizable:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskMiniaturizable;
    } else {
        self.styleMask &= ~NSWindowStyleMaskMiniaturizable;
    }
}

- (void)setLks_styleMaskResizable:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskResizable;
    } else {
        self.styleMask &= ~NSWindowStyleMaskResizable;
    }
}

- (void)setLks_styleMaskUnifiedTitleAndToolbar:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskUnifiedTitleAndToolbar;
    } else {
        self.styleMask &= ~NSWindowStyleMaskUnifiedTitleAndToolbar;
    }
}

- (void)setLks_styleMaskFullSizeContentView:(BOOL)value {
    if (value) {
        self.styleMask |= NSWindowStyleMaskFullSizeContentView;
    } else {
        self.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
    }
}

#pragma mark - CollectionBehavior Flag Accessors

- (BOOL)lks_collectionBehaviorCanJoinAllSpaces {
    return (self.collectionBehavior & NSWindowCollectionBehaviorCanJoinAllSpaces) != 0;
}

- (BOOL)lks_collectionBehaviorMoveToActiveSpace {
    return (self.collectionBehavior & NSWindowCollectionBehaviorMoveToActiveSpace) != 0;
}

- (BOOL)lks_collectionBehaviorParticipatesInCycle {
    return (self.collectionBehavior & NSWindowCollectionBehaviorParticipatesInCycle) != 0;
}

- (BOOL)lks_collectionBehaviorIgnoresCycle {
    return (self.collectionBehavior & NSWindowCollectionBehaviorIgnoresCycle) != 0;
}

- (BOOL)lks_collectionBehaviorFullScreenPrimary {
    return (self.collectionBehavior & NSWindowCollectionBehaviorFullScreenPrimary) != 0;
}

- (BOOL)lks_collectionBehaviorFullScreenAuxiliary {
    return (self.collectionBehavior & NSWindowCollectionBehaviorFullScreenAuxiliary) != 0;
}

- (BOOL)lks_collectionBehaviorFullScreenNone {
    return (self.collectionBehavior & NSWindowCollectionBehaviorFullScreenNone) != 0;
}

- (BOOL)lks_collectionBehaviorFullScreenAllowsTiling {
    return (self.collectionBehavior & NSWindowCollectionBehaviorFullScreenAllowsTiling) != 0;
}

- (BOOL)lks_collectionBehaviorFullScreenDisallowsTiling {
    return (self.collectionBehavior & NSWindowCollectionBehaviorFullScreenDisallowsTiling) != 0;
}

@end

#endif
