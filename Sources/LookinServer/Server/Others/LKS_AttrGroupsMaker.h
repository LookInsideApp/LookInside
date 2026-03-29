#if defined(SHOULD_COMPILE_LOOKIN_SERVER)
//
//  LKS_AttrGroupsMaker.h
//  LookinServer
//
//  Created by Li Kai on 2019/6/6.
//  https://lookin.work
//

#import "LookinDefines.h"

@class LookinAttributesGroup;
#if TARGET_OS_OSX
@class NSView, NSWindow;
#endif

@interface LKS_AttrGroupsMaker : NSObject

#if TARGET_OS_OSX

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForView:(NSView *)view;

#endif

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForLayer:(CALayer *)layer;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
