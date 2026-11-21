// Umbrella header of the LookinCore module.
//
// What is left in C is what Swift cannot express: the runtime shim
// (NSException catching, NSInvocation, @encode, ptrauth_strip) and the
// prototypes of the NSStringFrom* functions LookinCoreImpl exports with
// `@_cdecl`. Everything else the Host and the Server share is Swift in
// LookinCoreImpl: the attribute identifiers (LookinAttrIdentifiers.swift), the
// enums (LookinCoreTypes.swift), the versions, ports, request numbers,
// parameter keys and error codes (LookinDefines.swift), and the model classes
// and categories, declared with `@objc(OriginalName)` and their original
// selectors, so archived class names and Objective-C callers are unchanged.
//
// SwiftPM does not pass a target's C defines to Swift's Clang importer, so the
// guard the headers are wrapped in is defined here first.

#ifndef SHOULD_COMPILE_LOOKIN_SERVER
#define SHOULD_COMPILE_LOOKIN_SERVER 1
#endif

#import <Foundation/Foundation.h>
#import "LookinRuntimeShim.h"
#import "NSValue+Lookin.h"
