//
//  Created by jrk on 26/10/09.
//
// Copyright (c) 2009-2010, Jaroslaw Szpilewski (jaroslaw.szpilewski@gmail.com)
//
// LICENSED UNDER THE BSD LICENSE (with attribution)
// SEE LICENSE FILE

/* this is the general programm flow so that you get an idea what's happening here:
 
	1. - viewDidLoad:
			We create our NetServiceBrowser and start looking for appropriate servers that
			offer the wowbridge service.
 
	2. - netServiceBrowser:didFindService:
			on finding a service we ask the service to resolve its address and port
 
	3. - netServiceDidResolveAddress:
			After the service did resolve it's address we will create a human readable address
			and initiate a connection.
		
	4. - connectToServer:port:
			We will connect to the given server:port. After that we're ready to react to the 
			user's inputs and dispatch them to our server. (this is where all the IBAction stuff comes in)

	5. WoWRemotePrototypeAppDelegate.m - applicationWillTerminate:
			If the user decides to quit the app we will send a "close" command to the server and disconnect.
 
 
	error handling:
			Before sending a string to the server we check if the clientSocketFileHandle exists. If it doesn't
			we won't send anything. this check is done in -sendStringToServer:
 
			If the server vanished (eg the server process is terminated and the service is deanounced from bonjour)
			our bonjour delegate method -netServiceBrowser:didRemoveService: will get called and we there we will call
			stopServer: (setting the clientSocketFileHandle to nil, so we won't send anything to the server)
 */

#import "WoWPadClientViewController.h"

#import <fcntl.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <sys/time.h>
#import <sys/types.h>
#import <arpa/inet.h>
#import <unistd.h>

#pragma mark private category
@interface WoWPadClientViewController (private)

@end

#pragma mark -
#pragma mark implementation
@implementation WoWPadClientViewController
- (void)viewDidLoad 
{
	NSLog(@"view did load!");
	//let's start with the first view to display
	[[self view] addSubview: view1];
	currentSubView = view1;
	
    [super viewDidLoad];
}


//we want to disable interface rotation and only enable landscape mode
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
    [super dealloc];
}


/**
 action called from the pageview control
 
 here we will show the appropriate view for the chosen page
 */
- (IBAction) pageChanged: (id) sender
{
	NSInteger page = [sender currentPage];
	UIView *newSubview = nil;
	
	switch (page) 
	{
		case 0:
			newSubview = view1;
			break;
		case 1:
			newSubview = view2;
			break;
		case 2:
			newSubview = view3;
			break;
		default:
			return;
			break;
	}
	
	[currentSubView removeFromSuperview];
	[[self view] addSubview: newSubview];
	currentSubView = newSubview;
}


#pragma mark -
#pragma mark wasd view (view1) stuff
- (IBAction) startForward: (id) sender
{
	[self sendStringToServer: @"forward:1"];
}
- (IBAction) stopForward: (id) sender
{
	[self sendStringToServer: @"forward:0"];	
}

- (IBAction) startRight: (id) sender
{
	[self sendStringToServer: @"right:1"];
}
- (IBAction) stopRight: (id) sender
{
	[self sendStringToServer: @"right:0"];	
}

- (IBAction) startBack: (id) sender
{
	[self sendStringToServer: @"back:1"];	
}
- (IBAction) stopBack: (id) sender
{
	[self sendStringToServer: @"back:0"];	
}

- (IBAction) startLeft: (id) sender
{
	[self sendStringToServer: @"left:1"];	
}
- (IBAction) stopLeft: (id) sender
{
	[self sendStringToServer: @"left:0"];	
}

- (IBAction) jump: (id) sender
{
	[self sendStringToServer: @"jump"];
}

- (IBAction) sendTab: (id) sender
{
	[self sendStringToServer: @"presskey:\t"];	
}

#pragma mark -
#pragma mark view2 stuff
- (IBAction) sendF: (id) sender
{
	[self sendStringToServer: @"presskey:f"];	
}

- (IBAction) sendR: (id) sender
{
	[self sendStringToServer: @"presskey:r"];
}

- (IBAction) sendT: (id) sender
{
	[self sendStringToServer: @"presskey:t"];	
}

#pragma mark -
#pragma mark chat view (view3) stuff
- (IBAction) sendTextToRaw: (id) sender
{
	[chatTextField resignFirstResponder];			//let's hide the keypad
	NSString *text = [chatTextField text];
	
	[self sendStringToServer: [NSString stringWithFormat: @"execute:%@",text]];
}

- (IBAction) sendTextToSay: (id) sender
{
	[chatTextField resignFirstResponder];
	NSString *text = [chatTextField text];
	
	[self sendStringToServer: [NSString stringWithFormat: @"say:%@",text]];
}

- (IBAction) sendTextToGuild: (id) sender
{
	[chatTextField resignFirstResponder];
	NSString *text = [chatTextField text];
	
	[self sendStringToServer: [NSString stringWithFormat: @"guild:%@",text]];
	
}

//hide iphone keypad on "return"-tap
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	//here you could perform a default action. like send to say chat or something. it's up to you :)
	return YES;
}


#pragma mark -
#pragma mark server/client communication
/**
 this will start up our net service browser and look for wowbridge services in the local network.
 
 if a service is found NSNetServiceBrowser will call us back (see the net service browser delegate section at the bottom of this file).
*/
- (void)startClient
{
	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	[netServiceBrowser setDelegate: self];
	
	[netServiceBrowser searchForServicesOfType:@"_wowbridge._tcp." inDomain: @"local."];
}

