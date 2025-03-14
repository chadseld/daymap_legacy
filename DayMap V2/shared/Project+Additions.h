//
//  Project+Project_Additions.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "Project.h"

@interface Project (Additions)

+ (Project *)project;
#if !TARGET_OS_IPHONE
- (void)setArchivedWithInfoAlert:(BOOL)archived;
- (NSString *)utf8FormattedString;
#endif
- (NSString *)asHtml;

@end
