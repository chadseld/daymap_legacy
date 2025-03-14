//
//  NSString+WS.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/21/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_WS)

//- (NSShadow *)ws_blackEmbossShadow;
//- (NSAttributedString *)attributedStringWithShadow:(NSShadow *)shadow;

- (NSString *)ws_asLegalHtml;
+ (NSString *)ws_humanReadableSizeStringForBytes:(unsigned long long)bytes;

@end
