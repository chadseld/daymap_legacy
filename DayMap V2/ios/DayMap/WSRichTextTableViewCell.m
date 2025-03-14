//
//  WSRichTextTableViewCell.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/23/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSRichTextTableViewCell.h"
#import "NSDate+WS.h"

@interface WSRichTextTableViewCell ()

@property (nonatomic) BOOL strikeThrough;
@property (nonatomic) BOOL italic;

@end


@implementation WSRichTextTableViewCell

- (void)dealloc {
	if ([self.task.entity.name isEqualToString:@"Task"]) {
		[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
	}
	else {
		[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	}
}

- (void)setItalic:(BOOL)italic {
	if (self.shouldItalicize) {
		_italic = italic;
		[self updateFont];
	}
}

- (void)setStrikeThrough:(BOOL)strikeThrough
{
    _strikeThrough = strikeThrough;
    [self updateFont];
}

- (void)updateFont
{
    if (_italic) {
        self.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        NSMutableAttributedString *italicText = [self.textField.attributedText mutableCopy];
        
        UIFontDescriptor *fontDesc = [self.textField.font fontDescriptor];
        fontDesc = [fontDesc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        
        // Create the italicized font from the descriptor
        UIFont *italicsFont = [UIFont fontWithDescriptor:fontDesc size:self.textField.font.pointSize];
        
        // Create the attributes dictionary that we'll use to italicize parts of our NSMutableAttributedString
        NSDictionary *italicsAttributes = @{ NSFontAttributeName: italicsFont };
        
        [italicText setAttributes:italicsAttributes range:NSMakeRange(0, italicText.length)];
        self.textField.attributedText = italicText;
    }
    else {
        self.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }

    if (_strikeThrough) {
        NSMutableAttributedString *strikeText = [self.textField.attributedText mutableCopy];

        [strikeText addAttributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]} range:NSMakeRange(0, strikeText.length)];
        
        self.textField.attributedText = strikeText;
    }
    else {
        NSMutableAttributedString *strikeText = [self.textField.attributedText mutableCopy];
        
        [strikeText addAttributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleNone]} range:NSMakeRange(0, strikeText.length)];
        
        self.textField.attributedText = strikeText;
    }

}

- (void)awakeFromNib {
	[super awakeFromNib];
    [self observeValueForKeyPath:@"name" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"name"] ||
			[keyPath isEqualToString:@"completed"] ||
			[keyPath isEqualToString:@"repeat"] ||
			[keyPath isEqualToString:@"completedDate"] ||
			[keyPath isEqualToString:@"scheduledDate"] ||
			[keyPath isEqualToString:@"attributedDetails"] ||
			[keyPath isEqualToString:@"repeat.completions"] ||
			[keyPath isEqualToString:@"repeat.exceptions"]) {
			if (self.task) {
				self.textField.text = self.task.name ? : @"";
				self.italic = ([self.task.entity.name isEqualToString:@"Task"] && ((Task *)self.task).scheduledDate != nil);
				if ([self.task.entity.name isEqualToString:@"Task"] && [(Task *)self.task isCompletedAtDate:self.day partial:nil]) {
					self.completedButton.selected = YES;
					self.strikeThrough = YES;
				}
				else {
					self.completedButton.selected = NO;
					self.strikeThrough = NO;
				}
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

-(void)setTask:(AbstractTask *)task
{
	if ([self.task.entity.name isEqualToString:@"Task"]) {
		[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
		[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
	}
	else {
		[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	}

    _task = task;

    self.textField.enabled = NO;
    self.textField.delegate = self;
        
    if(self.gestureRecognizers.count == 0)
    {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editTitle)];
        longPress.minimumPressDuration = 0.6;
        [self addGestureRecognizer:longPress];
    }

	if ([self.task.entity.name isEqualToString:@"Task"]) {
		[self.task addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"completed" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"repeat" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"completedDate" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"scheduledDate" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"attributedDetails" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"repeat.completions" options:0 context:(__bridge void*)self];
		[self.task addObserver:self forKeyPath:@"repeat.exceptions" options:0 context:(__bridge void*)self];
	}
	else {
		[self.task addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
	}

	[self observeValueForKeyPath:@"name" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (void)editTitle
{
    self.textField.enabled = YES;
    [self.textField becomeFirstResponder];
    [self.textField selectAll:nil];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    self.textField.enabled = NO;
    [self.task setValue:self.textField.text forKey:@"name"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WSRichTextTableViewCellResignedObserverNotification object:nil userInfo:@{@"taskID":[self.task uuid]}];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    [[NSNotificationCenter defaultCenter] postNotificationName:WSRichTextTableViewCellResignedObserverNotification object:nil userInfo:@{@"taskID":[self.task uuid]}];

    return YES;
}

- (IBAction)toggleCompleted:(id)sender
{
    Task *task = (Task *)self.task;
	[task toggleCompletedAtDate:self.day partial:NO];
}

@end
