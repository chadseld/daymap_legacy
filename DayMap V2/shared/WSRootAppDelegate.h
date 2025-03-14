//
//  WSRootAppDelegate.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/24/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DayMapManagedObjectContext.h"
#import "DMEventKitBridge.h"

#if !TARGET_OS_IPHONE
@interface WSRootAppDelegate : NSObject <NSFilePresenter>
#else
#import <UIKit/UIKit.h>
@interface WSRootAppDelegate : UIResponder <NSFilePresenter>
#endif
{
}

@property (strong) NSSet *selectedTasks;
@property (strong) NSString *selectedProject; // uuid
@property (strong) DMEventKitBridge *eventKitBridge;

- (void)disableFilePresenter;
- (void)unloadPersistentStore;
- (void)tearDownCoreDataStack;

- (void)setupCoreDataStack;
- (void)enableFilePresenterForURL:(NSURL *)url;
- (void)loadPersistentStoreAtPresentedItemURL;
- (void)loadPersistentStoreStartupWorkflow;

- (void)managedObjectContextObjectsDidChangeNotification:(NSNotification *)notification;

- (void)checkToImportDayMapLiteData;

- (NSURL *)backupFilesDirectory;
- (IBAction)openWhetstoneAppsDotComSupport:(id)sender;
- (IBAction)moveOverdueTasksToToday:(id)sender;
- (BOOL)isUserLoggedIntoICloud;
- (IBAction)toggleiCloud:(id)sender;
- (NSUndoManager *)undoManager;

- (NSArray *)tasksForDay:(NSDate *)day;
- (NSDate *)completedDateFilter;
- (void)deleteCompletedTasksOlderThan:(NSDate *)olderThanDate;

- (NSURL *)ubiquitousStoreURL;
- (NSURL *)localStoreURL;

- (void)saveContext;

@end
