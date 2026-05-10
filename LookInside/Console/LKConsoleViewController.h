//
//  LKConsoleViewController.h
//  Lookin
//
//  Created by Li Kai on 2019/4/19.
//  https://lookin.work
//

#import "LKBaseViewController.h"

@class LookinObject, LKHierarchyDataSource, LookinLiveDocument;

@interface LKConsoleViewController : LKBaseViewController

- (instancetype)initWithHierarchyDataSource:(LKHierarchyDataSource *)dataSource;

@property(nonatomic, assign) BOOL isControllerShowing;

/// Phase F: forwarded onto the controller's `LKConsoleDataSource` so RPC
/// invocations route through the owning Live Doc's inspectable app.
@property(nonatomic, weak) LookinLiveDocument *liveDocument;

- (void)submitWithObj:(LookinObject *)obj text:(NSString *)text;

@end
