//  Created by jrk on 26/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import <UIKit/UIKit.h>

#pragma mark interface
@interface WoWPadClientViewController : UIViewController 
{
	IBOutlet UIView *view1;					//view with WASD + space
	IBOutlet UIView *view2;					//view with some other keybindings
	IBOutlet UIView *view3;					//chat view
	UIView *currentSubView;					//the currently active subview
	
	IBOutlet UITextField *chatTextField;	//our chat input text field

	NSFileHandle *clientSocketFileHandle;	//we'll be doing network communication over a NSFileHandle (abuse ;)
	NSNetServiceBrowser *netServiceBrowser; //the service browser for bonjour discovery
}

#pragma mark -
#pragma mark client control
- (void)startClient;						//look for active servers over bonjour
- (void)stopClient;							//disconnect us from our server

#pragma mark -
#pragma mark UI stuff
- (IBAction) pageChanged: (id) sender;		//action called by the page view control to indicate a page change (we'll swap the subviews)

#pragma mark -
#pragma mark client/server communication
- (void) sendStringToServer: (NSString *) stringToSend;		//sends a string to the server we're connected with. 

#pragma mark -
#pragma mark wow chat
- (IBAction) sendTextToRaw: (id) sender;	//sends a raw wow /emote oder text
- (IBAction) sendTextToSay: (id) sender;	//sends a text to the /say chat
- (IBAction) sendTextToGuild: (id) sender;	//sends a text to the guild

#pragma mark -
#pragma mark wow movement
- (IBAction) jump: (id) sender;				//wow's most important functionality: jump!

- (IBAction) startForward: (id) sender;		//start moving forward (sent on tap down)
- (IBAction) stopForward: (id) sender;		//stop moving forward (sent on tap up)

- (IBAction) startRight: (id) sender;
- (IBAction) stopRight: (id) sender;

- (IBAction) startBack: (id) sender;
- (IBAction) stopBack: (id) sender;

- (IBAction) startLeft: (id) sender;
- (IBAction) stopLeft: (id) sender;

#pragma mark -
#pragma mark send keycodes to wow
- (IBAction) sendF: (id) sender;			//here we will send some keycods to wow. these keys are bound on my char to certain actions
- (IBAction) sendR: (id) sender;			//you may want to change/add/remove keybindings here
- (IBAction) sendT: (id) sender;

- (IBAction) sendTab: (id) sender;			//sends a tabulator \t to wow (this is bound to change the current target)



@end

