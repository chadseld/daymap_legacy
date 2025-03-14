//
//  CalendarHeaderView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/29/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarHeaderView.h"
#import "CalendarViewController.h"
#import "NSDate+WS.h"
#import "MiscUtils.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"

#define TOP_HEGIHT 117
#define DAY_RIBBON_HIGHT 22


@implementation CalendarHeaderView

static NSDictionary *__monthAttributes;
static NSDictionary *monthAttributes() {
    if (!__monthAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __monthAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSFont dayMapFontOfSize:24.0], NSFontAttributeName,
                                     [NSColor dayMapDarkTextColor],NSForegroundColorAttributeName,
                                     paragraphStyle, NSParagraphStyleAttributeName,
                                     nil];
    }
    return __monthAttributes;
}

static NSDictionary *__yearAttributes;
static NSDictionary *yearAttributes() {
    if (!__yearAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __yearAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont dayMapFontOfSize:24.0], NSFontAttributeName,
                              [NSColor dayMapDarkTextColor],NSForegroundColorAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName,
                              nil];
    }
    return __yearAttributes;
}

static NSDictionary *__weekAttributes;
static NSDictionary *weekAttributes() {
    if (!__weekAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __weekAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize]], NSFontAttributeName,
                             [NSColor dayMapDarkTextColor],NSForegroundColorAttributeName,
                             paragraphStyle, NSParagraphStyleAttributeName,
                             nil];
    }
    return __weekAttributes;
}

static NSDictionary *__dayAttributes;
static NSDictionary *dayAttributes() {
    if (!__dayAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __dayAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize]], NSFontAttributeName,
                             [NSColor dayMapLightTextColor], NSForegroundColorAttributeName,
                             paragraphStyle, NSParagraphStyleAttributeName,
                             nil];
    }
    return __dayAttributes;
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
//    static BOOL __alreadyCalled = NO;
//    assert(NO == __alreadyCalled);
//    __alreadyCalled = YES;
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKeyNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKeyNotification:) name:NSWindowDidResignKeyNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			__dayAttributes = nil;
			__weekAttributes = nil;
			__monthAttributes = nil;
			__yearAttributes = nil;
			[self setNeedsDisplay:YES];
			[self resizeSubviewsWithOldSize:self.bounds.size];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)windowDidBecomeKeyNotification:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

- (void)windowDidResignKeyNotification:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

- (BOOL)isOpaque
{
    return YES;
}

- (NSString *)postfixForDay:(NSInteger)day
{
//    1st
//    2nd
//    3rd
//    4th 
//    
//    10th
//    11th
//    12th
//    13th
//    
//    21st
//    22nd
//    23rd
//    24th
    
    NSString *postfix = @"th";
    if (day >= 10 && day <= 20) { // special case for teens
        // do nothing, default is @"th"
    }
    else if (day % 10 == 1) {
        postfix = @"st";
    }
    else if (day % 10 == 2) {
        postfix = @"nd";
    }
    else if (day % 10 == 3) {
        postfix = @"rd";
    }
    
    return postfix;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (DMCalendarViewByMonth == self.viewController.calendarViewByMode) {
		[self drawForMonthLayout:dirtyRect];
	}
	else {
		[self drawForWeekLayout:dirtyRect];
	}
}

