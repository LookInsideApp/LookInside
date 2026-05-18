//
//  LKNavigationManager.h
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LKLaunchWindowController, LKDynamicWindowController, LKWindowController, LKReadWindowController, LookinHierarchyInfo, LookinHierarchyFile;

@interface LKNavigationManager : NSObject <NSWindowDelegate>

+ (instancetype)sharedInstance;

- (void)showLaunch;

- (void)showLaunchAllowingAutoEnter:(BOOL)allowAutoEnter;

- (void)closeLaunch;

- (void)showPreference;

- (void)showAbout;

- (void)showJsonWindow:(NSString *)json;

/// Phase C 后:thin wrapper,内部走 NSDocumentController openDocumentWithContentsOfURL。
/// 返回值始终为 YES(被异步打开行为接管),错误通过 NSApp presentError: 异步弹出。
- (BOOL)showReaderWithFilePath:(NSString *)filePath error:(NSError **)error;

/// Phase C 后:用一个内存中的 LookinHierarchyFile 创建一个 untitled LookinArchiveDocument,
/// 注册到 NSDocumentController,并显示 reader 窗口。Save As 会弹出落盘对话框。
- (void)showReaderWithHierarchyFile:(LookinHierarchyFile *)file title:(NSString *)title;

@property(nonatomic, strong, readonly) LKLaunchWindowController *launchWindowController;

- (LKWindowController *)currentKeyWindowController;

@property(nonatomic, assign) CGFloat windowTitleBarHeight;

@end
