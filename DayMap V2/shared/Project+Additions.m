//
//  Project+Project_Additions.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "Project+Additions.h"
#import "WSRootAppDelegate.h"
#import "Task+Additions.h"
#import "MiscUtils.h"
#import "NSString+WS.h"
#import "AbstractTask+Additions.h"

@implementation Project (Additions)

+ (Project *)project
{
	Project *project = [[Project alloc] initWithEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	project.uuid = WSCreateUUID();
	project.createdDate = [NSDate date];
    project.name = @"Untitled Project";
    
	// Currently we have a temporaryID. Since we are going to use the objectID for identification e.g. drag or save to prefs we need ampermanent one immediately.
//	NSError *error = nil;
//	if (![context obtainPermanentIDsForObjects:[NSArray arrayWithObject:project] error:&error]) {
//		// Operation failed, so we punt and do a slower save of all changes
//		[[(WSRootAppDelegate *)[NSApp delegate] managedObjectContext] save:NULL];
//	}
    
	return project;
}

#if !TARGET_OS_IPHONE
- (void)setArchivedWithInfoAlert:(BOOL)archived {
	self.archived = [NSNumber numberWithBool:archived];
	
	if (archived && ![[NSUserDefaults standardUserDefaults] boolForKey:@"supressArchiveInfoAlert"]) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.messageText = NSLocalizedString(@"Project Archived", @"alert title");
		alert.informativeText = NSLocalizedString(@"Archived projects and their subtasks are hidden from view. You can show your archived projects by choosing “Show Archived Projects” from the View menu.", @"alert text");
		[alert setShowsSuppressionButton:YES];
		[alert runModal];
		if ([[alert suppressionButton] state] == NSOnState) {
			// Suppress this alert from now on.
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supressArchiveInfoAlert"];
		}
	}
}

- (NSString *)utf8FormattedString {
	return [Task utf8FormattedStringForTasks:[self sortedFilteredChildren]];
}

#endif

- (NSString *)asHtml
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];

	NSMutableString *html = [[NSMutableString alloc] init];
	[html appendString:@"<div class=\"project\">"];
	[html appendString:@"<div class=\"name\">"]; [html appendString:[self.name ws_asLegalHtml] ? : @"-- Unnammed Project --"]; [html appendString:@"</div>"];
	if (self.completedDate) { [html appendString:@"<div class=\"completedDate\"> - Completed on: "]; [html appendString:[dateFormatter stringFromDate: self.completedDate]]; [html appendString:@"</div>"]; }
	
	if (self.attributedDetails) { [html appendString:@"<div class=\"details\">"]; [html appendString:[[self.attributedDetailsAttributedString string] ws_asLegalHtml]]; [html appendString:@"</div>"]; }
	[html appendString:@"<div class=\"children\">"];
	NSArray *filteredChildren = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(self.children, [(WSRootAppDelegate *)[NSApp delegate] completedDateFilter], nil, SORT_BY_SORTINDEX);
	for (Task *task in filteredChildren) {
		[html appendString:[task asHtml]];
	}
	[html appendString:@"</div>"]; // Children
	
	[html appendString:@"</div>"]; // Project

	return html;
}

@end
