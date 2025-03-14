//
//  ProjectTableHeaderCell.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/31/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Project.h"

@interface ProjectTableHeaderCell : NSTableHeaderCell <NSMenuDelegate>

@property (nonatomic, strong) NSString *titleString;
@property (nonatomic) BOOL archived;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic) BOOL minimized;

- (BOOL)trackMouse:(NSEvent *)theEvent inMinimizeButtonForCellFrame:(NSRect)cellFrame ofView:(NSView *)controlView;
- (BOOL)trackMouse:(NSEvent *)theEvent inMenuButtonForCellFrame:(NSRect)cellFrame ofView:(NSView *)controlView;

- (NSRect)menuButtonFrameForCellFrame:(NSRect)cellFrame;

@end
