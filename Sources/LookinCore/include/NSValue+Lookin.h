#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  NSValue+Lookin.h
//  LookinServer
//
//  Created by JH on 2024/11/5.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

// Exported by the `@_cdecl` functions in LookinCoreImpl/Category/NSValue+Lookin.swift.
// The NSValue (Lookin) category itself is a Swift extension with the
// original selectors.

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_OSX
NSString *NSStringFromInsets(NSEdgeInsets insets);
NSString *NSStringFromCGAffineTransform(CGAffineTransform transform);
NSString *NSStringFromCGVector(CGVector vector);
NSString *NSStringFromCGRect(CGRect rect);
NSString *NSStringFromCGPoint(CGPoint point);
NSString *NSStringFromCGSize(CGSize size);
NSString *NSStringFromDirectionalEdgeInsets(NSDirectionalEdgeInsets insets);
#else
NSString *NSStringFromInsets(UIEdgeInsets insets);
#endif


NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
