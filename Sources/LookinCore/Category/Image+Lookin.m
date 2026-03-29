#ifdef SHOULD_COMPILE_LOOKIN_SERVER 

//
//  Image+Lookin.m
//  LookinShared
//
//  Created by 李凯 on 2022/4/2.
//

#import "Image+Lookin.h"

#if TARGET_OS_IPHONE

#elif TARGET_OS_OSX

@implementation NSImage (LookinClient)

- (NSData *)lookin_data {
    if (self.representations.count == 0) {
        return nil;
    }
    // 优先尝试直接使用 bitmap representations（适用于光栅图像）。
    NSData *data = [NSBitmapImageRep representationOfImageRepsInArray:self.representations usingType:NSBitmapImageFileTypePNG properties:@{}];
    if (data) {
        return data;
    }
    // 兜底方案：渲染到 bitmap context（处理矢量图、SF Symbols 等）。
    CGRect proposedRect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGImageRef cgImage = [self CGImageForProposedRect:&proposedRect context:nil hints:nil];
    if (!cgImage) {
        return nil;
    }
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    return [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
