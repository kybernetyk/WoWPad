// ServerThread.h
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import <Cocoa/Cocoa.h>
#import "SessionThread.h"


#pragma mark delegate protocol
//the delegate protocol we'd like our delegate to implement

@class ServerThread; //stupid forward decleration. we sould move the protocol declaration to its own file

@protocol ServerThreadDelegate
- (void) serverThread: (ServerThread *) aServer didReceiveData: (NSData *) dataReceived;
@end

#pragma mark -
#pragma mark interface
/**
 this is a primitive server that will listen on a local port for data
 and will forward the received data to its delegate.
 
 NOTICE: this is not a thread in the current implementation. but you should make it a thread if you
 want a really usable application. (the network might block and this will stall our app!)
 
 if you want to make it multithreaded you'll have to remove the NSFileHandle stuff and implement
 your own thread safe socket communications. (I suspect NSFileHandle's asynchronous data transfer is mainthread only)
 
 the server will announce its presence over bonjour
 */
@interface ServerThread : NSObject <NSNetServiceDelegate, SessionThreadDelegate>
{
	NSFileHandle *fileHandle;							//we will be receiving data through this filehandle
	NSNetService *netService;							//our bonjour net service
	NSMutableArray *sessions;							//here we keep track of all connected clients

	id <ServerThreadDelegate, NSObject> delegate;		//our delegate to pass received data to
}

@property (readwrite, assign) id delegate;

#pragma mark -
#pragma mark server control
- (void) startServing;
- (void) stopServing;

@end
