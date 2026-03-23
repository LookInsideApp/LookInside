#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UITableView+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/9/5.
//  https://lookin.work
//

#import <UIKit/UIKit.h>

@interface UITableView (LookinServer)

- (NSArray<NSNumber *> *)lks_numberOfRows;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
