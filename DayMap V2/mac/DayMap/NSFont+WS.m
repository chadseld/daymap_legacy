//
//  NSFont+WS.m
//  DayMap
//
//  Created by Chad Seldomridge on 8/19/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "NSFont+WS.h"

@implementation NSFont (NSFont_WS)

+ (NSFont *)dayMapFontOfSize:(CGFloat)size {
	if (size <= [self dayMapBaseFontSize] && [[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return [self boldDayMapFontOfSize:size];
	}
	return [NSFont systemFontOfSize:size];
}

+ (NSFont *)dayMapLightFontOfSize:(CGFloat)size {
	if (size <= [self dayMapBaseFontSize] && [[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return [self systemFontOfSize:size];
	}
	return [NSFont fontWithName:@"Helvetica-Light" size:size];

}

+ (NSFont *)dayMapListFontOfSize:(CGFloat)size {
	return [NSFont systemFontOfSize:size];
}

+ (NSFont *)boldDayMapFontOfSize:(CGFloat)size {
	return [NSFont boldSystemFontOfSize:size];
}

+ (CGFloat)dayMapBaseFontSize {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return 13.0;
	}
	else {
		return 13.0;
	}
}

+ (CGFloat)dayMapListFontSize {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return [self dayMapBaseFontSize] + 2;
	}
	else {
		return [self dayMapBaseFontSize];
	}
}

+ (CGFloat)dayMapSmallListFontSize {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return [self dayMapBaseFontSize] + 1;
	}
	else {
		return [self dayMapBaseFontSize] - 0.5;
	}
}

@end
