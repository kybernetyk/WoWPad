// SessionThread.m
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import "SessionThread.h"
#import "NSString+Search.h"

@implementation SessionThread
@synthesize delegate;
@synthesize remoteFilehandle;


/**
 register for the filehandle's readcompletion notification and setup background data reading
 */
- (void) startSession: (NSFileHandle *) theFilehandle
{
	NSLog(@"starting new session %@ with filehandle %@",self,theFilehandle);
	
	[self setRemoteFilehandle: theFilehandle];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector: @selector(readData:)
			   name: NSFileHandleReadCompletionNotification
			 object: remoteFilehandle];
	
	[remoteFilehandle readInBackgroundAndNotify];
}


/**
 stop our session
 
 well here happens really nothing as the session termination is found in dealloc
 our delegate (which should be our owning object) will send us a release message
 so dealloc will be called.
*/
- (void) stopSession
{
	NSLog(@"%@ stopping session!", self);
//	[self autorelease];
	//we will be relesed by our owning object
}

/**
 here happens too much important stuff in dealloc
 so enabling garbage collection is a really bad idea
 if you chose to do so you'll have to move the stuff into -finalize:
 or redesign my sloppy work :)
*/
- (void) dealloc
{
	close ([remoteFilehandle fileDescriptor]); //close the filehandle and its socket 
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[remoteFilehandle release];
	remoteFilehandle = nil;
	NSLog(@"%@ Session dealloc!",self);
	[super dealloc];
}

/**
 reads the data. 
 if it contains the word "close" the connection is terminated.
 otherwise the data is passed to our delegate.
 
 NOTICE: this "close"-handling is really bad design in here. the protocol parser should
 do this. but i was too lazy (storing/passing session id and stuff) ;)
*/
- (void) readData: (NSNotification *) notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSData *remoteData = [userInfo objectForKey: NSFileHandleNotificationDataItem];

	//if we ever get invalid data, we should kill the connection
	//for example: data length 0 happens if we kill our iphone client thorugh xcode's run->stop menu
	//too long data: bad guys ;)
	//data == nil never happened to me but who knows.
	if (!remoteData || [remoteData length] == 0 || [remoteData length] > 1024)
	{
		NSLog(@"data %@ (located at 0x%x) was nil or of invalid length (0 || > 1024)!",remoteData, remoteData);
		[self stopSession];
		return;
	}
	
	NSString *dataString = [[NSString alloc] initWithData: remoteData encoding: NSUTF8StringEncoding];
	NSLog(@"%@ received data \"%@\" with length %i.",self,dataString,[remoteData length]);
	
	//end session if we get a "close"
	//notice: this is a bad thing to do here. we should not parse the application protocol in the transportation layer.
	//but i'm lazy. also there's a bug: if you'd like to say "i'm close to the water" in wow ... well you can imagine :)
	if ([dataString containsString: @"close" ignoringCase: YES])
	{	
		[dataString release];
		[self stopSession];
	
		//message our delegate of our death :(
		if ([delegate respondsToSelector:@selector(sessionThread:sessionDidEndWithCode:)])
			[delegate sessionThread: self sessionDidEndWithCode: @"close"];
		return;
	}

	//send our delegate the data
	if ([delegate respondsToSelector:@selector(sessionThread:didReceiveData:)])
		[delegate sessionThread: self didReceiveData: remoteData];
	[dataString release];

	//send back an "ok\n" to let our client know that we accepted his command and will execute it
	[remoteFilehandle writeData: [@"ok\n" dataUsingEncoding: NSUTF8StringEncoding]]; 

	
	//continue reading data in background
	[remoteFilehandle readInBackgroundAndNotify];
}

@end
