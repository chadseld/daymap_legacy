//
//  main.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/20/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "validatereceipt.h"
#import "VerifyStoreReceipt.h"

#ifndef GLOBAL_BUNDLE

#ifdef TARGET_DAYMAP_LITE
const NSString * global_bundleVersion = @"2.1.5";
const NSString * global_bundleIdentifier = @"com.whetstoneapps.daymap-lite";
#else
const NSString * global_bundleVersion = @"2.1.5";
const NSString * global_bundleIdentifier = @"com.whetstoneapps.daymap";
#endif

#endif
#define GLOBAL_BUNDLE 1

int main(int argc, char *argv[])
{
	@autoreleasepool {
		NSString * receiptPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
		if (!verifyReceiptAtPath(receiptPath)) {
			NSLog(@"Failed to validate receipt: %@", receiptPath);
			exit(173);
		}
    }
	
	return NSApplicationMain(argc, (const char **)argv);
}
