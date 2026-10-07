#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookinRuntimeShim.h
//  LookinCore
//
//  The few Objective-C runtime operations Swift cannot express, for the
//  Swift implementations in LookinCoreImpl and LookinServerImpl:
//  catching NSExceptions, NSInvocation (calls whose argument and return types
//  are only known from the method signature), the exact @encode strings, and
//  ptrauth_strip on arm64e. Each helper does what the Objective-C original
//  did inline; keep their behaviour exactly as is.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Exceptions

/// Runs `block` inside @try and returns the NSException it raised, or nil.
/// Swift cannot catch Objective-C exceptions; use this wherever the original
/// had a @try / @catch.
FOUNDATION_EXPORT NSException *_Nullable LookinCatchException(NS_NOESCAPE void (^block)(void)) NS_SWIFT_NAME(LookinCatchException(_:));

#pragma mark - NSInvocation

/// The `@encode` string of the return type of `selector` on `target`
/// (`[[target methodSignatureForSelector:selector] methodReturnType]`), or
/// nil when `target` does not answer `selector`. `outArgumentCount`, when not
/// NULL, receives `numberOfArguments` (2 for a method without parameters).
FOUNDATION_EXPORT NSString *_Nullable LookinMethodReturnType(id target, SEL selector, NSUInteger *_Nullable outArgumentCount);

/// The `@encode` string of the parameter at `index` (0 = first parameter after
/// self and _cmd), or nil when there is no such parameter.
FOUNDATION_EXPORT NSString *_Nullable LookinMethodArgumentType(id target, SEL selector, NSUInteger index);

/// Calls `selector` on `target` through NSInvocation, as the Objective-C code
/// did.
///
/// Each element of `arguments` supplies one parameter, in order:
///   - an NSValue whose `objCType` has the same size as the parameter type: its
///     bytes are copied in (build it with `NSValue(bytes:objCType:)` and
///     `LookinEncoding(_:)`, or `NSNumber` for scalars of the matching type);
///   - any other object, or NSNull for nil: passed as an object parameter.
///
/// The return value comes back as:
///   - nil for a void method or a nil object;
///   - the object (or Class) itself for `@` / `#` return types;
///   - otherwise an NSValue holding the raw return bytes with `objCType` equal
///     to the method's return type (read it with `-getValue:size:`).
///
/// The invocation is not wrapped in @try: an exception propagates exactly as
/// before, so call it inside LookinCatchException where the original caught.
/// Returns nil and sets `*outError` when `target` does not answer `selector`
/// or an argument does not fit its parameter; it never invokes in that case.
FOUNDATION_EXPORT id _Nullable LookinInvoke(id target, SEL selector, NSArray *_Nullable arguments, NSError *_Nullable *_Nullable outError);

#pragma mark - @encode

/// The types the server compares method signatures and NSValue contents
/// against. Swift has no @encode; use `LookinEncoding(_:)` instead of
/// hand-written strings.
typedef NS_ENUM(NSInteger, LookinEncodedType) {
    LookinEncodedTypeVoid,
    LookinEncodedTypeId,
    LookinEncodedTypeClass,
    LookinEncodedTypeSEL,
    LookinEncodedTypeChar,
    LookinEncodedTypeInt,
    LookinEncodedTypeShort,
    LookinEncodedTypeLong,
    LookinEncodedTypeLongLong,
    LookinEncodedTypeUnsignedChar,
    LookinEncodedTypeUnsignedInt,
    LookinEncodedTypeUnsignedShort,
    LookinEncodedTypeUnsignedLong,
    LookinEncodedTypeUnsignedLongLong,
    LookinEncodedTypeFloat,
    LookinEncodedTypeDouble,
    LookinEncodedTypeBOOL,
    LookinEncodedTypeCGPoint,
    LookinEncodedTypeCGVector,
    LookinEncodedTypeCGSize,
    LookinEncodedTypeCGRect,
    LookinEncodedTypeCGAffineTransform,
    LookinEncodedTypeLookinInsets,
#if TARGET_OS_IPHONE
    LookinEncodedTypeUIOffset,
#endif
};

/// `@encode(T)` for `type` (`LookinEncodedTypeLookinInsets` is UIEdgeInsets on
/// UIKit, NSEdgeInsets on AppKit).
FOUNDATION_EXPORT NSString *LookinEncoding(LookinEncodedType type);

#pragma mark - Pointer authentication

/// `ptrauth_strip(pointer, ptrauth_key_process_independent_data)` on arm64e,
/// the pointer unchanged elsewhere.
FOUNDATION_EXPORT const void *_Nullable LookinStripProcessIndependentDataPointer(const void *_Nullable pointer);

/// Reads the SEL stored in the instance variable `ivarName` of `object`
/// without going through KVC, stripping its pointer signature on arm64e
/// (UIKit signs `UIGestureRecognizerTarget._action` there; the raw value
/// faults in NSStringFromSelector). NULL when the class has no such ivar.
FOUNDATION_EXPORT SEL _Nullable LookinReadSelectorIvar(id object, const char *ivarName);

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
