//
//  NSString+WS.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/21/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "NSString+WS.h"

@implementation NSString (NSString_WS)
//
//- (NSShadow *)ws_blackEmbossShadow
//{
//	NSShadow *shadow = [[NSShadow alloc] init];
//    shadow.shadowOffset = NSMakeSize(0, 1.0);
//    shadow.shadowBlurRadius = 1.0;
//    shadow.shadowColor = [NSColor blackColor];
//	return shadow;
//}
//
//- (NSAttributedString *)ws_attributedStringWithShadow:(NSShadow *)shadow
//{
//    if(self.length == 0) return nil;
//    
//    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//    paragraphStyle.alignment = [_titleLabel alignment];//NSCenterTextAlignment;
//    paragraphStyle.lineBreakMode = [[_titleLabel cell] lineBreakMode];//NSLineBreakByTruncatingTail;
//    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
//                                [_titleLabel font], NSFontAttributeName,
//                                [_titleLabel textColor], NSForegroundColorAttributeName,
//                                paragraphStyle, NSParagraphStyleAttributeName,
//                                shadow, NSShadowAttributeName, nil];
//	
//    return [[NSAttributedString alloc] initWithString:self attributes:attributes];
//}

- (NSString *)ws_asLegalHtml
{
	NSMutableString *s = [NSMutableString stringWithString:self];
	[s replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\r\n" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\n\r" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\n" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\r" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\xE2\x80\xA8" withString:@"<br />" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	return s;
}

+ (NSString *)ws_humanReadableSizeStringForBytes:(unsigned long long)bytes
{
    NSString *sizeString;
    if(bytes > 1073741824ULL) { // GB
        sizeString = [NSString stringWithFormat:NSLocalizedString(@"%.1f GB", @"file size"), bytes/1073741824.0];
    }
    else if(bytes > 1048576ULL) { // > 1MB
        sizeString = [NSString stringWithFormat:NSLocalizedString(@"%.1f MB", @"file size"), bytes/1048576.0];
    }
    else if(bytes > 1024ULL) { // > 1KB
        sizeString = [NSString stringWithFormat:NSLocalizedString(@"%llu KB", @"file size"), bytes/1024ULL];
    }
    else {
        sizeString = [NSString stringWithFormat:NSLocalizedString(@"%llu bytes", @"file size"), bytes];
    }
    return sizeString;
}

@end
