//
//  LookinArchiveDocument.m
//  LookInside
//

#import "LookinArchiveDocument.h"
#import "LookinHierarchyFile.h"
#import "LKReadWindowController.h"
#import "LookinDefines.h"

@implementation LookinArchiveDocument

+ (BOOL)autosavesInPlace {
    return NO;
}

+ (BOOL)preservesVersions {
    return NO;
}

+ (BOOL)usesUbiquitousStorage {
    return NO;
}

- (NSArray<NSString *> *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    // Phase E: archives are read-only snapshots; suppress Save / Save As / Duplicate.
    return @[];
}

- (void)makeWindowControllers {
    LKReadWindowController *wc = [[LKReadWindowController alloc] initWithDocument:self];
    [self addWindowController:wc];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (!self.hierarchyFile) {
        NSAssert(NO, @"");
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }

    if ([typeName isEqualToString:@"com.lookin.lookin"]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.hierarchyFile requiringSecureCoding:YES error:outError];
        return data;
    }

    if (outError) {
        *outError = LookinErr_Inner;
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // .lookin archives are non-secure NSKeyedArchiver payloads holding LookinHierarchyFile graphs.
    // Stay on the legacy API to avoid the NSSecureCoding "[NSObject class] allowed list" runtime spam.
    LookinHierarchyFile *hierarchyFile = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
    if (!hierarchyFile) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return NO;
    }

    NSError *verifyError = [LookinHierarchyFile verifyHierarchyFile:hierarchyFile];
    if (verifyError) {
        if (outError) {
            *outError = verifyError;
        }
        return NO;
    }

    self.hierarchyFile = hierarchyFile;
    return YES;
}

@end
