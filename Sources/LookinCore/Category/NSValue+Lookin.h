#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  NSValue+Lookin.h
//  LookinServer
//
//  Created by JH on 2024/11/5.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import "LookinDefines.h"

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

@interface NSValue (Lookin)
#if TARGET_OS_OSX
+ (NSValue *)valueWithCGVector:(CGVector)vector;
+ (NSValue *)valueWithCGRect:(CGRect)rect;
+ (NSValue *)valueWithCGPoint:(CGPoint)point;
+ (NSValue *)valueWithCGSize:(CGSize)size;
+ (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform;
- (CGAffineTransform)CGAffineTransformValue;
- (CGVector)CGVectorValue;
- (CGRect)CGRectValue;
- (CGPoint)CGPointValue;
- (CGSize)CGSizeValue;
+ (NSValue *)valueWithInsets:(NSEdgeInsets)insets;
- (NSEdgeInsets)InsetsValue;
#else
+ (NSValue *)valueWithInsets:(UIEdgeInsets)insets;
- (UIEdgeInsets)InsetsValue;
#endif
@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
