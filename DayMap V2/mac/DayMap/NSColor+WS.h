//
//  NSColor+WS.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/9/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSColor (NSColor_WS)

- (NSColor *)disabledColor;
- (NSColor *)lighterColor:(CGFloat)amount;
- (NSColor *)darkerColor:(CGFloat)amount;
- (NSColor *)desaturateColor:(CGFloat)amount;

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1080
- (CGColorRef)CGColor;
+ (NSColor *)colorWithCGColor:(CGColorRef)aColor;
#endif

+ (NSColor *)dayMapActionColor;
+ (NSColor *)dayMapDarkActionColor;

+ (NSColor *)dayMapDividerColor;
+ (NSColor *)dayMapProjectsHeaderDividerColor;
+ (NSColor *)dayMapProjectsDividerColor;
+ (NSColor *)dayMapCalendarDividerColor;

+ (NSColor *)dayMapBackgroundColor;
+ (NSColor *)dayMapCalendarBackgroundColor;
+ (NSColor *)dayMapEKEventsCalendarBackgroundColor;
+ (NSColor *)dayMapDarkTextColor;
+ (NSColor *)dayMapLightTextColor;

+ (NSColor *)dayMapTaskTextColor;
+ (NSColor *)dayMapCompletedTaskTextColor;

+ (NSColor *)dayMapCurrentDayHighlightColor;

+ (NSColor *)dayMapInboxBackgroundColor;
+ (NSColor *)dayMapInboxBackgroundColorInactive;

+ (NSColor *)randomProjectColor;

@end
