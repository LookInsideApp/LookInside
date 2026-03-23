//
//  main.m
//  Lookin
//
//  Created by Li Kai on 2018/12/21.
//  https://lookin.work
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return EXIT_SUCCESS;
}
