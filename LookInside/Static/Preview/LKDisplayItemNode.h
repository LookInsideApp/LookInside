//
//  LKDisplayItemNode.h
//  Lookin
//
//  Created by Li Kai on 2019/8/17.
//  https://lookin.work
//

#import <SceneKit/SceneKit.h>

@class LookinDisplayItem, LKPreferenceManager, LKHierarchyDataSource;

@interface LKDisplayItemNode : SCNNode

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource;

/// 在全部 displayItems 里的 idx
@property(nonatomic, assign) NSUInteger index;

/// 3D 视图坐标原点对应的 frameToRoot 坐标点。
/// 由 LKPreviewView 在每次 render 时根据"面积最大的顶层窗口 item"计算得出，
/// 这样最大窗口的中心始终落在 3D 视图的 (0, 0)，其余较小的窗口围绕它分布。
@property(nonatomic, assign) CGPoint referenceCenter;

@property(nonatomic, weak) LKPreferenceManager *preferenceManager;

@property(nonatomic, strong) LookinDisplayItem *displayItem;

@property(nonatomic, assign) BOOL isDarkMode;

@end
