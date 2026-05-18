//
//  LKLaunchWindowController.h
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import "LKWindowController.h"

@class LKLaunchViewController;

@interface LKLaunchWindowController : LKWindowController

- (instancetype)initWithAutoEnterOnInitialReload:(BOOL)autoEnterOnInitialReload;

@property(nonatomic, strong, readonly) LKLaunchViewController *launchViewController;

@end
