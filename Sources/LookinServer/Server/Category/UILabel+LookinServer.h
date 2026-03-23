#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UILabel+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/2/26.
//  https://lookin.work
//

#import <UIKit/UIKit.h>

@interface UILabel (LookinServer)

@property(nonatomic, assign) CGFloat lks_fontSize;

- (NSString *)lks_fontName;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
