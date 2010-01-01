// WoWPadServerAppDelegate.m
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import "WoWPadServerAppDelegate.h"
#import "ServerThread.h"
#import "NSString+Search.h"

// WARNING: The AppleScript stuff is a mess! Don't try this at home :)

/*
 the program flow:
 
 1. do nothing until the user clicks on the "start"-button.
 2.	if the start button was clicked, start up our server thread (-startServer:)
 3. the server will listen for incomig connection requests and create new SessionThread instance for each connection
 4. if the user clicks on the "stop"-button, we will stop the server. the server will disconnect all connected clients and deannoune itself from bonjour. goto 1.
*/

@implementation WoWPadServerAppDelegate

@synthesize window;

#pragma mark -
#pragma mark cocoa application stuff
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	//load our wow controlling applescript from the "wow steer.applescript" file
	wowScriptLib = [[NSString alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"wow steer" ofType: @"applescript"]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	//let's kill our server (closing connections, deanouncing bonjour services, and freeing sockets)
	[serverThread stopServing];
}

- (void) dealloc
{
	[wowScriptLib release];
	[serverThread release];

	[super dealloc];
}

#pragma mark -
#pragma mark server control
- (IBAction) startServer: (id) sender
{
	//there can be only one server ;)
	if (!serverThread)
	{
		serverThread = [[ServerThread alloc] init];
		[serverThread setDelegate: self];
		[serverThread startServing];					//let's start our service, anounce it with bonjour and bind a socket
	}
	else 
	{
		NSLog(@"server running already!");
	}

}

- (IBAction) stopServer: (id) sender
{
	[serverThread stopServing];
	[serverThread release];
	serverThread = nil;
}



