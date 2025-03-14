//
//  WSProjectTableViewCell.m
//  DayMap
//
//  Created by Jonathan Huggins on 12/6/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "WSProjectTableViewCell.h"
#import "ProjectDisplayAttributes+Additions.h"


@implementation WSProjectTableViewCell

- (void)dealloc {
	[self.project removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	[self.project removeObserver:self forKeyPath:@"displayAttributes.color" context:(__bridge void*)self];
}

- (void)awakeFromNib {
	self.colorView.layer.cornerRadius = 5;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"name"] ||
			[keyPath isEqualToString:@"displayAttributes.color"]) {
			if (self.project) {
				self.label.text = self.project.name ? : @"";
				self.colorView.backgroundColor = [self.project.displayAttributes nativeColor];
				//    cell.colorView.layer.cornerRadius = 5;
			}
        }
		else {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setProject:(Project *)project {
	[self.project removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	[self.project removeObserver:self forKeyPath:@"displayAttributes.color" context:(__bridge void*)self];

	_project = project;

	[self.project addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
	[self.project addObserver:self forKeyPath:@"displayAttributes.color" options:0 context:(__bridge void*)self];

	[self observeValueForKeyPath:@"name" ofObject:self.project change:nil context:(__bridge void*)self];
}

@end
