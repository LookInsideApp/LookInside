//
//  LKReadWindowController.h
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

#import "LKWindowController.h"

@class LookinHierarchyFile, LKPreferenceManager, LookinArchiveDocument;

@interface LKReadWindowController : LKWindowController

/// Phase A 之前的入口:接受 LookinHierarchyFile 直接打开 reader 窗口。
/// Phase F 计划删除,届时由 -initWithDocument: 取代。
- (instancetype)initWithFile:(LookinHierarchyFile *)file;

/// Phase C 引入:NSDocument 走 NSDocumentController 路径时使用。
/// 内部把 document.hierarchyFile 转给 -initWithFile:。
- (instancetype)initWithDocument:(LookinArchiveDocument *)document;

@end
