//
//  DMClearableDatePickerCell.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/5/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "DMClearableDatePickerCell.h"


@interface NSDatePickerCell (Private)
- (void)_commitSubfieldFieldChanges;
- (void)_userEditExpired:(id)foo;
- (void)_constrainAndSetDateValue:(id)date timeInterval:(NSTimeInterval)ti sendActionIfChanged:(BOOL)saic beepIfNoChange:(BOOL)binc returnCalendarToHomeMonth:(BOOL)rcthm preserveFractionalSeconds:(BOOL)pfs;
@end


@implementation DMClearableDatePickerCell {
	BOOL _handleNextExpiration;
}

- (void)setDateValue:(NSDate *)dateValue {
	if (nil == dateValue || [dateValue isEqualToDate:[NSDate distantFuture]]) {
		//[self clearControl];
		dateValue = [NSDate distantFuture]; // can't set date value to nil, it gets ignored
	}
	else {
		//[self unclearControl];
	}
	[super setDateValue:dateValue];
}

- (NSDate *)dateValue {
	if ([super.dateValue isEqualToDate:[NSDate distantFuture]]) { // NSDatePicker never has a nil date
		return nil;
	}
	return super.dateValue;
}

/*** This section is to block the 1-second edit timeout bug in NSDatePicker ***/
- (void)_userEditExpired:(id)foo {
	if([super respondsToSelector:@selector(_userEditExpired:)] && _handleNextExpiration) {
		[super _userEditExpired:foo];
		_handleNextExpiration = NO;
	}
}

- (void)_constrainAndSetDateValue:(id)date timeInterval:(NSTimeInterval)ti sendActionIfChanged:(BOOL)saic beepIfNoChange:(BOOL)binc returnCalendarToHomeMonth:(BOOL)rcthm preserveFractionalSeconds:(BOOL)pfs {
	if([super respondsToSelector:@selector(_constrainAndSetDateValue:timeInterval:sendActionIfChanged:beepIfNoChange:returnCalendarToHomeMonth:preserveFractionalSeconds:)]) {
		if([[self controlView] window] != nil) {
			_handleNextExpiration = YES;
		}
		[super _constrainAndSetDateValue:date timeInterval:ti sendActionIfChanged:saic beepIfNoChange:binc returnCalendarToHomeMonth:rcthm preserveFractionalSeconds:pfs];
	}
}
/***/

@end
