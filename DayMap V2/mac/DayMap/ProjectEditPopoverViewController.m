//
//  ProjectEditPopoverViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/7/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectEditPopoverViewController.h"
#import "ProjectDisplayAttributes+Additions.h"
#import "NSColor+WS.h"
#import "AbstractTask+Additions.h"
#import "Project+Additions.h"

@implementation ProjectEditPopoverViewController

+ (ProjectEditPopoverViewController *)projectEditPopoverViewController
{
    id controller = [[self alloc] initWithNibName:@"ProjectEditPopover" bundle:nil];
    return controller;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib {
}

- (IBAction)done:(id)sender
{	
    [self.popover performClose:sender];
}

- (void)popoverWillShow:(NSNotification *)notification {
	[[self.nameTextField window] setInitialFirstResponder:self.nameTextField];
}

- (void)popoverDidShow:(NSNotification *)notification
{
}

- (void)popoverDidClose:(NSNotification *)notification
{
	// Save and close color picker
	[self.colorWell deactivate];
	if ([NSColorPanel sharedColorPanelExists]) {
		[[NSColorPanel sharedColorPanel] close];
	}

	NSPopover *popover = [notification object];
	popover.contentViewController = nil;
}

- (void)setProject:(Project *)project
{
	[self willChangeValueForKey:@"projectColor"];
    _project = project;
	[self didChangeValueForKey:@"projectColor"];
}

- (NSColor *)projectColor
{
	NSColor *color = [self.project.displayAttributes nativeColor];
	if (!color) {
		color = [NSColor randomProjectColor];
	}
	return color;
}

- (void)setProjectColor:(NSColor *)color
{
	[self.project.displayAttributes setNativeColor:color];
}

- (BOOL)archived {
	return [self.project.archived boolValue];
}

- (void)setArchived:(BOOL)archived {
	[self.project setArchivedWithInfoAlert:archived];
}

- (NSAttributedString *)attributedDetails {
	return _project.attributedDetailsAttributedString;
}

- (void)setAttributedDetails:(NSAttributedString *)attributedDetails {
	_project.attributedDetailsAttributedString = attributedDetails;
}

- (IBAction)expand:(id)sender {
	[sender setHidden:YES];
	NSRect frame = self.view.frame;
	frame.size = NSMakeSize(550, 600);
	[self.popover setContentSize:frame.size];
}

@end
