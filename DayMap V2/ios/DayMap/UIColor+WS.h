//
//  UIColor+WS.h
//  DayMap
//
//  Created by Jonathan Huggins on 8/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor (UIColor_WS)

- (UIColor *)lighterColor:(CGFloat)amount;
- (UIColor *)darkerColor:(CGFloat)amount;

+ (UIColor *)dayMapActionColor;
+ (UIColor *)dayMapDarkActionColor;
+ (UIColor *)dayMapDividerColor;
+ (UIColor *)dayMapBackgroundColor;
+ (UIColor *)dayMapDarkTextColor;
+ (UIColor *)dayMapLightTextColor;

+ (UIColor *)dayMapSelectedTaskBackgroundColor;
+ (UIColor *)dayMapCurrentDayBackgroundColor;

+ (UIColor *)dayMapInboxBackgroundColor;

+ (UIColor *)randomProjectColor;

@end
