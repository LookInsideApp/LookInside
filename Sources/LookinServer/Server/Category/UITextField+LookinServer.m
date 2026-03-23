#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UITextField+LookinServer.m
//  LookinServer
//
//  Created by Li Kai on 2019/2/26.
//  https://lookin.work
//

#import "UITextField+LookinServer.h"

@implementation UITextField (LookinServer)

- (CGFloat)lks_fontSize {
    return self.font.pointSize;
}
- (void)setLks_fontSize:(CGFloat)lks_fontSize {
    UIFont *font = [self.font fontWithSize:lks_fontSize];
    self.font = font;
}

- (NSString *)lks_fontName {
    return self.font.fontName;
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
