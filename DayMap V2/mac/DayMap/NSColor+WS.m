//
//  NSColor+WS.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/9/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "NSColor+WS.h"

@implementation NSColor (NSColor_WS)

BOOL isDarkAquaEnabled() {
	if (@available(macOS 10.14, *)) {
		return [[NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqualToString:NSAppearanceNameDarkAqua];

	}
	return false;
}

- (NSColor *)disabledColor {
	NSColor *rgbColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	if (rgbColor.colorSpace.numberOfColorComponents > 1) {
		return [rgbColor desaturateColor:0.25];
		//return [NSColor colorWithDeviceWhite:[self brightnessComponent] alpha:1.0];
//		return [NSColor secondarySelectedControlColor];
	}
	else {
		return [rgbColor lighterColor:0.25];
	}
}

- (NSColor *)lighterColor:(CGFloat)amount
{
    CGFloat hue, saturation, brightness, alpha;
	[[self colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
	
	NSColor *lighterColor = [NSColor colorWithDeviceHue:hue
											 saturation:saturation brightness:MIN(1.0, brightness+amount) alpha:alpha];
    return lighterColor;
}

- (NSColor *)darkerColor:(CGFloat)amount
{
    CGFloat hue, saturation, brightness, alpha;
	[[self colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

	NSColor *darkerColor = [NSColor colorWithDeviceHue:hue
											saturation:saturation brightness:MAX(0.0, brightness-amount) alpha:alpha];
    return darkerColor;
}

- (NSColor *)desaturateColor:(CGFloat)amount
{
    CGFloat hue, saturation, brightness, alpha;
	[[self colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
	
	NSColor *lighterColor = [NSColor colorWithDeviceHue:hue
											 saturation:MAX(0.0, saturation-amount)
											 brightness:brightness
												  alpha:alpha];
    return lighterColor;
}



#if MAC_OS_X_VERSION_MAX_ALLOWED < 1080
- (CGColorRef)CGColor
{
	NSColor *colorRGB = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat components[4];
	[colorRGB getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	CGColorSpaceRef theColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGColorRef theColor = CGColorCreate(theColorSpace, components);
	CGColorSpaceRelease(theColorSpace);
	//return (__bridge_retained CGColorRef)(__bridge_transfer id)theColor;
	return theColor;
}

+ (NSColor *)colorWithCGColor:(CGColorRef)aColor
{
	const CGFloat *components = CGColorGetComponents(aColor);
	CGFloat red = components[0];
	CGFloat green = components[1];
	CGFloat blue = components[2];
	CGFloat alpha = components[3];
	return [self colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}
#endif

+ (NSColor *)dayMapActionColor {
	return [NSColor colorWithDeviceRed:0.03 green:0.57 blue:0.73 alpha:1.0];
}

+ (NSColor *)dayMapDarkActionColor {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceWhite:0.35 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.25 alpha:1.0];
	}
}

+ (NSColor *)dayMapDividerColor {
//	return [NSColor colorWithDeviceWhite:0.25 alpha:1.0];
	return [self dayMapActionColor];
}

+ (NSColor *)dayMapBackgroundColor {
	if (isDarkAquaEnabled()) {
		return [NSColor windowBackgroundColor];
	}
	else {
		return [NSColor whiteColor];
	}
}

+ (NSColor *)dayMapCalendarBackgroundColor {
	if (isDarkAquaEnabled()) {
		return [NSColor underPageBackgroundColor];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.97 alpha:1];
	}
}

+ (NSColor *)dayMapEKEventsCalendarBackgroundColor {
	if (isDarkAquaEnabled()) {
		return [NSColor controlBackgroundColor];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.92 alpha:1];
	}
}

+ (NSColor *)dayMapDarkTextColor {
	return [NSColor labelColor];
}

+ (NSColor *)dayMapLightTextColor {
	return [NSColor colorWithDeviceWhite:0.98 alpha:1.0];
}

+ (NSColor *)dayMapTaskTextColor {
	return [NSColor labelColor];
}

+ (NSColor *)dayMapCompletedTaskTextColor {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
		return [NSColor dayMapDarkTextColor];
	}
	else {
		return [NSColor secondaryLabelColor];
	}
}

+ (NSColor *)dayMapCurrentDayHighlightColor {
	return [NSColor colorWithCalibratedRed:0.95 green:0.2 blue:0.2 alpha:1.0];
}

+ (NSColor *)dayMapInboxBackgroundColor {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceHue:0.5472
								saturation:0.17
								brightness:0.3
									 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceRed:0.82 green:0.91 blue:0.95 alpha:1.0];
	}
}

+ (NSColor *)dayMapInboxBackgroundColorInactive {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceHue:0.5472
								saturation:0.14
								brightness:0.25
									 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.96 alpha:1.0];
	}
}

+ (NSColor *)dayMapProjectsHeaderDividerColor {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceWhite:0.35 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.35 alpha:1];
	}
}

+ (NSColor *)dayMapProjectsDividerColor {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceWhite:0.35 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.65 alpha:1];
	}
}

+ (NSColor *)dayMapCalendarDividerColor {
	if (isDarkAquaEnabled()) {
		return [NSColor colorWithDeviceWhite:0.35 alpha:1];
	}
	else {
		return [NSColor colorWithDeviceWhite:0.73 alpha:1];
	}
}

+ (NSColor *)randomProjectColor {
	CGFloat hue = [[[NSUserDefaults standardUserDefaults] valueForKey:PREF_RAND_PROJECT_COLOR] doubleValue];
	NSColor *color = [NSColor colorWithDeviceHue:hue saturation:0.80 brightness:0.93 alpha:1.0];
	hue = hue + 0.18;
	if (hue > 1) {
		hue = hue - 1;
	}
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:hue] forKey:PREF_RAND_PROJECT_COLOR];
	return color;
}

@end
