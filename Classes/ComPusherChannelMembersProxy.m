/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUtils.h"
#import "ComPusherChannelMembersProxy.h"

@implementation ComPusherChannelMembersProxy

-(void)_configureWithChannel:(PTPusherPresenceChannel *)presenceChannel {
	RELEASE_AND_REPLACE(_presenceChannel, presenceChannel);
}

-(id)count {
	return @([_presenceChannel memberCount]);
}

-(void)each:(id)args {
	KrollCallback *callback = [args objectAtIndex:0];
	ENSURE_TYPE(callback, KrollCallback);
	
	[[_presenceChannel memberIDs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSDictionary *info = [_presenceChannel infoForMemberWithID:(NSString*)obj];
		
		NSDictionary *data = @{ @"id" : obj, @"info" : info };
		[callback call:@[data] thisObject:self];
	}];
}

-(id)getMember:(id)args {
	NSString *userID = [TiUtils stringValue:[args objectAtIndex:0]];
	
	NSDictionary *info = [_presenceChannel infoForMemberWithID:userID];
	if(info) {
		return @{ @"id" : userID, @"info" : info };
	} else {
		return nil;
	}
}

@end