/**
 this will disconnect us from our server.
*/
- (void) stopClient
{
	//[self sendString: @"close\n"];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[clientSocketFileHandle closeFile];
	[clientSocketFileHandle release];
	clientSocketFileHandle = nil;
}


/**
 initiates a connection to the given server on the given port. 
 the server-string may contain either an IP or a computer name (like imac.local)
 
 this method will be called from our NSNetServiceBrowser delegate callback
*/
- (void) connectToServer: (NSString *) server port: (unsigned short) port
{
	NSLog(@"connecting ...");

	//crate a socket
	int socketfd = -1;
    if ( (socketfd = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
	{
	   NSLog (@"could not create socket: %s",strerror(errno));
		return;
	}
	
	//get a the host network address from our server name
	struct hostent* remoteHost;
    struct sockaddr_in remoteAddr;
    if ( (remoteHost = gethostbyname([server cStringUsingEncoding: [NSString defaultCStringEncoding]])) == NULL )
	{
		NSLog (@"host %@ not found: %s",server, strerror(errno));
		return;
	}

    bzero((char*)&remoteAddr, sizeof(remoteAddr));
    remoteAddr.sin_family = AF_INET;
    bcopy((char*)remoteHost->h_addr, (char*)&remoteAddr.sin_addr.s_addr, remoteHost->h_length);
    remoteAddr.sin_port = htons(port);
	
    // connect to our host
    if ( (connect(socketfd, (struct sockaddr*)&remoteAddr, sizeof(remoteAddr)) < 0) )
	{
		NSLog (@"connection failed: %s",strerror(errno));
		return;
	}
	

	//create a NSFileHandle with our socket connection
	clientSocketFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:socketfd];
	if (!clientSocketFileHandle)
	{
		NSLog(@"could not create a NSFileHandle with the socketfd %i",socketfd);
		exit(2);
	}
	
	//register ourself to updates from the filehandle
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(processServerData:)
			   name: NSFileHandleReadCompletionNotification
			 object: clientSocketFileHandle];
	
	NSLog(@"connection ok. listening now!");
	
	//start listening for data in the background
	[clientSocketFileHandle readInBackgroundAndNotify];
}

/**
 this will send a given string to the server we're connected to.
 
 for communication the clientSocketFileHandle reference is used. you want to use proper sockets for this.
 using a NSFileHandle for network communication works but it's not the intended way to do.
*/
- (void) sendStringToServer: (NSString *) stringToSend
{
	if (!clientSocketFileHandle)
	{
		NSLog(@"error sending. not connected!");
		return;
	}

	NSLog(@"sending string: %@",stringToSend);
	NSData *data = [stringToSend dataUsingEncoding: NSUTF8StringEncoding];
	[clientSocketFileHandle writeData: data];
}

/**
 This method is invoked in response to NSFileHandleReadCompletionNotification
 
 Here we process the server's answer. (well we just NSLog it - the server will send us an 'ok\n' if he has accepted our command)
*/
- (void) processServerData:(NSNotification *)note
{
	NSData *data = [[note userInfo]	objectForKey:NSFileHandleNotificationDataItem];

	if ([data length] > 0)
		NSLog(@"server answered: %@", [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease]);
	
	// Tell file handle to continue waiting for data
	[clientSocketFileHandle readInBackgroundAndNotify];
}


#pragma mark Bonjour Browser delegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing
{
	NSLog(@"bonjour browser didFindDomain: %@",domainName);
}

/**
 the browser found a service. let's resolve the service. (if the resolution succeeds we will connect to the server offering this service) 
*/
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	NSLog(@"(%i) bonjour browser didFindService: %@\nresolving",moreServicesComing, [netService name]);
	
	[netService setDelegate: self];
	[netService retain];				//the service we get from the browser is autoreleased and would be removed in the next pool drain
										//thus we have to retain it here and release it later when the service is resolved (or if it fails to resolve)

	[netService resolveWithTimeout: 25.0f];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo
{
	NSLog(@"bonjour browser didNotSearch: %@",errorInfo);
}

/**
 if our server vanishes this will disconnect us from it. as soon as the server comes back and restarts announcing its
 service over bonjour we will be reconnected. 
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	NSLog(@"bonjour browser service removed %@",[netService name]);
	[self stopClient];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing
{
	NSLog(@"bonjour browser domain removed %@",domainName);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	NSLog(@"bonjour browser stopped search");
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	NSLog(@"bonjour browser will search");
}

#pragma mark Bonjour service delegate
/**
 we will get a sockaddr struct from the netservice object. here we will convert it into a human readable format
 and connect to the server. (our connect method expects a human radable address - though we could use the sockaddr struct
 to connect without converting it first)
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog(@"resolved service %@ (%i)",[sender name],[sender retainCount]);
	
	//let's get a human readable adress for the service
	NSData *d = [[sender addresses] objectAtIndex: 0];
	struct sockaddr_in *a = (struct sockaddr_in *)[d bytes];
	char node[512];
	memset(node,0x00,512);
	
	char service[512];
	memset(service,0x00,512);
	getnameinfo((const struct sockaddr*)a, sizeof(struct sockaddr_in), (char *)&node, 512, (char *)&service, 512, 0);
	
	unsigned short serverPort = ntohs(a->sin_port);
	NSString *serverAdress = [NSString stringWithCString: node];
	
	NSLog(@"server: %@",serverAdress);
	NSLog(@"port: %i",serverPort);
	
	//release our previously retained service
	[sender release];
	
	[self connectToServer: serverAdress port: serverPort];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLog(@"service did not resolve: %@",errorDict);
	
	//release our previously retained service
	[sender release];
}


@end