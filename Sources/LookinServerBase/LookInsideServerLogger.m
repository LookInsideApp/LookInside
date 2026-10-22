#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookInsideServerLogger.m
//  LookinServerBase
//
//  The exported C constant only: Swift cannot define a C global. The
//  LookInsideServerLogger class is implemented in Swift
//  (LookinCoreImpl/LookInsideServerLogger.swift).
//

#import "LookInsideServerLogger.h"

NSString *const LookInsideServerLogLevelEnvironmentKey = @"LOOKINSIDE_SERVER_LOG_LEVEL";

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
