//
//  WSAbstractTaskTableViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/12/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AbstractTask.h"

@class DayMapManagedObjectContext;

@interface WSAbstractTaskTableViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *sortedTasks;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) AbstractTask *editingTask;

- (void)pushDetailViewForAbstractTask:(AbstractTask *)task;
- (void)editTitleOfTask:(AbstractTask *)task;

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification;
- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification;

- (NSManagedObject *)objectToObserve;
- (NSArray *)keyPathsToObserve;

@end
