#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookinRuntimeShim.m
//  LookinCore
//
//  See LookinRuntimeShim.h. This file stays Objective-C on purpose.
//

#import "LookinRuntimeShim.h"
#import <TargetConditionals.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <os/lock.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
typedef UIEdgeInsets LookinShimEdgeInsets;
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
typedef NSEdgeInsets LookinShimEdgeInsets;
#endif
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

/// A method's signature and its return type as a string, kept once looked up.
@interface LookinShimMethodSignature : NSObject
@property(nonatomic, strong) NSMethodSignature *signature;
@property(nonatomic, copy) NSString *returnType;
@end

@implementation LookinShimMethodSignature
@end

/// `[target methodSignatureForSelector:selector]` with its return type.
/// -methodSignatureForSelector: is slow (NSObject's walks every adopted
/// protocol for a method description) and the Server asks for every attribute
/// of every node, so the answer is kept per class and selector once it is
/// known that the class implements the selector itself; a method's types never
/// change while its class exists. A selector the class has no method for (one
/// it forwards) is looked up every time, since its signature may depend on the
/// instance.
static LookinShimMethodSignature *LookinShimSignature(id target, SEL selector) {
    Class targetClass = object_getClass(target);
    if (!targetClass || !selector) {
        return nil;
    }
    // Class -> (selector -> signature). Keys are the class and selector
    // pointers (not retained); the inner dictionaries and the signatures are
    // retained.
    static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    static CFMutableDictionaryRef signaturesByClass;
    os_unfair_lock_lock(&lock);
    CFMutableDictionaryRef signaturesBySelector = signaturesByClass ? (CFMutableDictionaryRef)CFDictionaryGetValue(signaturesByClass, (__bridge const void *)targetClass) : NULL;
    LookinShimMethodSignature *cached = signaturesBySelector ? (__bridge LookinShimMethodSignature *)CFDictionaryGetValue(signaturesBySelector, selector) : nil;
    os_unfair_lock_unlock(&lock);
    if (cached) {
        return cached;
    }
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (!signature) {
        return nil;
    }
    LookinShimMethodSignature *result = [LookinShimMethodSignature new];
    result.signature = signature;
    result.returnType = [NSString stringWithUTF8String:signature.methodReturnType];
    if (class_getInstanceMethod(targetClass, selector)) {
        os_unfair_lock_lock(&lock);
        if (!signaturesByClass) {
            signaturesByClass = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
        signaturesBySelector = (CFMutableDictionaryRef)CFDictionaryGetValue(signaturesByClass, (__bridge const void *)targetClass);
        if (!signaturesBySelector) {
            signaturesBySelector = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(signaturesByClass, (__bridge const void *)targetClass, signaturesBySelector);
            CFRelease(signaturesBySelector);
        }
        CFDictionarySetValue(signaturesBySelector, selector, (__bridge const void *)result);
        os_unfair_lock_unlock(&lock);
    }
    return result;
}

NSString *LookinMethodReturnType(id target, SEL selector, NSUInteger *outArgumentCount) {
    LookinShimMethodSignature *cached = LookinShimSignature(target, selector);
    if (!cached) {
        return nil;
    }
    if (outArgumentCount) {
        *outArgumentCount = cached.signature.numberOfArguments;
    }
    return cached.returnType;
}

NSString *LookinMethodArgumentType(id target, SEL selector, NSUInteger index) {
    NSMethodSignature *signature = LookinShimSignature(target, selector).signature;
    if (!signature || index + 2 >= signature.numberOfArguments) {
        return nil;
    }
    return [NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:index + 2]];
}

// LookinErrorDomain and LookinErrCode_Inner, which Swift declares in
// LookinCoreImpl/LookinDefines.swift; this target cannot see Swift, so the
// shim keeps its own copy. Change both together: the error goes over the wire
// in the invoke-method reply (206).
static NSString *const LookinShimErrorDomain = @"LookinError";
static const NSInteger LookinShimErrorCodeInner = -401;

static NSError *LookinInvokeError(NSString *reason) {
    return [NSError errorWithDomain:LookinShimErrorDomain code:LookinShimErrorCodeInner userInfo:@{NSLocalizedDescriptionKey: reason}];
}

static BOOL LookinIsObjectType(const char *type) {
    return type[0] == _C_ID || type[0] == _C_CLASS;
}

