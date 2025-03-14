//
//  WSProjectTableViewCell.h
//  DayMap
//
//  Created by Jonathan Huggins on 12/6/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+Additions.h"

@interface WSProjectTableViewCell : UITableViewCell

@property (nonatomic, strong) Project *project;

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIView *colorView;

@end
