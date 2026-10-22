// Umbrella header of the LookinCore module.
//
// Only C declarations live here: the macros and port ranges, the exported
// attribute identifier constants, the archived enums, the NSStringFrom*
// prototypes the Swift `@_cdecl` functions export, and the runtime shim
// (NSException catching, NSInvocation, @encode, ptrauth_strip). The model
// classes and categories are plain Swift in LookinCoreImpl, declared with
// `@objc(OriginalName)` and their original selectors, so archived class
// names and Objective-C callers are unchanged.
//
// SwiftPM does not pass a target's C defines to Swift's Clang importer, so the
// guard the headers are wrapped in is defined here first.

#ifndef SHOULD_COMPILE_LOOKIN_SERVER
#define SHOULD_COMPILE_LOOKIN_SERVER 1
#endif

#import "LookinAttrIdentifiers.h"
#import "LookinAttrType.h"
#import "LookinCodingValueType.h"
#import "LookinCoreTypes.h"
#import "LookinDefines.h"
#import "LookinHitTargetSize.h"
#import "LookinRuntimeShim.h"
#import "NSValue+Lookin.h"
