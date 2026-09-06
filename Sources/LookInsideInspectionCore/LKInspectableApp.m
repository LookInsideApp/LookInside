#import "LKInspectableApp.h"
#import "LKConnectionManager.h"
#import "LookinConnectionResponseAttachment.h"
#import "LookinDefines.h"

@interface LKInspectableApp ()
@property(nonatomic, weak) LKInspectionSession *boundInspectionSession;
@end

@implementation LKInspectableApp

- (instancetype)init {
    if ((self = [super init])) {
        _transportIdentifier = @"local";
    }
    return self;
}

- (LKInspectionSession *)inspectionSession {
    return self.boundInspectionSession ?: [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:self];
}

- (void)bindInspectionSession:(LKInspectionSession *)session {
    self.boundInspectionSession = session;
}

- (RACSignal *)fetchHierarchyData {
    return [self.inspectionSession refreshHierarchyWithInitiator:@"host"];
}

- (RACSignal *)submitInbuiltModification:(LookinAttributeModification *)modification {
    return [self localizedRequestWithType:LookinRequestTypeInbuiltAttrModification payload:modification];
}

- (RACSignal *)rawSubmitInbuiltModification:(LookinAttributeModification *)modification {
    if (!modification) return [RACSignal error:LookinErr_Inner];
    return [self.inspectionSession requestWithType:LookinRequestTypeInbuiltAttrModification payload:modification];
}

- (RACSignal *)submitCustomModification:(LookinCustomAttrModification *)modification {
    return [self localizedRequestWithType:LookinRequestTypeCustomAttrModification payload:modification];
}

- (RACSignal *)fetchHierarchyDetailWithTaskPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages {
    return [self localizedRequestWithType:LookinRequestTypeHierarchyDetails payload:packages ?: @[]];
}

- (RACSignal *)rawFetchHierarchyDetailWithTaskPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages {
    return [self.inspectionSession requestWithType:LookinRequestTypeHierarchyDetails payload:packages ?: @[]];
}


- (RACSignal *)fetchModificationPatchWithTasks:(NSArray<LookinStaticAsyncUpdateTask *> *)tasks {
    return [self localizedRequestWithType:LookinRequestTypeAttrModificationPatch payload:tasks];
}

- (RACSignal *)fetchObjectWithOid:(unsigned long)objectIdentifier {
    if (!objectIdentifier) return [RACSignal error:LookinErr_Inner];
    return [self localizedRequestWithType:LookinRequestTypeFetchObject payload:@(objectIdentifier)];
}

- (RACSignal *)fetchSelectorNamesWithClass:(NSString *)className hasArg:(BOOL)hasArgument {
    return [self localizedRequestWithType:LookinRequestTypeAllSelectorNames
                                 payload:@{@"className": className, @"hasArg": @(hasArgument)}];
}

- (RACSignal *)invokeMethodWithOid:(unsigned long)objectIdentifier text:(NSString *)selectorName {
    if (!objectIdentifier || !selectorName.length) return [RACSignal error:LookinErr_Inner];
    return [[self localizedRequestWithType:LookinRequestTypeInvokeMethod
                                  payload:@{@"oid": @(objectIdentifier), @"text": selectorName}]
        map:^id(NSDictionary *response) {
            if (![response[@"description"] isEqualToString:LookinStringFlag_VoidReturn]) return response;
            NSMutableDictionary *localizedResponse = response.mutableCopy;
            localizedResponse[@"description"] = NSLocalizedString(@"The method was invoked successfully and no value was returned.", nil);
            return localizedResponse;
        }];
}

- (RACSignal *)rawInvokeMethodWithOid:(unsigned long)objectIdentifier text:(NSString *)selectorName {
    if (!objectIdentifier || !selectorName.length) return [RACSignal error:LookinErr_Inner];
    return [self.inspectionSession requestWithType:LookinRequestTypeInvokeMethod
                                          payload:@{@"oid": @(objectIdentifier), @"text": selectorName}];
}

- (RACSignal *)fetchAttrGroupListWithOid:(unsigned long)objectIdentifier {
    if (!objectIdentifier) return [RACSignal error:LookinErr_Inner];
    return [self localizedRequestWithType:LookinRequestTypeAllAttrGroups payload:@(objectIdentifier)];
}

- (RACSignal *)fetchImageWithImageViewOid:(unsigned long)objectIdentifier {
    if (!objectIdentifier) return [RACSignal error:LookinErr_Inner];
    return [self localizedRequestWithType:LookinRequestTypeFetchImageViewImage payload:@(objectIdentifier)];
}

- (RACSignal *)modifyGestureRecognizer:(unsigned long)objectIdentifier toBeEnabled:(BOOL)shouldBeEnabled {
    if (!objectIdentifier) return [RACSignal error:LookinErr_Inner];
    return [self localizedRequestWithType:LookinRequestTypeModifyRecognizerEnable
                                 payload:@{@"oid": @(objectIdentifier), @"enable": @(shouldBeEnabled)}];
}

- (RACSignal *)localizedRequestWithType:(uint32_t)requestType payload:(id)payload {
    return [[self.inspectionSession requestWithType:requestType payload:payload] catch:^RACSignal *(NSError *error) {
        if ([error.domain isEqualToString:LookinErrorDomain]) {
            if (error.code == LookinErrCode_ObjectNotFound) return [RACSignal error:LookinErr_ObjNotFound];
            if (error.code == LookinErrCode_Inner) return [RACSignal error:LookinErr_Inner];
        }
        return [RACSignal error:error];
    }];
}

- (RACSignal *)performInspectionRequestWithType:(uint32_t)requestType payload:(id)payload {
    if (!self.channel) return [RACSignal error:LookinErr_NoConnect];
    return [[LKConnectionManager.sharedInstance requestWithType:requestType data:payload channel:self.channel]
        flattenMap:^RACSignal *(RACTuple *responseTuple) {
            LookinConnectionResponseAttachment *attachment = responseTuple.first;
            return attachment.error ? [RACSignal error:attachment.error] : [RACSignal return:attachment.data];
        }];
}

@end
