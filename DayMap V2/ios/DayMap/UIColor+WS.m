//
//  UIColor+WS.m
//  DayMap
//
//  Created by Jonathan Huggins on 8/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "UIColor+WS.h"

@implementation UIColor (UIColor_WS)
- (UIColor *)lighterColor:(CGFloat)amount
{
    CGFloat hue, saturation, brightness, alpha;
	[self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
	
	UIColor *lighterColor = [UIColor colorWithHue:hue
											 saturation:saturation brightness:MIN(1.0, brightness+amount) alpha:alpha];
    return lighterColor;
}

- (UIColor *)darkerColor:(CGFloat)amount
{
    CGFloat hue, saturation, brightness, alpha;
	[self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
	UIColor *darkerColor = [UIColor colorWithHue:hue
											saturation:saturation brightness:MAX(0.0, brightness-amount) alpha:alpha];
    return darkerColor;
}

+ (UIColor *)dayMapActionColor {
	return [UIColor colorWithRed:0.03 green:0.57 blue:0.73 alpha:1.0];
}

+ (UIColor *)dayMapDarkActionColor {
	return [UIColor colorWithWhite:0.25 alpha:1.0];
}

+ (UIColor *)dayMapDividerColor {
	return [self dayMapActionColor];
}

+ (UIColor *)dayMapBackgroundColor {
	return [UIColor whiteColor];
}

+ (UIColor *)dayMapDarkTextColor {
    return [UIColor colorWithWhite:0.25 alpha:1.0];
}

+ (UIColor *)dayMapLightTextColor {
	return [UIColor colorWithWhite:0.98 alpha:1.0];
}

+ (UIColor *)dayMapSelectedTaskBackgroundColor {
	return [UIColor colorWithRed:0.03 green:0.57 blue:0.73 alpha:0.2];
    //	return [UIColor selectedTextBackgroundColor];
}

+ (UIColor *)dayMapCurrentDayBackgroundColor {
	return [UIColor colorWithWhite:0.96 alpha:1.0];
}

+ (UIColor *)dayMapInboxBackgroundColor {
	return [UIColor colorWithRed:0.82 green:0.91 blue:0.95 alpha:1.0];
}

+ (UIColor *)randomProjectColor {
	CGFloat hue = [[[NSUserDefaults standardUserDefaults] valueForKey:PREF_RAND_PROJECT_COLOR] doubleValue];
	UIColor *color = [UIColor colorWithHue:hue saturation:0.80 brightness:0.93 alpha:1.0];
	hue = hue + 0.18;
	if (hue > 1) {
		hue = hue - 1;
	}
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:hue] forKey:PREF_RAND_PROJECT_COLOR];
	return color;
}

@end
