//
//  LKDeviceItem.h
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import <Foundation/Foundation.h>
#import "LookinAppInfo.h"
#import "LookinAttributeModification.h"
#import "LookinCustomAttrModification.h"
#import "LookinAttributesGroup.h"

@class Lookin_PTChannel, LookinDisplayItemTrace, LookinInvocationRequest, LookinHierarchyInfo, LookinStaticAsyncUpdateTasksPackage, LookinStaticAsyncUpdateTask;

@interface LKInspectableApp : NSObject

@property(nonatomic, strong) NSError *serverVersionError;

@property(nonatomic, strong) LookinAppInfo *appInfo;

@property(nonatomic, weak) Lookin_PTChannel *channel;

- (RACSignal *)fetchHierarchyData;

- (RACSignal *)submitInbuiltModification:(LookinAttributeModification *)modification;

/// Variant of `-submitInbuiltModification:` that surfaces the server's raw
/// `LookinErrCode_*` values verbatim instead of remapping them onto the
/// localized `LookinErr_*` constants. The MCPBridge modification route
/// consumes this so it can translate raw codes into structured wire
/// error codes (`modify.objectNotFound`, `modify.invalidSetter`,
/// `modify.exception`, etc.) on the success path the response is the
/// unwrapped `LookinDisplayItemDetail *` exactly as the server sent it.
- (RACSignal *)rawSubmitInbuiltModification:(LookinAttributeModification *)modification;
- (RACSignal *)submitCustomModification:(LookinCustomAttrModification *)modification;

- (RACSignal *)fetchHierarchyDetailWithTaskPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages;
- (void)cancelHierarchyDetailFetching;

- (RACSignal *)fetchModificationPatchWithTasks:(NSArray<LookinStaticAsyncUpdateTask *> *)tasks;

- (RACSignal *)fetchObjectWithOid:(unsigned long)oid;

- (RACSignal *)fetchSelectorNamesWithClass:(NSString *)className hasArg:(BOOL)hasArg;

- (RACSignal *)invokeMethodWithOid:(unsigned long)oid text:(NSString *)text;

/// Variant of `-invokeMethodWithOid:text:` that surfaces the server's raw
/// response dictionary and raw `NSError` codes verbatim, without the
/// console-facing `LookinStringFlag_VoidReturn` → localized description
/// substitution and without remapping `LookinErrCode_ObjectNotFound` /
/// `LookinErrCode_Inner` onto the localized `LookinErr_*` constants. The
/// MCPBridge invocation route consumes this so it can translate the raw
/// server signal into structured machine-readable bridge error codes
/// (`invoke.objectNotFound`, `invoke.invalidSelector`, etc.) while preserving
/// the `returnedVoid` flag on the success path.
- (RACSignal *)rawInvokeMethodWithOid:(unsigned long)oid text:(NSString *)text;

/// 获取某个 imageView 的 image 对象，oid 是 imageView 的 oid
- (RACSignal *)fetchImageWithImageViewOid:(unsigned long)oid;

/// 修改一个 gestureRecognizer 的 enable 属性。如果 shouldBeEnabled 为 YES 则表示想要把它的 enable 属性修改为 YES
- (RACSignal *)modifyGestureRecognizer:(unsigned long)oid toBeEnabled:(BOOL)shouldBeEnabled;

#pragma mark - Push From iOS

@end
