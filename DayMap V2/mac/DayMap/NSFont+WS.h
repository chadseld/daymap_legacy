//
//  NSFont+WS.h
//  DayMap
//
//  Created by Chad Seldomridge on 8/19/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFont (NSFont_WS)

+ (NSFont *)dayMapFontOfSize:(CGFloat)size;
+ (NSFont *)dayMapLightFontOfSize:(CGFloat)size;
+ (NSFont *)dayMapListFontOfSize:(CGFloat)size;
+ (NSFont *)boldDayMapFontOfSize:(CGFloat)size;

+ (CGFloat)dayMapBaseFontSize;
+ (CGFloat)dayMapListFontSize;
+ (CGFloat)dayMapSmallListFontSize;

@end
