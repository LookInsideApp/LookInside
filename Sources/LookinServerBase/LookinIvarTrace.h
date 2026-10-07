// `__swift__`: Swift targets import this header through the LookinServerBase
// Clang module, which SwiftPM builds for them without the C define, so the
// declaration must not depend on it there.
#if defined(SHOULD_COMPILE_LOOKIN_SERVER) || defined(__swift__)

//
//  LookinIvarTrace.h
//  Lookin
//
//  Created by Li Kai on 2019/4/30.
//  https://lookin.work
//
//  The LookinIvarTrace class is plain Swift (LookinCoreImpl/LookinIvarTrace.swift,
//  `@objc(LookinIvarTrace)`); `-[NSObject lks_ivarTraces]` is a Swift `@objc`
//  extension member in LookinServerImpl. Only the exported C constant stays
//  here (defined in LookinIvarTraceConstants.m).
//

#import <Foundation/Foundation.h>

extern NSString *const LookinIvarTraceRelationValue_Self;

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
