//
//  LKDashboardSearchMethodsDataSource.h
//  Lookin
//
//  Created by Li Kai on 2019/9/6.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LookinLiveDocument;

@interface LKDashboardSearchMethodsDataSource : NSObject

/// Phase F: Live Doc that owns this dashboard search session. The single
/// caller (`LKDashboardViewController`) injects it after constructing the
/// data source so RPCs route through the per-doc inspectable app instead
/// of the deprecated single-slot global.
@property(nonatomic, weak) LookinLiveDocument *liveDocument;

- (RACSignal *)fetchNonArgMethodsListWithClass:(NSString *)className;

- (void)clearAllCache;

@end
