//
//  ProjectTableHeaderView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/2/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProjectTableHeaderView : NSTableHeaderView

@end


@protocol DMProjectTableViewDelegate <NSObject>

- (void)tableView:(NSTableView *)tableView didToggleMinimizeForTableColumn:(NSTableColumn *)column;
- (void)tableView:(NSTableView *)tableView didClickHeaderMenuButtonForTableColumn:(NSTableColumn *)column;

@end