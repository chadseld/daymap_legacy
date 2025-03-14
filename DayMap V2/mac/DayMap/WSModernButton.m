//
//  WSModernButton.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/31/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WSModernButton.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"

@implementation WSModernButtonCell

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			[self setTitle:self.title];
			[[self controlView] setNeedsDisplay:YES];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSRect trackRect = NSInsetRect(NSIntegralRect(frame), 2.5, 2.5);
	NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
	[track setLineWidth:1];
	
	if (self.isHighlighted) {
		NSColor *highlightedColor = [NSColor dayMapActionColor];
		[highlightedColor set];
		[self setTextColor:highlightedColor];
	}
	else {
		if ([controlView.window isKeyWindow]) {
			[[NSColor dayMapDarkActionColor] set];
			[self setTextColor:[NSColor dayMapDarkTextColor]];
		}
		else {
			[[[NSColor dayMapDarkActionColor] disabledColor] set];
			[self setTextColor:[[NSColor dayMapDarkTextColor] disabledColor]];
		}		
	}
	
	[track stroke];
}

- (void)updateAttributedTitle {
	NSMutableAttributedString *titleAttributes = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
	NSRange range = NSMakeRange(0, [titleAttributes length]);
	
	NSMutableParagraphStyle *pararagraphStyle = [[NSMutableParagraphStyle alloc] init];
	pararagraphStyle.alignment = self.alignment;
	[titleAttributes addAttribute:NSParagraphStyleAttributeName value:pararagraphStyle range:range];
	
	if (_textColor) {
		[titleAttributes addAttribute:NSForegroundColorAttributeName value:_textColor range:range];
	}
	
	[titleAttributes addAttribute:NSFontAttributeName value:[NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize] + _fontSizeAdjustment] range:range];
	
	[titleAttributes fixAttributesInRange:range];
	[self setAttributedTitle:titleAttributes];
}

- (void)setTextColor:(NSColor *)textColor {
	_textColor = textColor;
	[self updateAttributedTitle];
}

- (void)setTitle:(NSString *)title {
	[super setTitle:title];
	[self updateAttributedTitle];
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	return [super drawTitle:title withFrame:NSOffsetRect(frame, 0, _fontSizeAdjustment > 0 ? 0 : -1) inView:controlView];
}

- (void)setFontSizeAdjustment:(NSInteger)adjustment {
	_fontSizeAdjustment = adjustment;
	[self updateAttributedTitle];
}

@end

@implementation WSModernButton

+ (Class)cellClass
{
    return [WSModernButtonCell class];
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self _init];
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self _init];
	}
	return self;
}

- (void)_init {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKey:) name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKey:) name:NSWindowDidResignKeyNotification object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidChangeKey:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

@end
