//
//  UnmarkPin.m
//  Where Are The Eyes
//
//  Created by Milo Trujillo on 10/31/16.
//  Copyright © 2016 Daylighting Society. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnmarkPin.h"
#import "Constants.h"
#import "Vibrate.h"

@implementation UnmarkPin

+ (id)unmarkPinAt:(Coord*)c withUsername:(NSString*)username
{
	NSLog(@"Unmarking pin at lat:%f lon:%f with username %@", c.latitude, c.longitude, username);
	[Vibrate pulse]; // Let the user know their unmark request has been noticed
	
	// Set the URL and create an HTTP request
	NSString* unmarkUrl = [kEyesURL stringByAppendingString:@"/unmarkPin"];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:unmarkUrl]];
	
	// Specify that it will be a POST request
	[request setHTTPMethod:@"POST"];
	
	// Setting a timeout
	[request setTimeoutInterval:kPostTimeout];
	
	// Convert your data and set your request's HTTPBody property
	NSString* data = [NSString stringWithFormat:@"username=%@&latitude=%f&longitude=%f", username, c.latitude, c.longitude];
	
	// Set the size of the request
	[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-length"];
	
	// Now set its contents
	NSData* requestBodyData = [data dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:requestBodyData];
	
	// Send the request, read the response the server sends
	NSData* returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	NSString* response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
	
	NSLog(@"Response from unmarking pin: %@", response);
	[self parseResponse:response];
	
	return nil;
}

// Reads the server response, and on an error creates an alert box on the main thread.
+ (void)parseResponse:(NSString*)response
{
	// In an error we dispatch a message to the main ViewController, and it displays the errors on the main thread.
	if( [response isEqualToString:@"ERROR: Invalid login\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"InvalidLogin" object:self];
	else if( [response isEqualToString:@"ERROR: Geoip out of range\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CameraOutOfRange" object:self];
	else if( [response isEqualToString:@"ERROR: Rate limit exceeded\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RateLimitError" object:self];
	else if( [response isEqualToString:@"ERROR: Permission denied\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PermissionDeniedUnmarkingCamera" object:self];
	else if( [response hasPrefix:@"ERROR:"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorUnmarkingCamera" object:self];
	else
		NSLog(@"I got an unmark pin response I don't understand: %@", response);
}

@end
