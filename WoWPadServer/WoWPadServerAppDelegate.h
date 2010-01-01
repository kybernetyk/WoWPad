// WoWPadServerAppDelegate.h
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import <Cocoa/Cocoa.h>
#import "ServerThread.h"


@interface WoWPadServerAppDelegate : NSObject <NSApplicationDelegate, ServerThreadDelegate> 
{
    NSWindow *window; 
	
	NSString *wowScriptLib;				//this string will hold our wow controll applescript
	ServerThread *serverThread;			//well we're not using actual threads here. so the name is confusing. :(
}

@property (assign) IBOutlet NSWindow *window;


#pragma mark -
#pragma mark server control
- (IBAction) startServer: (id) sender;
- (IBAction) stopServer: (id) sender;

#pragma mark -
#pragma mark movement wrapper
- (void) startWalkingForward;
- (void) stopWalkingForward;

- (void) startTurningLeft;
- (void) stopTurningLeft;

- (void) startTurningRight;
- (void) stopTurningRight;

- (void) startWalkingBack;
- (void) stopWalkingBack;

- (void) jump;

#pragma mark -
#pragma mark chat wrapper
- (void) executeString: (NSString *) stringToExecute;	//will pass the given string directly to wow. passing "/dance" to this method will make the char dance ingame
- (void) sayString: (NSString *) textToSay;				//will say the given text in the /say chat
- (void) gchatString: (NSString *) textToSay;			//sill send the given text to the /guild chat

#pragma mark -
#pragma mark applescript keypress wrapper
- (void) pressKeyCode: (NSString *) keyCode;			//will press the key with the given keycode for 0.1 sec
- (void) pressKey: (NSString *) keyName;				//will press the key with the given name for 0.1 sec 

@end
