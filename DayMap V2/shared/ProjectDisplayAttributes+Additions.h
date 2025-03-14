//
//  ProjectDisplayAttributes+Additions.h
//  DayMap
//
//  Created by Chad Seldomridge on 11/21/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectDisplayAttributes.h"

#if !TARGET_OS_IPHONE
#else
#define DEFAULT_PROJECT_COLOR [UIColor colorWithRed:0.51 green:0.21 blue:0 alpha:1]
#endif

@interface ProjectDisplayAttributes (Additions)

#if !TARGET_OS_IPHONE
- (NSColor *)nativeColor;
- (void)setNativeColor:(NSColor *)color;
#else
- (UIColor *)nativeColor;
- (void)setNativeColor:(UIColor *)color;
#endif

@end
