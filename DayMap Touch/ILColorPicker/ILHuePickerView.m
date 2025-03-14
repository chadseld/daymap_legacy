//
//  ILHuePicker.m
//  ILColorPickerExample
//
//  Created by Jon Gilkison on 9/1/11.
//  Copyright 2011 Interfacelab LLC. All rights reserved.
//

#import "ILHuePickerView.h"

@interface ILHuePickerView(Private)

-(void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event;

@end

@implementation ILHuePickerView


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
	self.clipsToBounds=YES;
	self.hue=0.5;
	self.pickerOrientation=ILHuePickerViewOrientationHorizontal;
}

#pragma mark - Drawing

-(void)drawRect:(CGRect)rect
{
    // draw the hue gradient
    CGContextRef context=UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    
    float step=0.166666666666667f;
    
    CGFloat locs[7]={ 
        0.00f, 
        step, 
        step*2, 
        step*3, 
        step*4, 
        step*5, 
        1.0f
    };
    
    NSArray *colors=[NSArray arrayWithObjects:
                     (id)[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0] CGColor], 
                     (id)[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] CGColor], 
                     nil];
    
    CGGradientRef grad=CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locs);
    if (self.pickerOrientation==ILHuePickerViewOrientationHorizontal)
        CGContextDrawLinearGradient(context, grad, CGPointMake(rect.size.width,0), CGPointMake(0, 0), 0);
    else
        CGContextDrawLinearGradient(context, grad, CGPointMake(0,rect.size.height), CGPointMake(0, 0), 0);
        
    CGGradientRelease(grad);
     
    CGColorSpaceRelease(colorSpace);
    
    // Draw the indicator
    float pos=(self.pickerOrientation==ILHuePickerViewOrientationHorizontal) ? rect.size.width*self.hue : rect.size.height*self.hue;
    float indLength=(self.pickerOrientation==ILHuePickerViewOrientationHorizontal) ? rect.size.height/3 : rect.size.width/3;
    
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetShadow(context, CGSizeMake(0, 0), 4);

    if (self.pickerOrientation==ILHuePickerViewOrientationHorizontal)
    {
        CGContextMoveToPoint(context, pos-(indLength/2), -1);
        CGContextAddLineToPoint(context, pos+(indLength/2), -1);
        CGContextAddLineToPoint(context, pos, indLength);
        CGContextAddLineToPoint(context, pos-(indLength/2), -1);

        CGContextMoveToPoint(context, pos-(indLength/2), rect.size.height+1);
        CGContextAddLineToPoint(context, pos+(indLength/2), rect.size.height+1);
        CGContextAddLineToPoint(context, pos, rect.size.height-indLength);
        CGContextAddLineToPoint(context, pos-(indLength/2), rect.size.height+1);
    }
    else
    {
        CGContextMoveToPoint(context, -1, pos-(indLength/2));
        CGContextAddLineToPoint(context, -1, pos+(indLength/2));
        CGContextAddLineToPoint(context, indLength, pos);
        CGContextAddLineToPoint(context, -1, pos-(indLength/2));
        
        CGContextMoveToPoint(context, rect.size.width+1, pos-(indLength/2));
        CGContextAddLineToPoint(context, rect.size.width+1, pos+(indLength/2));
        CGContextAddLineToPoint(context, rect.size.width-indLength, pos);
        CGContextAddLineToPoint(context, rect.size.width+1, pos-(indLength/2));
    }
    
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}

#pragma mark - Touches

-(void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint pos=[[touches anyObject] locationInView:self];
    
    float p=(self.pickerOrientation==ILHuePickerViewOrientationHorizontal) ? pos.x : pos.y;
    float b=(self.pickerOrientation==ILHuePickerViewOrientationHorizontal) ? self.frame.size.width : self.frame.size.height;
    
    if (p<0)
        self.hue=0;
    else if (p>b)
        self.hue=1;
    else
        self.hue=p/b;
    
    [self.delegate huePicked:self.hue picker:self];
    
    [self setNeedsDisplay];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches withEvent:event];
}

#pragma mark - Property Setters

-(void)setHue:(float)h
{
    _hue=h;
    [self setNeedsDisplay];
}

-(void)setPickerOrientation:(ILHuePickerViewOrientation)po
{
    _pickerOrientation=po;
    [self setNeedsDisplay];
}

#pragma mark - Current color

-(void)setColor:(UIColor *)cc
{
	CGFloat h = 0;
	[cc getHue:&h saturation:nil brightness:nil alpha:nil];
	
    self.hue=h;
    [self setNeedsDisplay];
}

-(UIColor *)color
{
    return [UIColor colorWithHue:self.hue saturation:1.0f brightness:1.0f alpha:1.0];
}

@end