/// Calls a getter that returns an object or a scalar directly through
/// objc_msgSend instead of building an NSInvocation, which costs several
/// microseconds a call; the Server reads every attribute of every node this
/// way. Scalars come back boxed exactly as NSInvocation's path boxes them.
/// Sets `*outHandled` to NO, without calling anything, for the return types it
/// leaves to NSInvocation (structs, pointers, void).
static id LookinInvokeGetterDirectly(id target, SEL selector, const char *returnType, BOOL *outHandled) {
    *outHandled = YES;
    switch (returnType[0]) {
        case _C_ID:
        case _C_CLASS:
            return ((id (*)(id, SEL))objc_msgSend)(target, selector);
#define LOOKIN_DIRECT_SCALAR(code, scalarType) \
        case code: { \
            scalarType value = ((scalarType (*)(id, SEL))objc_msgSend)(target, selector); \
            return [NSValue valueWithBytes:&value objCType:returnType]; \
        }
        LOOKIN_DIRECT_SCALAR(_C_CHR, char)
        LOOKIN_DIRECT_SCALAR(_C_UCHR, unsigned char)
        LOOKIN_DIRECT_SCALAR(_C_SHT, short)
        LOOKIN_DIRECT_SCALAR(_C_USHT, unsigned short)
        LOOKIN_DIRECT_SCALAR(_C_INT, int)
        LOOKIN_DIRECT_SCALAR(_C_UINT, unsigned int)
        LOOKIN_DIRECT_SCALAR(_C_LNG, long)
        LOOKIN_DIRECT_SCALAR(_C_ULNG, unsigned long)
        LOOKIN_DIRECT_SCALAR(_C_LNG_LNG, long long)
        LOOKIN_DIRECT_SCALAR(_C_ULNG_LNG, unsigned long long)
        LOOKIN_DIRECT_SCALAR(_C_FLT, float)
        LOOKIN_DIRECT_SCALAR(_C_DBL, double)
        LOOKIN_DIRECT_SCALAR(_C_BOOL, bool)
#undef LOOKIN_DIRECT_SCALAR
        default:
            *outHandled = NO;
            return nil;
    }
}

id LookinInvoke(id target, SEL selector, NSArray *arguments, NSError **outError) {
    NSMethodSignature *signature = LookinShimSignature(target, selector).signature;
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
    if (parameterCount == 0) {
        BOOL handled = NO;
        id directResult = nil;
#if TARGET_OS_WATCH
        // See the NSInvocation path below for why the watch catches here.
        @try {
            directResult = LookinInvokeGetterDirectly(target, selector, signature.methodReturnType, &handled);
        } @catch (NSException *exception) {
            if (outError) {
                *outError = LookinInvokeError([NSString stringWithFormat:@"%@ raised %@: %@", NSStringFromSelector(selector), exception.name, exception.reason ?: @"no reason"]);
            }
            return nil;
        }
#else
        directResult = LookinInvokeGetterDirectly(target, selector, signature.methodReturnType, &handled);
#endif
        if (handled) {
            return directResult;
        }
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
#if TARGET_OS_WATCH
    // The watch's UIKitCore leaves out some selectors its headers declare
    // (-[UIWindowScene pointerLockState] for one), and a getter that calls
    // one raises. Report that instead of ending the app. This is the last
    // line of defence only: the exception unwinds through the Server's Swift
    // getter, which Swift does not promise to survive, so the getters stay
    // away from every selector known to be missing on the watch.
    @try {
        [invocation invoke];
    } @catch (NSException *exception) {
        if (outError) {
            *outError = LookinInvokeError([NSString stringWithFormat:@"%@ raised %@: %@", NSStringFromSelector(selector), exception.name, exception.reason ?: @"no reason"]);
        }
        return nil;
    }
#else
    [invocation invoke];
#endif

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
            return @(@encode(LookinShimEdgeInsets));
        case LookinEncodedTypeCATransform3D:
            return @(@encode(CATransform3D));
        case LookinEncodedTypeNSRange:
            return @(@encode(NSRange));
        case LookinEncodedTypeNSDirectionalEdgeInsets:
            return @(@encode(NSDirectionalEdgeInsets));
        case LookinEncodedTypeCGColorRef:
            return @(@encode(CGColorRef));
        case LookinEncodedTypeCGPathRef:
            return @(@encode(CGPathRef));
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
