#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookinRuntimeShim.m
//  LookinCore
//
//  See LookinRuntimeShim.h. This file stays Objective-C on purpose.
//

#import "LookinRuntimeShim.h"
#import "LookinDefines.h"
#import <objc/runtime.h>
#if __has_feature(ptrauth_calls)
#import <ptrauth.h>
#endif

NSException *LookinCatchException(NS_NOESCAPE void (^block)(void)) {
    @try {
        block();
    } @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

NSString *LookinMethodReturnType(id target, SEL selector, NSUInteger *outArgumentCount) {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (!signature) {
        return nil;
    }
    if (outArgumentCount) {
        *outArgumentCount = signature.numberOfArguments;
    }
    return [NSString stringWithUTF8String:signature.methodReturnType];
}

NSString *LookinMethodArgumentType(id target, SEL selector, NSUInteger index) {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (!signature || index + 2 >= signature.numberOfArguments) {
        return nil;
    }
    return [NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:index + 2]];
}

static NSError *LookinInvokeError(NSString *reason) {
    return [NSError errorWithDomain:LookinErrorDomain code:LookinErrCode_Inner userInfo:@{NSLocalizedDescriptionKey: reason}];
}

static BOOL LookinIsObjectType(const char *type) {
    return type[0] == _C_ID || type[0] == _C_CLASS;
}

id LookinInvoke(id target, SEL selector, NSArray *arguments, NSError **outError) {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (!signature) {
        if (outError) {
            *outError = LookinInvokeError([NSString stringWithFormat:@"%@ does not respond to %@", [target class], NSStringFromSelector(selector)]);
        }
        return nil;
    }
    NSUInteger parameterCount = signature.numberOfArguments - 2;
    if (arguments.count != parameterCount) {
        if (outError) {
            *outError = LookinInvokeError([NSString stringWithFormat:@"%@ takes %lu arguments, got %lu", NSStringFromSelector(selector), (unsigned long)parameterCount, (unsigned long)arguments.count]);
        }
        return nil;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    // Argument buffers must outlive -invoke; NSInvocation copies them in
    // -setArgument:atIndex:, so a scoped buffer per argument is enough.
    for (NSUInteger index = 0; index < parameterCount; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index + 2];
        id argument = arguments[index];
        if (LookinIsObjectType(type)) {
            __unsafe_unretained id object = (argument == [NSNull null]) ? nil : argument;
            [invocation setArgument:&object atIndex:index + 2];
            continue;
        }
        if (![argument isKindOfClass:[NSValue class]]) {
            if (outError) {
                *outError = LookinInvokeError([NSString stringWithFormat:@"argument %lu of %@ needs an NSValue", (unsigned long)index, NSStringFromSelector(selector)]);
            }
            return nil;
        }
        NSUInteger parameterSize = 0;
        NSGetSizeAndAlignment(type, &parameterSize, NULL);
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment([(NSValue *)argument objCType], &valueSize, NULL);
        if (parameterSize != valueSize) {
            if (outError) {
                *outError = LookinInvokeError([NSString stringWithFormat:@"argument %lu of %@ has size %lu, the parameter %lu", (unsigned long)index, NSStringFromSelector(selector), (unsigned long)valueSize, (unsigned long)parameterSize]);
            }
            return nil;
        }
        void *buffer = calloc(1, parameterSize);
        [(NSValue *)argument getValue:buffer size:parameterSize];
        [invocation setArgument:buffer atIndex:index + 2];
        free(buffer);
    }
    [invocation invoke];

    const char *returnType = signature.methodReturnType;
    if (returnType[0] == _C_VOID) {
        return nil;
    }
    if (LookinIsObjectType(returnType)) {
        __unsafe_unretained id returnValue = nil;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    NSUInteger returnLength = signature.methodReturnLength;
    void *returnBuffer = calloc(1, returnLength);
    [invocation getReturnValue:returnBuffer];
    NSValue *value = [NSValue valueWithBytes:returnBuffer objCType:returnType];
    free(returnBuffer);
    return value;
}

NSString *LookinEncoding(LookinEncodedType type) {
    switch (type) {
        case LookinEncodedTypeVoid:
            return @(@encode(void));
        case LookinEncodedTypeId:
            return @(@encode(id));
        case LookinEncodedTypeClass:
            return @(@encode(Class));
        case LookinEncodedTypeSEL:
            return @(@encode(SEL));
        case LookinEncodedTypeChar:
            return @(@encode(char));
        case LookinEncodedTypeInt:
            return @(@encode(int));
        case LookinEncodedTypeShort:
            return @(@encode(short));
        case LookinEncodedTypeLong:
            return @(@encode(long));
        case LookinEncodedTypeLongLong:
            return @(@encode(long long));
        case LookinEncodedTypeUnsignedChar:
            return @(@encode(unsigned char));
        case LookinEncodedTypeUnsignedInt:
            return @(@encode(unsigned int));
        case LookinEncodedTypeUnsignedShort:
            return @(@encode(unsigned short));
        case LookinEncodedTypeUnsignedLong:
            return @(@encode(unsigned long));
        case LookinEncodedTypeUnsignedLongLong:
            return @(@encode(unsigned long long));
        case LookinEncodedTypeFloat:
            return @(@encode(float));
        case LookinEncodedTypeDouble:
            return @(@encode(double));
        case LookinEncodedTypeBOOL:
            return @(@encode(BOOL));
        case LookinEncodedTypeCGPoint:
            return @(@encode(CGPoint));
        case LookinEncodedTypeCGVector:
            return @(@encode(CGVector));
        case LookinEncodedTypeCGSize:
            return @(@encode(CGSize));
        case LookinEncodedTypeCGRect:
            return @(@encode(CGRect));
        case LookinEncodedTypeCGAffineTransform:
            return @(@encode(CGAffineTransform));
        case LookinEncodedTypeLookinInsets:
            return @(@encode(LookinInsets));
#if TARGET_OS_IPHONE
        case LookinEncodedTypeUIOffset:
            return @(@encode(UIOffset));
#endif
    }
    return @"";
}

const void *LookinStripProcessIndependentDataPointer(const void *pointer) {
#if __has_feature(ptrauth_calls)
    return ptrauth_strip(pointer, ptrauth_key_process_independent_data);
#else
    return pointer;
#endif
}

SEL LookinReadSelectorIvar(id object, const char *ivarName) {
    Ivar ivar = class_getInstanceVariable([object class], ivarName);
    if (!ivar) {
        return NULL;
    }
    void *raw = *(void **)((uint8_t *)(__bridge void *)object + ivar_getOffset(ivar));
    return (SEL)LookinStripProcessIndependentDataPointer(raw);
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
