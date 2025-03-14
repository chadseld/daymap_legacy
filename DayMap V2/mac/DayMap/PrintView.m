//
//  PrintView.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "PrintView.h"
#import "Project.h"
#import "Project+Additions.h"
#import "Task.h"
#import "NSDate+WS.h"
#import "NSString+WS.h"
#import "DayMapAppDelegate.h"
#import "MiscUtils.h"
#import <WebKit/WebKit.h>
#import "AbstractTask+Additions.h"
#import <EventKit/EKEvent.h>

@implementation PrintView {
	void (^completionHandler)(void);
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
	[(WebView *)self.view setUIDelegate:nil];
    [(WebView *)self.view setFrameLoadDelegate:nil];
    [(WebView *)self.view setResourceLoadDelegate:nil];
    self.view = nil;
}

- (void)loadView
{

	self.view = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 850, 1100)]; // We don't need to get this rect right, the web view does its own resizing math for printing
	self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[(WebView *)self.view setFrameLoadDelegate:self];
	[(WebView *)self.view setUIDelegate:self];
	
	[(WebView *)self.view setMaintainsBackForwardList:NO];
    
    WebPreferences *prefs = [[WebPreferences alloc] initWithIdentifier:@"com.whetstoneapps.daymap.printingwebprefs"];
    [prefs setAutosaves:NO];
    [prefs setJavaEnabled:NO];
	[prefs setJavaScriptEnabled:NO];
    [prefs setJavaScriptCanOpenWindowsAutomatically:NO];
    [prefs setPlugInsEnabled:NO];
    [prefs setCacheModel:WebCacheModelDocumentViewer];
    [prefs setUsesPageCache:NO];
    [prefs setPrivateBrowsingEnabled:YES];
    [(WebView *)self.view setPreferences:prefs];

}