- (void)drawForMonthLayout:(NSRect)dirtyRect {
	// Background
    [[NSColor dayMapCalendarBackgroundColor] set];
    NSRectFill(dirtyRect);
	
    NSRect topRect = NSMakeRect(0, (self.bounds.size.height - TOP_HEGIHT) + DAY_RIBBON_HIGHT, self.bounds.size.width, TOP_HEGIHT);
    NSRect calendarRect = NSMakeRect(0, 0, self.bounds.size.width, (self.bounds.size.height - TOP_HEGIHT) + DAY_RIBBON_HIGHT);
    
    // Header section
    if (NSIntersectsRect(dirtyRect, topRect)) {
		NSDate *date = self.viewController.week;
		
        // Month
        static NSDateFormatter *monthFormatter;
        if (!monthFormatter) {
            monthFormatter = [[NSDateFormatter alloc] init];
            [monthFormatter setDateFormat:@"MMMM "];
			monthFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        }
		NSString *monthString = [monthFormatter stringFromDate:date] ? : @"";
        NSAttributedString *monthAString = [[NSAttributedString alloc] initWithString:monthString attributes:monthAttributes()];
		
        // Year
        static NSDateFormatter *yearFormatter;
        if (!yearFormatter) {
            yearFormatter = [[NSDateFormatter alloc] init];
            [yearFormatter setDateFormat:@"yyyy "];
			yearFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        }
		NSString *yearString = [yearFormatter stringFromDate:date] ? : @"";
        NSAttributedString *yearAString = [[NSAttributedString alloc] initWithString:yearString attributes:yearAttributes()];
		
        // Draw it all
		NSMutableAttributedString *combined = [[NSMutableAttributedString alloc] init];
		[combined appendAttributedString:monthAString];
		//		[combined appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
		[combined appendAttributedString:yearAString];
		
		NSSize combinedSize = combined.size;
        NSRect dateRect = NSIntegralRect(NSMakeRect((self.bounds.size.width - combinedSize.width) / 2, self.bounds.size.height - combinedSize.height - 3, combinedSize.width, combinedSize.height));
		[combined drawInRect:dateRect];
    }
	
	// Calendar section
    if (NSIntersectsRect(dirtyRect, calendarRect)) {
		const CGFloat outerMargin = 0;
        
        // Calendar lines
        [[NSColor dayMapActionColor] set];
        NSRectFill(NSMakeRect(outerMargin, self.bounds.size.height - TOP_HEGIHT, self.bounds.size.width - 2 * outerMargin, DAY_RIBBON_HIGHT));
		
        for (int i=0; i<=7; i++) {
            CGFloat width = ((self.bounds.size.width - 2 * outerMargin) / 7.0);
            CGFloat textMargin = 6;
            
            // Day
            NSDate *day = [self.viewController.week dateByAddingDays:i];
			
            static NSDateFormatter *dayFormatter;
            if (!dayFormatter) {
                dayFormatter = [[NSDateFormatter alloc] init];
                [dayFormatter setDateFormat:@"EEEE"];
				dayFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            }
            static NSDateFormatter *shortDayFormatter;
            if (!shortDayFormatter) {
                shortDayFormatter = [[NSDateFormatter alloc] init];
                [shortDayFormatter setDateFormat:@"EEE"];
				shortDayFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            }
			
            NSString *dayString = [dayFormatter stringFromDate:day];
            
            // Shrink if needed
            NSSize dayStringSize = [dayString sizeWithAttributes:dayAttributes()];
            if (dayStringSize.width > width-2*textMargin) dayString = [shortDayFormatter stringFromDate:day];
			
            dayStringSize = [dayString sizeWithAttributes:dayAttributes()];
            
            // Draw day string
            NSRect destRect = NSMakeRect(width * i, self.bounds.size.height-TOP_HEGIHT, width, DAY_RIBBON_HIGHT);
            destRect = NSIntegralRect(NSInsetRect(destRect, textMargin, (DAY_RIBBON_HIGHT - dayStringSize.height) / 2));
            [dayString drawInRect:destRect withAttributes:dayAttributes()];
        }
	}
}

