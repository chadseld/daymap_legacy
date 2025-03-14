//
//  UpgradeNudgeWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/21/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    DMUpgradeNudgeReasonICloud = 0,
	DMUpgradeNudgeReasonOther
} DMUpgradeNudgeReason;

@interface UpgradeNudgeWindowController : NSWindowController
@property (weak) IBOutlet NSTextField *reasonTextField;
- (IBAction)purchaseNow:(id)sender;
- (IBAction)notNow:(id)sender;
- (IBAction)moreInformation:(id)sender;

@property (nonatomic, assign) DMUpgradeNudgeReason reason;
@end
