//
//  LeatherButton.m
//  DayMap
//
//  Created by Chad Seldomridge on 9/26/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "LeatherButton.h"

@implementation LeatherButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSDrawThreePartImage(frame, 
                         [NSImage imageNamed:@"buttonLightLeft"], 
                         [NSImage imageNamed:@"buttonLightMiddle"], 
                         [NSImage imageNamed:@"buttonLightRight"],
                         NO, NSCompositeSourceOver, 1.0, YES);
    
    if(self.isHighlighted) {
        NSDrawThreePartImage(frame, 
                             [NSImage imageNamed:@"buttonDarkLeft"], 
                             [NSImage imageNamed:@"buttonDarkMiddle"], 
                             [NSImage imageNamed:@"buttonDarkRight"], 
                             NO, NSCompositeSourceOver, 1.0, YES);
    }
}

@end

@implementation LeatherButton

+ (Class)cellClass
{
    return [LeatherButtonCell class];
}

- (void)awakeFromNib
{
    [self setTitle:self.title];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] 
                                            initWithAttributedString:[self attributedTitle]];
    NSInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName 
                      value:[NSColor colorWithDeviceRed:1.0 green:0.92 blue:0.84 alpha:1.0] 
                      range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedTitle:attrTitle];
}

@end
