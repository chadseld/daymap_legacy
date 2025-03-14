//
//  AboutController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/3/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import "AboutController.h"

@implementation AboutController

- (void)awakeFromNib {
	self.appNameLabel.stringValue = [[NSRunningApplication currentApplication] localizedName];

	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *copyright = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleGetInfoString"];
	self.versionLabel.stringValue = [NSString stringWithFormat:@"Version %@\n%@", version, copyright];
	
	NSURL *creditsURL = [[NSBundle mainBundle] URLForResource:@"Credits" withExtension:@"rtf"];
	NSAttributedString *credits = [[NSAttributedString alloc] initWithURL:creditsURL documentAttributes:nil];
	if (credits) [self.infoTextView insertText:credits];
	[self.infoTextView scrollToBeginningOfDocument:self];
	[self.infoTextView setEditable:NO];
	
	NSURL *credits3rdPartyURL = [[NSBundle mainBundle] URLForResource:@"3rdPartyCredits" withExtension:@"rtf"];
	NSAttributedString *credits3rdParty = [[NSAttributedString alloc] initWithURL:credits3rdPartyURL documentAttributes:nil];
	if(credits3rdParty) [self.creditsTextView insertText:credits3rdParty];
	[self.creditsTextView scrollToBeginningOfDocument:self];
	[self.creditsTextView setEditable:NO];
	
	[self.aboutPanel makeFirstResponder:self.aboutPanel];
}

- (IBAction)showAboutPanel:(id)sender {
	[self.aboutPanel makeKeyAndOrderFront:sender];
}

- (IBAction)showCredits:(id)sender {
	[NSApp beginSheet:_creditsWindow
	   modalForWindow:self.aboutPanel
		modalDelegate:nil
	   didEndSelector:NULL 
		  contextInfo:nil];
}

- (IBAction)closeCredits:(id)sender {
	[NSApp endSheet:_creditsWindow];
	[_creditsWindow orderOut:nil];
}

@end
