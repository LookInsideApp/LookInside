//
// LKServerVersionRequestor.m
// LookinClient
//
// Created by likai.123 on 2023/10/30.
// Copyright © 2023 hughkli. All rights reserved.
//

#import "LKServerVersionRequestor.h"

@implementation LKServerVersionRequestor

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static LKServerVersionRequestor *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self shared];
}

- (void)preload {
    // The upstream version endpoint is no longer available for this community build.
}

- (void)handleReceiveVersion:(NSString *)version {
    NSLog(@"Receive version: %@", version);
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"LKServerVersionRequestor_version"];
    [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:@"LKServerVersionRequestor_time"];
}

- (NSString *)query {
    return nil;
}

@end
