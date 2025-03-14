//
//  WSModernButton.h
//  DayMap
//
//  Created by Chad Seldomridge on 1/31/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface WSModernButtonCell : NSButtonCell

@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic) NSInteger fontSizeAdjustment;

@end

@interface WSModernButton : NSButton

@end