#pragma mark -
#pragma mark applescript keypress wrapper methods
/*
 wrapper for:
 
 -- will take a keycode and press the key for 0.1 sec
 on press_keycode(keycode)
	tell application "System Events" to tell process "World Of Warcraft"
		key code keycode
		delay 0.1
	end tell
 end press_keycode
*/ 
- (void) pressKeyCode: (NSString *) keyCode
{
	keyCode = [keyCode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	keyCode = [keyCode stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = [NSString stringWithFormat:@"press_keycode (%@)\n",keyCode];
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}

/* 
 wrapper for:
 
 -- presses a key, holds it down for a given time and releases it again
 on press_key(key, howlong)
	tell application "System Events" to tell process "World Of Warcraft"
		key down key
		delay howlong
		key up key
	end tell
 end press_key
*/ 
- (void) pressKey: (NSString *) keyName
{
	keyName = [keyName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	keyName = [keyName stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = [NSString stringWithFormat:@"press_key (\"%@\",0.1)\n",keyName];

	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];

	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError]; //here our applescript request ist passed to the system and executed.
	[appleScript release];
	[scriptError release];
	
}

#pragma mark -
#pragma mark chat wrapper
/*
 this method will execute a string directly in wow.
 so if you pass @"/lol" to it, the following will happen:
 
 1. a return-keystroke will be sent to open the wow's input prompt
 2. /lol will be typed
 3. a return-keystroke will be sent to finish the input
*/
- (void) executeString: (NSString *) stringToExecute
{
	stringToExecute = [stringToExecute stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	stringToExecute = [stringToExecute stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	NSLog(@"executing: %@",stringToExecute);
	
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"sendreturn()\n";

	NSMutableString *commandSequence = [NSMutableString string];

	//loop through each char of our given string and send each char to wow. 
	//there will be a delay of 0.1 sec between each keypress. (this works best for me and my network. your mileage may vary)
	NSRange r = NSMakeRange(0, 1);
	NSString *subChar = nil;
	for (int i = 0; i < [stringToExecute length]; i++)
	{
		r.location = i;
		subChar = [stringToExecute substringWithRange: r];
		
		[commandSequence appendFormat:@"press_key (\"%@\",0.1)\n",subChar];		
	}
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	oastr = [oastr stringByAppendingString: commandSequence];
	oastr = [oastr stringByAppendingString: @"sendreturn()\n"]; //\n wird schon im string mitgesendet ueber telnet
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}


//sends the given string to the guild chat
//the delays work for me. you can try to make it type faster but it's likely that this will fail
- (void) gchatString: (NSString *) textToSay 
{
	textToSay = [textToSay stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	textToSay = [textToSay stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"sendreturn()\n";
	
	NSMutableString *commandSequence = [NSMutableString string];
	[commandSequence appendString:@"press_keycode (44)\ndelay 0.1\n"];
	[commandSequence appendString:@"press_keycode (5)\ndelay 0.1\n"];
	[commandSequence appendString:@"press_keycode (49)\ndelay 0.1\n"];

	NSRange r = NSMakeRange(0, 1);
	NSString *subChar = nil;
	for (int i = 0; i < [textToSay length]; i++)
	{
		r.location = i;
		subChar = [textToSay substringWithRange: r];
		
		[commandSequence appendFormat:@"press_key (\"%@\",0.1)\n",subChar];		
	}
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	oastr = [oastr stringByAppendingString: commandSequence];
	oastr = [oastr stringByAppendingString: myScript]; //\n wird schon im string mitgesendet ueber telnet
	
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
}

//sends the given string to the local /say chat
//the delays work for me. you can try to make it type faster but it's likely that this will fail
- (void) sayString: (NSString *) textToSay
{
	textToSay = [textToSay stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	textToSay = [textToSay stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"sendreturn()\n";
	

	NSMutableString *commandSequence = [NSMutableString string];
	[commandSequence appendString:@"press_keycode (44)\ndelay 0.1\n"]; // /
	[commandSequence appendString:@"press_keycode (1)\ndelay 0.1\n"]; // s
	[commandSequence appendString:@"press_keycode (49)\ndelay 0.1\n"]; // whitespace*/
	
	NSRange r = NSMakeRange(0, 1);
	NSString *subChar = nil;
	for (int i = 0; i < [textToSay length]; i++)
	{
		r.location = i;
		subChar = [textToSay substringWithRange: r];
		
		[commandSequence appendFormat:@"press_key (\"%@\",0.1)\n",subChar];		
	}
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	oastr = [oastr stringByAppendingString: commandSequence];
	oastr = [oastr stringByAppendingString: myScript];

	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
}

#pragma mark -
#pragma mark movement wrapper
//starts walking forward
- (void) startWalkingForward
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"press_keydown (\"w\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
}

//stops walking forward
- (void) stopWalkingForward
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"release_key (\"w\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);

	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];	
}


- (void) startTurningLeft
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"press_keydown (\"a\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
//	NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}

- (void) stopTurningLeft
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"release_key (\"a\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];	
	
}

- (void) startTurningRight
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"press_keydown (\"d\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}

- (void) stopTurningRight
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"release_key (\"d\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];	
	
}

- (void) startWalkingBack
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"press_keydown (\"s\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}

- (void) stopWalkingBack
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"release_key (\"s\")\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];	
	
}

- (void) jump
{
	NSString *myScriptBase = [NSString stringWithString: wowScriptLib];
	NSString *myScript = @"jump()\n";
	
	NSString *oastr = [myScriptBase stringByAppendingFormat: @"\n%@",myScript];
	
	//NSLog(@"scr = %@",oastr);
	
	NSDictionary *scriptError = [[NSDictionary alloc] init]; 
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:oastr]; 
	[appleScript executeAndReturnError:&scriptError];
	[appleScript release];
	[scriptError release];
	
}


#pragma mark -
#pragma mark ServerThread delegate
//our server received data from a client
//let's process this data and send wow some events
- (void) serverThread: (ServerThread *) aServer didReceiveData: (NSData *) dataReceived
{
	//we're sending utf8 strings over the net. so let's create a nsstring from the received data
	NSString *dataString = [[NSString alloc] initWithData: dataReceived encoding: NSUTF8StringEncoding];
	
	//uncomment this and your char will be /say'ing what he's doing ;)
	//[self sayString: [NSString stringWithFormat:@"received command string: %@", dataString]];
	
	
	/*
	 our protocol is fairly primitive. the syntax is:
	 <command>:<argument>
	 
	 let's parse our received data and forward it to wow
	 */
	
	// move forward.
	if ([dataString containsString: @"forward:1" ignoringCase: YES])
		[self startWalkingForward];
	if ([dataString containsString: @"forward:0" ignoringCase: YES])
		[self stopWalkingForward];
	
	//turn left
	if ([dataString containsString: @"left:1" ignoringCase: YES])
		[self startTurningLeft];
	if ([dataString containsString: @"left:0" ignoringCase: YES])
		[self stopTurningLeft];
	
	//walk back
	if ([dataString containsString: @"back:1" ignoringCase: YES])
		[self startWalkingBack];
	if ([dataString containsString: @"back:0" ignoringCase: YES])
		[self stopWalkingBack];
	
	//turn right
	if ([dataString containsString: @"right:1" ignoringCase: YES])
		[self startTurningRight];
	if ([dataString containsString: @"right:0" ignoringCase: YES])
		[self stopTurningRight];
	
	//wow's most used function ;)
	if ([dataString containsString: @"jump" ignoringCase: YES])
		[self jump];
	

	/* warning: ugly hardcoded indices will follow :( */
	
	//say a string in the say chat
	if ([dataString containsString: @"say:" ignoringCase: YES])
		[self sayString: [dataString substringFromIndex: 4]];
	
	//say something to the guild
	if ([dataString containsString: @"guild:" ignoringCase: YES])
		[self gchatString: [dataString substringFromIndex: 6]];
	
	//execute a given string. something like "execute:/lol" will let the char perform a /lol
	if ([dataString containsString: @"execute:" ignoringCase: YES])
		[self executeString: [dataString substringFromIndex: 8]];
	
	//press a given key (in this implementation the key will be pressed, hold for 0.1 sec and then released)
	if ([dataString containsString: @"presskey:" ignoringCase: YES])
		[self pressKey: [dataString substringFromIndex: 9]];
	
	//press a given keycode
	if ([dataString containsString: @"keycode:" ignoringCase: YES])
		[self pressKeyCode: [dataString substringFromIndex: 9]];
	
	//clean up the mess
	[dataString release];
}
@end
