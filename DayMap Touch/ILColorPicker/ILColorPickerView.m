//
//  ILColorPicker.m
//  ILColorPickerExample
//
//  Created by Jon Gilkison on 9/2/11.
//  Copyright 2011 Interfacelab LLC. All rights reserved.
//

#import "ILColorPickerView.h"

@interface ILColorPickerView ()

@property (nonatomic, strong) ILSaturationBrightnessPickerView *satPicker;
@property (nonatomic, strong) ILHuePickerView *huePicker;
@property (nonatomic, strong) NSArray *rightLayoutConstraints;
@property (nonatomic, strong) NSArray *bottomLayoutConstraints;

@end


@implementation ILColorPickerView

#pragma mark - Setup

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self _init];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self _init];
	}
	return self;
}

-(void)_init
{
    self.opaque=NO;
    self.backgroundColor=[UIColor clearColor];
    
    self.huePicker=[[ILHuePickerView alloc] initWithFrame:CGRectZero];
	self.huePicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.huePicker];
	self.satPicker=[[ILSaturationBrightnessPickerView alloc] initWithFrame:CGRectZero];
	self.satPicker.translatesAutoresizingMaskIntoConstraints = NO;
	self.satPicker.delegate=self;
	self.huePicker.delegate=self.satPicker;
	[self addSubview:self.satPicker];
	
	NSDictionary *viewsDict = @{@"hue" : self.huePicker, @"saturation" : self.satPicker};
	self.rightLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[saturation]-10-[hue(38)]-0-|" options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:viewsDict];
	self.rightLayoutConstraints = [self.rightLayoutConstraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[saturation]-0-|" options:0 metrics:nil views:viewsDict]];

	self.bottomLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[saturation]-10-[hue(38)]-0-|" options:NSLayoutFormatAlignAllLeading|NSLayoutFormatAlignAllTrailing metrics:nil views:viewsDict];
	self.bottomLayoutConstraints = [self.bottomLayoutConstraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[saturation]-0-|" options:0 metrics:nil views:viewsDict]];
	
    self.pickerLayout=ILColorPickerViewLayoutBottom;
}

#pragma mark - Property Set/Get

-(void)setPickerLayout:(ILColorPickerViewLayout)layout
{
    _pickerLayout = layout;
    
    if (layout==ILColorPickerViewLayoutBottom)
    {
        self.huePicker.pickerOrientation=ILHuePickerViewOrientationHorizontal;
		
		[NSLayoutConstraint deactivateConstraints:self.rightLayoutConstraints];
		[NSLayoutConstraint activateConstraints:self.bottomLayoutConstraints];

    }
    else
    {
        self.huePicker.pickerOrientation=ILHuePickerViewOrientationVertical;

		[NSLayoutConstraint deactivateConstraints:self.bottomLayoutConstraints];
		[NSLayoutConstraint activateConstraints:self.rightLayoutConstraints];
    }
}

-(UIColor *)color
{
    return self.satPicker.color;
}

-(void)setColor:(UIColor *)c
{
    self.satPicker.color=c;
    self.huePicker.color=c;
}

#pragma mark - ILSaturationBrightnessPickerDelegate

-(void)colorPicked:(UIColor *)newColor forPicker:(ILSaturationBrightnessPickerView *)picker
{
    [self.delegate colorPicked:newColor forPicker:self];
}

@end