- (void)drawForWeekLayout:(NSRect)dirtyRect {
    // Background
    [[NSColor dayMapCalendarBackgroundColor] set];
    NSRectFill(dirtyRect);

    NSRect topRect = NSMakeRect(0, (self.bounds.size.height - TOP_HEGIHT) + DAY_RIBBON_HIGHT, self.bounds.size.width, TOP_HEGIHT);
    NSRect calendarRect = NSMakeRect(0, 0, self.bounds.size.width, (self.bounds.size.height - TOP_HEGIHT) + DAY_RIBBON_HIGHT);
    
    // Header section
    if (NSIntersectsRect(dirtyRect, topRect)) {
		
		NSDate *date = self.viewController.week;
		
        // Month
        static NSDateFormatter *monthFormatter;
        if (!monthFormatter) {
            monthFormatter = [[NSDateFormatter alloc] init];
            [monthFormatter setDateFormat:@"MMMM "];
			monthFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        }
		NSString *monthString = [monthFormatter stringFromDate:date] ? : @"";
        NSAttributedString *monthAString = [[NSAttributedString alloc] initWithString:monthString attributes:monthAttributes()];

        // Year
        static NSDateFormatter *yearFormatter;
        if (!yearFormatter) {
            yearFormatter = [[NSDateFormatter alloc] init];
            [yearFormatter setDateFormat:@"yyyy "];
			yearFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        }
		NSString *yearString = [yearFormatter stringFromDate:date] ? : @"";
        NSAttributedString *yearAString = [[NSAttributedString alloc] initWithString:yearString attributes:yearAttributes()];

        // Week
        static NSDateFormatter *weekFormatter;
        if (!weekFormatter) {
            weekFormatter = [[NSDateFormatter alloc] init];
            [weekFormatter setDateFormat:@"'Week 'w"];
			weekFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        }
		NSString *weekString = [weekFormatter stringFromDate:date] ? : @"";
        NSAttributedString *weekAString = [[NSAttributedString alloc] initWithString:weekString attributes:weekAttributes()];

        // Draw it all
		NSMutableAttributedString *combined = [[NSMutableAttributedString alloc] init];
		[combined appendAttributedString:monthAString];
//		[combined appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
		[combined appendAttributedString:yearAString];
		[combined appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
		[combined appendAttributedString:weekAString];
		
		NSSize combinedSize = combined.size;
        NSRect dateRect = NSIntegralRect(NSMakeRect((self.bounds.size.width - combinedSize.width) / 2, self.bounds.size.height - combinedSize.height - 3, combinedSize.width, combinedSize.height));
		[combined drawInRect:dateRect];
    }
    
    // Calendar section
    if (NSIntersectsRect(dirtyRect, calendarRect)) {
        
		const CGFloat outerMargin = 0;
        
        // Calendar lines
        [[NSColor dayMapActionColor] set];
        NSRectFill(NSMakeRect(outerMargin, self.bounds.size.height - TOP_HEGIHT, self.bounds.size.width - 2 * outerMargin, DAY_RIBBON_HIGHT));
        
        NSCalendar *cal = [NSCalendar currentCalendar];
		cal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		
        for (int i=0; i<=7; i++) {
            CGFloat width = ((self.bounds.size.width - 2 * outerMargin) / 7.0);
            CGFloat textMargin = 6;
            
            // Day
            NSDate *day = [self.viewController.week dateByAddingDays:i];
            NSDateComponents *components = [cal components:NSCalendarUnitDay fromDate:day];

            static NSDateFormatter *dayFormatter;
            if (!dayFormatter) {
                dayFormatter = [[NSDateFormatter alloc] init];
                [dayFormatter setDateFormat:@"EEEE', 'd"];
				dayFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            }
            static NSDateFormatter *shortDayFormatter;
            if (!shortDayFormatter) {
                shortDayFormatter = [[NSDateFormatter alloc] init];
                [shortDayFormatter setDateFormat:@"EEE', 'd"];
				shortDayFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            }

            NSString *dayString = [dayFormatter stringFromDate:day];
            NSString *postfix = [self postfixForDay:[components day]];
            
            // Shrink if needed
            NSSize dayStringSize = [[dayString stringByAppendingString:postfix] sizeWithAttributes:dayAttributes()];
            if (dayStringSize.width > width-2*textMargin) dayString = [shortDayFormatter stringFromDate:day];

			// Calculate geometry
			NSRect destRect = NSMakeRect(width * i, self.bounds.size.height-TOP_HEGIHT, width, DAY_RIBBON_HIGHT);
			destRect = NSIntegralRect(NSInsetRect(destRect, textMargin, (DAY_RIBBON_HIGHT - dayStringSize.height) / 2));

            dayString = [dayString stringByAppendingString:postfix];
            dayStringSize = [dayString sizeWithAttributes:dayAttributes()];
			
			// Highlight current day
			if ([[day dateQuantizedToDay] isEqualToDate:[NSDate today]]) {
				NSRect stringRect = NSIntegralRectWithOptions(NSInsetRect(destRect, ((destRect.size.width - dayStringSize.width) / 2) - (destRect.size.height / 2), 0), NSAlignAllEdgesOutward);
				if (self.window.isKeyWindow) {
					[[NSColor dayMapCurrentDayHighlightColor] set];
				}
				else {
					[[NSColor colorWithDeviceWhite:[[NSColor dayMapCurrentDayHighlightColor] saturationComponent] alpha:1.0] set];
				}
				[[NSBezierPath bezierPathWithRoundedRect:stringRect xRadius:stringRect.size.height / 2 yRadius:stringRect.size.height / 2] fill];
			}
			
            // Draw day string
            [dayString drawInRect:destRect withAttributes:dayAttributes()];
        
            // Draw portion of separator line
//            [[NSColor dayMapActionColor] set];
//            CGFloat x = floor(outerMargin + width * i)+0.5;
//            if (i == 7) x = self.bounds.size.width - outerMargin - 0.5;
//            CGFloat y = self.bounds.size.height - TOP_HEIGHT;
//            if (i == 7 || i == 0)  y = self.bounds.size.height - TOP_HEIGHT + DAY_RIBBON_HIGHT;
//            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
//                                      toPoint:NSMakePoint(x, 0)];
//			
//			// Draw shaded current day
//			if ([[day dateQuantizedToDay] isEqualToDate:[NSDate today]]) {
//				NSRect dayRect = NSMakeRect(floor(x)+1, 0, ceil(width)-1, self.bounds.size.height - TOP_HEIGHT);
//				[[NSColor dayMapCurrentDayBackgroundColor] set];
//				[NSBezierPath fillRect:dayRect];
//			}
        }
    }
}

- (void)setContentView:(NSView *)contentView {
	[_contentView removeFromSuperview];
	_contentView = contentView;
	if (_contentView) [self addSubview:_contentView];
	[self setNeedsDisplay:YES];
	[self resizeSubviewsWithOldSize:self.bounds.size];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	// Week selection view section
	CGFloat weekContainerMargin = 50;
	NSRect frame = self.dateSelectionContainerView.frame;
	frame.origin.y = NSMaxY(self.bounds) - 31 - frame.size.height;
	frame.size.width = MIN(750, self.bounds.size.width - weekContainerMargin*2);
	frame.origin.x = ceil((self.bounds.size.width - frame.size.width) / 2);
	frame = NSIntegralRect(frame);
	self.dateSelectionContainerView.frame = frame;
	[self.dateSelectionContainerView layoutSubtreeIfNeeded];
	
	// Content View
	frame = self.bounds;
	frame.size.height -= TOP_HEGIHT;
	self.contentView.frame = frame;
}

@end
