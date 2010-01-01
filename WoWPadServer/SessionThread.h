// SessionThread.h
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import <Cocoa/Cocoa.h>

//the delegate protocol we'd like our delegate to implement
@class SessionThread; //stupid forward decleration.
@protocol SessionThreadDelegate
- (void) sessionThread: (SessionThread *) aSession didReceiveData: (NSData *) dataReceived;
- (void) sessionThread: (SessionThread *) aSession sessionDidEndWithCode: (NSString *) code;
@end

/*
 just a simple object that will receive data over a NSFileHandle
 and pass it to the delegate object
 */
@interface SessionThread : NSObject 
{
	NSFileHandle *remoteFilehandle;					//we will receive data over this filehandle
	id <SessionThreadDelegate,NSObject> delegate;
}

@property (readwrite, retain) NSFileHandle *remoteFilehandle;
@property (readwrite, assign) id delegate;

- (void) startSession: (NSFileHandle *) theFilehandle;
- (void) stopSession;

@end

