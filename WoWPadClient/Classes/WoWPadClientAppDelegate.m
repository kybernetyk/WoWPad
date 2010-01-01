//
//  Created by jrk on 26/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import "WoWPadClientAppDelegate.h"
#import "WoWPadClientViewController.h"

@implementation WoWPadClientAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching: (UIApplication *)application 
{    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	[viewController startClient];
}

- (void)applicationWillTerminate: (UIApplication *)application
{
	[viewController sendStringToServer: @"close\n"];
	[viewController stopClient];
}


- (void)dealloc 
{
    [viewController release];
    [window release];
    [super dealloc];
}


@end
