//
//  LKHierarchyController.m
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

#import "LKHierarchyController.h"
#import "LKHierarchyDataSource.h"
#import "LookinDisplayItem.h"
#import "LKTableView.h"
#import "LKHierarchyDataSource+KeyDown.h"
#import "LKPreferenceManager.h"

@interface LKHierarchyController ()

@end

@implementation LKHierarchyController

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource {
    LKHierarchyView *hierarchyView = [[LKHierarchyView alloc] initWithDataSource:dataSource];
    hierarchyView.delegate = self;
    if (self = [self initWithContainerView:hierarchyView]) {
        _dataSource = dataSource;
        _hierarchyView = hierarchyView;
    }
    return self;
}

- (NSView *)makeContainerView {
    LKHierarchyView *hierarchyView = [[LKHierarchyView alloc] init];
    hierarchyView.delegate = self;
    _hierarchyView = hierarchyView;
    return hierarchyView;
}

- (NSView *)currentSelectedRowView {
    NSInteger row = [self.dataSource.displayingFlatItems indexOfObject:self.dataSource.selectedItem];
    if (row == NSNotFound) {
//        NSAssert(NO, @"LKHierarchyController, currentSelectedRowView, NSNotFound");
        return nil;
    }
    return [self.hierarchyView.tableView.tableView rowViewAtRow:row makeIfNecessary:NO];
}

- (BOOL)acceptsFirstResponder {
    return true;
}


- (void)keyDown:(NSEvent *)event {
    if ([self.dataSource keyDown:event]) {
        return;
    }

    [super keyDown:event];
}

#pragma mark - <LKHierarchyViewDelegate>

- (void)hierarchyView:(LKHierarchyView *)view didSelectItem:(LookinDisplayItem *)item {
    self.dataSource.selectedItem = item;
}

- (void)hierarchyView:(LKHierarchyView *)view didDoubleClickItem:(LookinDisplayItem *)item {
    LookinDoubleClickBehavior behavior = [[LKPreferenceManager mainManager] doubleClickBehavior];
    if (behavior == LookinDoubleClickBehaviorCollapse) {
        if (!item.isExpandable) {
            return;
        }
        if (item.isExpanded) {
            [self.dataSource collapseItem:item];
        } else {
            [self.dataSource expandItem:item];
        }

    } else if (behavior == LookinDoubleClickBehaviorFocus) {
        [self.dataSource focusDisplayItem:item];
        
    } else {
        NSAssert(NO, @"");
    }
}

/// 注意这里 item 可能为 nil
- (void)hierarchyView:(LKHierarchyView *)view didHoverAtItem:(LookinDisplayItem *)item {
    self.dataSource.hoveredItem = item;
}

- (void)hierarchyView:(LKHierarchyView *)view needToCollapseItem:(LookinDisplayItem *)item {
    [self.dataSource collapseItem:item];
}

- (void)hierarchyView:(LKHierarchyView *)view needToCollapseChildrenOfItem:(LookinDisplayItem *)item {
    [self.dataSource collapseAllChildrenOfItem:item];
}

- (void)hierarchyView:(LKHierarchyView *)view needToExpandItem:(LookinDisplayItem *)item recursively:(BOOL)recursively {
    if (recursively) {
        [self.dataSource expandItemsRootedByItem:item];
    } else {
        [self.dataSource expandItem:item];
    }
}

- (void)hierarchyView:(LKHierarchyView *)view didInputSearchString:(NSString *)string {
    NSLog(@"search string:%@", string);
    if (string.length) {
        [self.dataSource searchWithString:string];
    } else {
        [self.dataSource endSearch];
        if (self.dataSource.selectedItem) {
            // 结束搜索，滚动到选中的 item
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.hierarchyView scrollToMakeItemVisible:self.dataSource.selectedItem];
            });
        }
    }
}

@end
