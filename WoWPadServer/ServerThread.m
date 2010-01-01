// ServerThread.m
//
//  Created by jrk on 25/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

#import "ServerThread.h"
#import "SessionThread.h"

#import <fcntl.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <sys/time.h>
#import <sys/types.h>
#import <arpa/inet.h>
#import <unistd.h>


@implementation ServerThread
@synthesize delegate;

#pragma mark -
#pragma mark net service delegate
/**
 * Called when our bonjour service has been successfully published.
 * This method does nothing but output a log message telling us about the published service.
 **/
- (void)netServiceDidPublish:(NSNetService *)ns
{
	// Override me to do something here...
	
	NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
}

/**
 * Called if our bonjour service failed to publish itself.
 * This method does nothing but output a log message telling us about the published service.
 **/
- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
	NSLog(@"Error Dict: %@", errorDict);
}

#pragma mark -
#pragma mark server control 
/**
 listen on a port
 announce service on bonjour
 accept connections
*/
- (void) startServing
{
	srand(time(0));
	unsigned short currentPort = 0x7FFF + rand()%0x7FFF; //range between 32767 and 65534
	
	/* create a socket, bind it to our port and listen() */
	unsigned int socketFD =  socket(AF_INET, SOCK_STREAM, 0);
	if (socketFD < 0)
	{
		NSLog(@"error creating socket: %s",strerror(errno));
		return;
	}
	struct sockaddr_in localAddr;
    
	//set instant reuse of address to 1 so we can immediatly start serving after we stopped
	//well this does not matter as we're using random ports - just in case
	int on = 1;
    setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, (void*)&on, sizeof(on));
	
    // bind our socket to the address
    localAddr.sin_family = AF_INET;
    localAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    localAddr.sin_port = htons(currentPort);

	//bind our socket to the address:port
    if (bind(socketFD, (struct sockaddr*)&localAddr, sizeof(localAddr)) < 0)
	{
		NSLog(@"could not bind to port %i: %s",currentPort,strerror(errno));
		return;
	}
	
	//and start listeing
	listen(socketFD, 0x10);
	
	
	NSLog(@"listening with sock fd %i on port %i",socketFD,currentPort);

	//create our sessions tracker
	sessions = [[NSMutableArray alloc] init];
	
	//now we will create a fileHandle to do all the data transfer stuff
	//this is pretty convinient but also primitive. you want to reimplement this with real socket reading/writing :)
	//+ i don't know if nsfilehandle background listening is mainthread only 
	fileHandle = [[NSFileHandle alloc] initWithFileDescriptor: socketFD closeOnDealloc: YES];

	//we want to be notified when a new connection is made to the filehandle
	//so we can spawn a session
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self 
		   selector: @selector(newConnection:) 
			   name: NSFileHandleConnectionAcceptedNotification
			 object: nil];

	//listen for connections in the background
	[fileHandle acceptConnectionInBackgroundAndNotify];


	// Announce our great service over bonjour
	NSString *domain = @"local.";
	NSString *name = @"";
	NSString *type = @"_wowbridge._tcp.";
	
	netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:currentPort];
	[netService setDelegate:self];
	[netService publish];
}

/**
 kill all open sessions
 stop accepting new connections
 kill our socket
*/
- (void) stopServing
{
	NSLog(@"Server %@ stops serving!",self);
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[netService stop];
	[netService release];
	netService = nil;

	//let us kill all our sessions 
	for (SessionThread *session in sessions)
	{
		[session setDelegate: nil];
		[session release]; //the session will close all open connections in dealloc: (don't enable garbage collection or you will get some errors!)
	}
	[sessions release];
	sessions = nil;
	
	//close our file handle
	//we want explicitly to close the file as our fileHandle might be still retained by the runloop
	//and thus closeOnDealloc would be done in some unclear time in the future
	//if the socket is not closed we can't start serving again as the port is blocked
	//so we close here explicitly
	[fileHandle closeFile];
	[fileHandle release];
	fileHandle = nil;
}

#pragma mark -
#pragma mark filehandle notification handler
/**
 there's a new connection on our fileHandle
 let's spawn a new session and continue listening for connection requests
*/
- (void)newConnection:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSFileHandle *remoteFileHandle = [userInfo objectForKey: NSFileHandleNotificationFileHandleItem];
	
	//back to work!
	[fileHandle acceptConnectionInBackgroundAndNotify];
	
	//create a new Session and pass the new connection filehandle to it
	//again there's no real thread created. it's just a name that should give you a hint what you have to do
	//if you want something really usable ;)
	if (remoteFileHandle)
	{
		SessionThread *t = [[SessionThread alloc] init];
		[t setDelegate: self];
		[t startSession: remoteFileHandle];
		[sessions addObject: t];
	}
}

#pragma mark -
#pragma mark sessionthread delegate
/**
 one of our sessions received data. let's pass this data to our delegate.
*/
- (void) sessionThread: (SessionThread *) aSession didReceiveData: (NSData *) dataReceived
{
	if ([delegate respondsToSelector:@selector(serverThread:didReceiveData:)])
		[delegate serverThread: self didReceiveData: dataReceived];
}

/**
 one of our sessions did end. let's remove it from our tracker
 */
- (void) sessionThread:(SessionThread *)aSession sessionDidEndWithCode: (NSString *) code
{
	NSLog(@"session %@ did end",aSession);
	[sessions removeObject: aSession];
	[aSession release];
}


@end