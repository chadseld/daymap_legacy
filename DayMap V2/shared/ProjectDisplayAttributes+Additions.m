//
//  ProjectDisplayAttributes+Additions.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/21/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectDisplayAttributes+Additions.h"

@implementation ProjectDisplayAttributes (Additions)


#if !TARGET_OS_IPHONE

- (NSColor *)nativeColor {
	NSData *colorData = [self valueForKey:@"color"];
	if (!colorData) {
		return nil;
	}
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:colorData];

	if (![unarchiver containsValueForKey:@"v4"]) {
		@try {
			// Try reading old color data format
			NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
			if (color) {
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					[self setNativeColor:color]; // update data format
				});
			}
			return color;
		}
		@catch (NSException *exception) {
			NSLog(@"Exception converting native color: %@", exception);
		}
	}
	
	return [NSColor colorWithDeviceRed:[unarchiver decodeDoubleForKey:@"R"] green:[unarchiver decodeDoubleForKey:@"G"] blue:[unarchiver decodeDoubleForKey:@"B"] alpha:[unarchiver decodeDoubleForKey:@"A"]];
}

- (void)setNativeColor:(NSColor *)color {
	CGFloat red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	NSMutableData *data = [NSMutableData dataWithCapacity:192];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeDouble:red forKey:@"R"];
	[archiver encodeDouble:green forKey:@"G"];
	[archiver encodeDouble:blue forKey:@"B"];
	[archiver encodeDouble:alpha forKey:@"A"];
	[archiver encodeBool:YES forKey:@"v4"];
	[archiver finishEncoding];
	
	[self setValue:data forKey:@"color"];
}

#else

- (UIColor *)nativeColor {
	NSData *colorData = [self valueForKey:@"color"];
	if (!colorData) {
		return nil;
	}
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:colorData];
	
	if (![unarchiver containsValueForKey:@"v4"]) {
		return nil;
	}
	
	return [UIColor colorWithRed:[unarchiver decodeDoubleForKey:@"R"] green:[unarchiver decodeDoubleForKey:@"G"] blue:[unarchiver decodeDoubleForKey:@"B"] alpha:[unarchiver decodeDoubleForKey:@"A"]];
}

- (void)setNativeColor:(UIColor *)color {
	CGFloat red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	
	NSMutableData *data = [NSMutableData dataWithCapacity:192];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeDouble:red forKey:@"R"];
	[archiver encodeDouble:green forKey:@"G"];
	[archiver encodeDouble:blue forKey:@"B"];
	[archiver encodeDouble:alpha forKey:@"A"];
	[archiver encodeBool:YES forKey:@"v4"];
	[archiver finishEncoding];
	
	[self setValue:data forKey:@"color"];
}

#endif

@end
