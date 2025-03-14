//
//  WSSettingsViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/5/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSSettingsViewController.h"
#import "WSAppDelegate.h"

@implementation WSSettingsViewController

- (void)viewDidLoad {

	// iCloud
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_ICLOUD_STORAGE options:0 context:(__bridge void*)self];
	[self.toggleiCloudButton setOn:[[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_ICLOUD_STORAGE] animated:NO];
    
    self.pastDateFilterSlider.value = [[NSUserDefaults standardUserDefaults] integerForKey:PREF_HIDE_COMPLETED_INTERVAL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_ICLOUD_STORAGE]) {
			[self.toggleiCloudButton setOn:[[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_ICLOUD_STORAGE] animated:YES];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewWillUnload
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_ICLOUD_STORAGE];
}

- (IBAction)toggleiCloud:(id)sender
{
	[(WSAppDelegate *)[[UIApplication sharedApplication] delegate] toggleiCloud:sender];
	[self.toggleiCloudButton setOn:[[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_ICLOUD_STORAGE] animated:YES];
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell == self.supportTableCell) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://whetstoneapps.com/support/"]];
	}
	if (cell == self.overDueCell) {
        [(WSAppDelegate *)[[UIApplication sharedApplication] delegate] moveOverdueTasksToToday:nil];
    }
	[cell setSelected:NO];
}

- (IBAction)fiterDateChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)slider.value forKey:PREF_HIDE_COMPLETED_INTERVAL];
    self.sliderLabel.text = @"Hide Completed Tasks";
}

- (IBAction)changeDisplayValue:(id)sender {
    UISlider *slider = (UISlider *)sender;
    switch ((NSInteger)slider.value) {
        case 0:
            self.sliderLabel.text = @"Hide All";
            break;
            
        case 91:
            self.sliderLabel.text = @"Don't Hide";
            break;
            
        default:
            self.sliderLabel.text = [NSString stringWithFormat:@"%ld Days Ago", (long)slider.value];
            break;
    }
}
@end
