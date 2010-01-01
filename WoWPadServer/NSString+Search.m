// NSString+Search.m
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import "NSString+Search.h"


@implementation NSString (SearchingAdditions)

- (BOOL)containsString:(NSString *)aString 
{
    return [self containsString:aString ignoringCase:NO];
}

- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag 
{
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length > 0;
}

@end