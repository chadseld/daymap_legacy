//
//  SearchController.h
//  DayMap
//
//  Created by Chad Seldomridge on 1/3/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *searchResultsTableView;
@property (nonatomic, strong) NSString *searchString;

- (IBAction)tableViewAction:(id)sender;

@end
