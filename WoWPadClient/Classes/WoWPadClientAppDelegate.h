//
//  Created by jrk on 26/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import <UIKit/UIKit.h>

@class WoWPadClientViewController;

@interface WoWPadClientAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
    WoWPadClientViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WoWPadClientViewController *viewController;

@end

