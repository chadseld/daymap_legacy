//
//  WSAboutViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/15/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSAboutViewController.h"

@interface WSAboutViewController ()

@end

@implementation WSAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	self.versionLabel.text = [NSLocalizedString(@"Version ", @"about") stringByAppendingString:version];
}

- (void)viewDidUnload
{
	[self setVersionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)dismiss:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
