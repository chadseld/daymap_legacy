//
//  UIAlertView+Blocks.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/3/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Blocks)

- (void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
