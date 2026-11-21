// Umbrella header of the LookinCore module.
//
// Only C declarations live here: the exported attribute identifier
// constants, the archived enums, the NSStringFrom* prototypes the Swift
// `@_cdecl` functions export, and the runtime shim (NSException catching,
// NSInvocation, @encode, ptrauth_strip). Versions, ports, request numbers,
// parameter keys and error codes are Swift (LookinCoreImpl/LookinDefines.swift).
// The model classes and categories are plain Swift in LookinCoreImpl,
// declared with `@objc(OriginalName)` and their original selectors, so
// archived class names and Objective-C callers are unchanged.
//
// SwiftPM does not pass a target's C defines to Swift's Clang importer, so the
// guard the headers are wrapped in is defined here first.

#ifndef SHOULD_COMPILE_LOOKIN_SERVER
#define SHOULD_COMPILE_LOOKIN_SERVER 1
#endif

#import <Foundation/Foundation.h>
#import "LookinAttrType.h"
#import "LookinCodingValueType.h"
#import "LookinCoreTypes.h"
#import "LookinRuntimeShim.h"
#import "NSValue+Lookin.h"
