//
//  LookinObject+LookinClient.m
//  LookinClient
//
//  Created by likai.123 on 2024/1/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "LookinObject+LookinClient.h"
#import "LookInside-Swift.h"

@implementation LookinObject (LookinClient)

- (NSString *)lk_completedDemangledClassName {
    return [LKSwiftDemangler completedParseWithInput:self.rawClassName];
}

- (NSString *)lk_simpleDemangledClassName {
    NSString *name = [LKSwiftDemangler simpleParseWithInput:self.rawClassName];
    // 去掉模块前缀（例如 "AppKit._NSCoreHostingView<AppKit.ThemeWidgetView>" 中的 "AppKit."），
    // 但只考虑泛型 '<' 括号之前的点号，避免误拆泛型类型参数内部的点号。
    NSUInteger angleBracketIndex = [name rangeOfString:@"<"].location;
    NSString *prefixPortion = (angleBracketIndex != NSNotFound) ? [name substringToIndex:angleBracketIndex] : name;
    NSRange lastDotRange = [prefixPortion rangeOfString:@"." options:NSBackwardsSearch];
    if (lastDotRange.location != NSNotFound) {
        return [name substringFromIndex:lastDotRange.location + 1];
    }
    return name;
}

@end