- (void)printProjects:(NSArray *)projects completionHandler:(void(^)(void))completion
{
	completionHandler = [completion copy];
	
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[printInfo setHorizontalPagination:NSAutoPagination];//NSFitPagination
	[printInfo setHorizontallyCentered:YES];
    [printInfo setVerticallyCentered:NO];	

	// Start building the HTML
	NSMutableString *html = [[NSMutableString alloc] initWithString:@"<html><head><meta http-equiv='Content-type' content='text/html; charset=utf-8' /><style type='text/css'>"];

	// Load Printing CSS
	NSError *error = nil;
    NSString *css = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"print_outline" withExtension:@"css"] encoding:NSUTF8StringEncoding error:&error];
	if (!css) {
		NSLog(@"Error loading printing CSS: %@", [error localizedDescription]);
	}
	else {
		[html appendString:css];
	}
	
	// Add HTML from projects
	[html appendString:@"</style></head><body>"];
	for (Project *project in projects) {
		[html appendString:[project asHtml]];
	}
	[html appendString:@"</body></html>"];
	
	//DLog(html);

	// Load the HTML
	[[(WebView *)self.view mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
}

- (void)printWeekAsList:(NSDate *)week numberOfDays:(NSInteger)numberOfDays completionHandler:(void(^)(void))completion {
	completionHandler = [completion copy];
	
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[printInfo setHorizontalPagination:NSAutoPagination];//NSFitPagination
	[printInfo setHorizontallyCentered:YES];
	[printInfo setVerticallyCentered:NO];
	
	// Start building the HTML
	NSMutableString *html = [[NSMutableString alloc] initWithString:@"<html><head><meta http-equiv='Content-type' content='text/html; charset=utf-8' /><style type='text/css'>"];
	
	// Load Printing CSS
	NSError *error = nil;
	NSString *css = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"print_outline" withExtension:@"css"] encoding:NSUTF8StringEncoding error:&error];
	if (!css) {
		NSLog(@"Error loading printing CSS: %@", [error localizedDescription]);
	}
	else {
		[html appendString:css];
	}
	
	// Add HTML from projects
	[html appendString:@"</style></head><body>"];

	week = [week beginningOfWeek]; // just make sure
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	if (printInfo.orientation == NSPortraitOrientation) {
		[dateFormatter setDateFormat:@"EEE', 'd"];
	}
	else {
		[dateFormatter setDateFormat:@"EEEE', 'd"];
	}
	NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
	NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"j:mm a" options:0 locale:[NSLocale currentLocale]];
	formatString = [formatString stringByAppendingString:@" - "];
	[timeFormatter setDateFormat:formatString];

	for (int i=0; i<numberOfDays; i++) {
		NSDate *day = [week dateByAddingDays:i];
		NSArray *tasksForDay = [(DayMapAppDelegate *)[NSApp delegate] tasksForDay:day];
		NSArray *filteredTasksForDay = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:tasksForDay], [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], day, SORT_BY_SORTINDEX_DAY);
		
		NSArray *ekEventsForDay = nil;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_EVENTKIT_EVENTS]) {
			ekEventsForDay = [[(DayMapAppDelegate *)[NSApp delegate] eventKitBridge] eventsForDay:day];
		}
		
		[html appendString:@"<div class=\"day\">"];
		[html appendString:@"<div class=\"day_date\">"]; [html appendString:[dateFormatter stringFromDate:day]]; [html appendString:@"</div>"];
		for (Task *task in filteredTasksForDay) {
			[html appendString:@"<div class=\"task\">"];
			if ([task.completed intValue] == TASK_COMPLETED) {
				[html appendString:@"<div class=\"completed\">"];
			}
			[html appendString:@"<div class=\"name\">"]; [html appendString:[task.name ws_asLegalHtml] ? : @"-- Unnammed Task --"]; [html appendString:@"</div>"];
			if (task.attributedDetails) { [html appendString:@"<div class=\"details\">"]; [html appendString:[[task.attributedDetailsAttributedString string] ws_asLegalHtml]]; [html appendString:@"</div>"]; }
			if ([task.completed intValue] == TASK_COMPLETED) {
				[html appendString:@"</div>"]; // Completed
			}
			[html appendString:@"</div>"]; // Task
		}
		
		if (ekEventsForDay.count > 0) {
			[html appendString:@"<div><div class=\"ekeventheader\">"]; [html appendString:@"Apple Calendar Events"]; [html appendString:@"</div></div>"];
		}
		for (EKEvent *event in ekEventsForDay) {
			[html appendString:@"<div class=\"ekevent\">"];
			NSString *timeAndTitle = [[timeFormatter stringFromDate:event.startDate] stringByAppendingString:event.title];
			[html appendString:@"<div class=\"name\">"]; [html appendString:[timeAndTitle ws_asLegalHtml] ? : @"-- Unnammed Apple Calendar Event --"]; [html appendString:@"</div>"];
			[html appendString:@"</div>"]; // EKEvent
		}
		
		[html appendString:@"</div>"]; // Day
	}
	
	[html appendString:@"</body></html>"];
	
	//DLog(html);
	
	// Load the HTML
	[[(WebView *)self.view mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
}

- (void)printWeek:(NSDate *)week completionHandler:(void(^)(void))completion
{
	completionHandler = [completion copy];
	
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[printInfo setHorizontalPagination:NSAutoPagination];//NSFitPagination
	[printInfo setHorizontallyCentered:YES];
    [printInfo setVerticallyCentered:NO];	
	
	// Start building the HTML
	NSMutableString *html = [[NSMutableString alloc] initWithString:@"<html><head><meta http-equiv='Content-type' content='text/html; charset=utf-8' /><style type='text/css'>"];
	
	// Load Printing CSS
	NSError *error = nil;
    NSString *css = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"print_week" withExtension:@"css"] encoding:NSUTF8StringEncoding error:&error];
	if (!css) {
		NSLog(@"Error loading printing CSS: %@", [error localizedDescription]);
	}
	else {
		[html appendString:css];
	}

	// Fill out tasks
	[html appendString:@"</style></head><body>"];
	week = [week beginningOfWeek]; // just make sure
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	if (printInfo.orientation == NSPortraitOrientation) {
		[dateFormatter setDateFormat:@"EEE', 'd"];
	} 
	else {
		[dateFormatter setDateFormat:@"EEEE', 'd"];
	}
    for (int i=0; i<7; i++) {
		NSDate *day = [week dateByAddingDays:i];
		NSArray *tasksForDay = [(DayMapAppDelegate *)[NSApp delegate] tasksForDay:day];
		NSArray *filteredTasksForDay = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:tasksForDay], [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], day, SORT_BY_SORTINDEX_DAY);

		[html appendString:@"<div class=\"day\">"];
		[html appendString:@"<div class=\"day_date\">"]; [html appendString:[dateFormatter stringFromDate:day]]; [html appendString:@"</div>"]; 
		for (Task *task in filteredTasksForDay) {
			[html appendString:@"<div class=\"task\">"];
			if ([task.completed intValue] == TASK_COMPLETED) {
				[html appendString:@"<div class=\"completed\">"];		
			}
			[html appendString:@"<div class=\"name\">"]; [html appendString:[task.name ws_asLegalHtml] ? : @"-- Unnammed Task --"]; [html appendString:@"</div>"];
			if (task.attributedDetails) { [html appendString:@"<div class=\"details\">"]; [html appendString:[[task.attributedDetailsAttributedString string] ws_asLegalHtml]]; [html appendString:@"</div>"]; }
			if ([task.completed intValue] == TASK_COMPLETED) {
				[html appendString:@"</div>"]; // Completed
			}
			[html appendString:@"</div>"]; // Task
		}
		[html appendString:@"</div>"]; // Day


	}
	[html appendString:@"</body></html>"];

	//DLog(html);

	// Load the HTML
	[[(WebView *)self.view mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
{
	// Print!
//	[[[[(WebView *)self.view mainFrame] frameView] documentView] print:self];
	
	// Run completion handler
//	completionHandler();
	
	
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:[[[(WebView *)self.view mainFrame] frameView] documentView]];
	
	//[printOperation runOperation];
	[printOperation runOperationModalForWindow:[NSApp mainWindow] delegate:self didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:NULL];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)info
{
	completionHandler();
}

- (float)webViewHeaderHeight:(WebView *)sender
{
	return 0;
	// TODO - implement - (void)webView:(WebView *)sender drawHeaderInRect:(NSRect)rect
	// or footer version and print page numbers, current date, etc...
}

- (float)webViewFooterHeight:(WebView *)sender
{
	return 0;
}

@end
