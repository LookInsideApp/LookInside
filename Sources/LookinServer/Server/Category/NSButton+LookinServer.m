#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_OSX
//
//  NSButton+LookinServer.m
//  LookinServer
//
//  Created by JH on 2024/11/7.
//

#import "NSButton+LookinServer.h"

@implementation NSButton (LookinServer)
- (NSButtonType)lks_buttonType {
    return [[self valueForKeyPath:@"cell._buttonType"] unsignedIntegerValue];
}
@end
#endif
