//
//  RACDisposable.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/16/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACDisposable.h"
#import "RACScopedDisposable.h"
#import <stdatomic.h>

@interface RACDisposable () {
	// A copied block of type void (^)(void) containing the logic for disposal,
	// a pointer to `self` if no logic should be performed upon disposal, or
	// NULL if the receiver is already disposed.
	//
	// This should only be used atomically.
	_Atomic(void *) _disposeBlock;
}

@end

@implementation RACDisposable

#pragma mark Properties

- (BOOL)isDisposed {
	return atomic_load_explicit(&_disposeBlock, memory_order_acquire) == NULL;
}

#pragma mark Lifecycle

- (instancetype)init {
	self = [super init];

	atomic_store_explicit(&_disposeBlock, (__bridge void *)self, memory_order_release);

	return self;
}

- (instancetype)initWithBlock:(void (^)(void))block {
	NSCParameterAssert(block != nil);

	self = [super init];

	atomic_store_explicit(&_disposeBlock, (void *)CFBridgingRetain([block copy]), memory_order_release);

	return self;
}

+ (instancetype)disposableWithBlock:(void (^)(void))block {
	return [[self alloc] initWithBlock:block];
}

- (void)dealloc {
	void *disposeBlockPtr = atomic_exchange_explicit(&_disposeBlock, NULL, memory_order_acq_rel);
	if (disposeBlockPtr == NULL || disposeBlockPtr == (__bridge void *)self) return;

	CFRelease(disposeBlockPtr);
}

#pragma mark Disposal

- (void)dispose {
	void (^disposeBlock)(void) = NULL;

	void *blockPtr = atomic_exchange_explicit(&_disposeBlock, NULL, memory_order_acq_rel);
	if (blockPtr != NULL && blockPtr != (__bridge void *)self) {
		disposeBlock = CFBridgingRelease(blockPtr);
	}

	if (disposeBlock != nil) disposeBlock();
}

#pragma mark Scoped Disposables

- (RACScopedDisposable *)asScopedDisposable {
	return [RACScopedDisposable scopedDisposableWithDisposable:self];
}

@end
