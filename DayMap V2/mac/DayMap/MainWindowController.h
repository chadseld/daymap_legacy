//
//  MainWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/11/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalendarViewController.h"
#import "ProjectsViewController.h"
#import "SearchController.h"
#import "DayMapManagedObjectContext.h"

@interface MainWindowController : NSWindowController <NSSharingServicePickerDelegate, NSSharingServiceDelegate>

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *splitTopView;
@property (weak) IBOutlet NSView *splitBottomView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *shareButton;

@property (readonly) CalendarViewController *calendarViewController;
@property (weak) IBOutlet SearchController *searchController;

- (IBAction)addProject:(id)sender;
- (IBAction)addTask:(id)sender;
- (IBAction)completedSliderChanged:(id)sender;
- (IBAction)searchFieldChanged:(id)sender;
- (IBAction)selectSearchField:(id)sender;
- (IBAction)shareButtonClicked:(id)sender;

- (IBAction)showWeek:(id)sender;
- (IBAction)showMonth:(id)sender;
- (IBAction)showHideCalendar:(id)sender;
- (IBAction)goToToday:(id)sender;

- (IBAction)upgradeToFullVersion:(id)sender;

@end
