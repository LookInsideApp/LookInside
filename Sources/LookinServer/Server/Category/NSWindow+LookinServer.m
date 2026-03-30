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

@end

#endif
