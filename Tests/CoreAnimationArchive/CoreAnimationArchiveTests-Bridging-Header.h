//
//  CoreAnimationArchiveTests-Bridging-Header.h
//
//  The C side of LookinCore the Core Animation archive tests compile
//  against: `LookinCatchException` for the decoder, and the model the
//  converter builds into.
//

// Only the C declarations: the LookinCoreImpl Swift files compiled into the
// converter test binary declare the model classes themselves
// (`@objc(OriginalName)`).
#import "LookinDefines.h"
#import "LookinAttrIdentifiers.h"
#import "LookinAttrType.h"
#import "LookinCodingValueType.h"
#import "LookinCoreTypes.h"
#import "LookinRuntimeShim.h"
#import "NSValue+Lookin.h"
#import "LookInsideServerLogger.h"
#import "LookinIvarTrace.h"
