//
//  WSProjectColorPickerViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSProjectColorPickerViewController.h"

@interface WSProjectColorPickerViewController ()

@end

@implementation WSProjectColorPickerViewController
@synthesize color = _color;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.colorPicker.pickerLayout = ILColorPickerViewLayoutRight;
	self.colorPicker.color = _color;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setColor:(UIColor *)color {
	_color = color;
	self.colorPicker.color = color;
}

- (UIColor *)color {
	return self.colorPicker.color;
}

- (IBAction)doneButtonPressed:(id)sender {
	[self.delegate colorPickerController:self didPickColor:self.color];
}

- (void)viewDidUnload {
	[self setColorPicker:nil];
	[super viewDidUnload];
}

@end
