//
//  SearchResultTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 1/3/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SearchResultTableCellView : NSTableCellView <NSPopoverDelegate>

@property (strong) IBOutlet NSTextField *contextLabel;
@property (strong) NSColor *projectColor;
@property (strong) NSString *type;
@property (strong) NSString *uuid;

- (void)showPopover;

@end
