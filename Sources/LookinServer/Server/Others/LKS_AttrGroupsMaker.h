#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  LKS_AttrGroupsMaker.h
//  LookinServer
//
//  Created by Li Kai on 2019/6/6.
//  https://lookin.work
//

#import "LookinDefines.h"

@class LookinAttributesGroup;

@interface LKS_AttrGroupsMaker : NSObject
    
+ (NSArray<LookinAttributesGroup *> *)attrGroupsForLayer:(CALayer *)layer;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
