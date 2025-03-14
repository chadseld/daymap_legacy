//
//  WSAppDelegate.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/24/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSAppDelegate.h"
#import "WSProjectViewController.h"
#import "WSInboxViewController.h"
#import "WSTodayViewController.h"
#import "NSDate+WS.h"
#import "Task.h"
#import "DayMap.h"


@implementation WSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSMutableDictionary *defaultDefaults = [NSMutableDictionary dictionary];
	[defaultDefaults setValue:@(14) forKey:PREF_HIDE_COMPLETED_INTERVAL];
	[defaultDefaults setValue:@(0.3694) forKey:PREF_RAND_PROJECT_COLOR];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];

	// Load Core Data
	[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:nil userInfo:nil];
    [self setupCoreDataStack];
    [self loadPersistentStoreStartupWorkflow];

    // Override point for customization after application launch.
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
	    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];//Detail View
	    splitViewController.delegate = (id)navigationController.topViewController;
	    
        //List View
	    UITabBarController *projectTabController = [splitViewController.viewControllers objectAtIndex:0];
        UINavigationController *projectNavController = [projectTabController.viewControllers objectAtIndex:0];
        
	    WSProjectViewController *controller = (WSProjectViewController *)projectNavController.topViewController;
        
        projectNavController = [projectTabController.viewControllers objectAtIndex:1];
        controller = (WSProjectViewController*)projectNavController.topViewController;
	} else {
        [[UITableView appearance] setSeparatorColor:[UIColor dayMapDividerColor]];
        [[UISlider appearance] setMinimumTrackTintColor:[UIColor dayMapDividerColor]];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        backgroundView.backgroundColor = [UIColor dayMapSelectedTaskBackgroundColor];
        [[UITableViewCell appearance] setSelectedBackgroundView:backgroundView];
        
		UITabBarController *tabViewController = (UITabBarController *)self.window.rootViewController;
        tabViewController.view.tintColor = [UIColor dayMapActionColor];
        for (UITabBarItem *item in tabViewController.tabBar.items) {
			if (100 == item.tag) {
                [item setSelectedImage:[UIImage imageNamed:@"today"]];
            }
			if (101 == item.tag) {
                [item setSelectedImage:[UIImage imageNamed:@"inbox"]];
            }
			if (102 == item.tag) {
                [item setSelectedImage:[UIImage imageNamed:@"projects"]];
            }
			if (103 == item.tag) {
                [item setSelectedImage:[UIImage imageNamed:@"settings"]];
            }
			if (104 == item.tag) {
                [item setSelectedImage:[UIImage imageNamed:@"week"]];
            }
		}
	}

	// Register for change notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(managedObjectContextObjectsDidChangeNotification:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	DLog(@"applicationDidEnterBackground");
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	DLog(@"applicationWillEnterForeground");
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	DLog(@"applicationDidBecomeActive");
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	DLog(@"applicationWillTerminate");
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}


#pragma mark - Core Data Operations

- (NSDate *)completedDateFilter
{
	NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:PREF_HIDE_COMPLETED_INTERVAL];
//    NSInteger value = 0;
	if (0 == value ) { // hide all
		return [NSDate distantFuture];
	}
	else if (91 == value) { // none
		return [NSDate distantPast];
	}
	else {
		return [[NSDate today] dateByAddingDays:-value];
	}
}


@end
