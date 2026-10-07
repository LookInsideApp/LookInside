// Umbrella header of the LookinServerBase module.
//
// SwiftPM does not pass a target's C defines to Swift's Clang importer, so the
// guard LookinIvarTrace.h is wrapped in is defined here first; without it a
// Swift target that imports LookinServerBase without C settings of its own
// (LookinCoreImpl, which implements LookinIvarTrace) sees an empty module.

#ifndef SHOULD_COMPILE_LOOKIN_SERVER
#define SHOULD_COMPILE_LOOKIN_SERVER 1
#endif

#import "LookinIvarTrace.h"
#import "LookInsideServerLogger.h"
