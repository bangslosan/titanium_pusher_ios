/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "ComPusherModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

#import "PTPusherEvent.h"
#import "PTPusherChannel.h"
#import "Reachability.h"

#import "ComPusherChannelProxy.h"
#import "KrollBridge.h"

static ComPusherModule *_instance;

@interface ComPusherModule ()

@property (nonatomic,retain) NSString *channel_auth_endpoint;
@property (nonatomic,retain) KrollCallback *log;

@end

@implementation ComPusherModule {
	BOOL reconnectAutomaticaly;
	NSDictionary *authParams;
	NSMutableDictionary *bindings;
  NSMutableDictionary *channels;
}

@synthesize pusher, pusherAPI;
@synthesize channel_auth_endpoint=_channel_auth_endpoint;
@synthesize log=_log;

#pragma mark Internal
-(id)init {
  if(self = [super init]) {
    channels = [[NSMutableDictionary alloc] init];
		bindings = [[NSMutableDictionary alloc] init];
		_channel_auth_endpoint = [@"/pusher/auth" retain];
  }
  
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  RELEASE_TO_NIL(pusher);
  RELEASE_TO_NIL(pusherAPI);
  RELEASE_TO_NIL(channels);
	RELEASE_TO_NIL(_channel_auth_endpoint);
  [super dealloc];
}

// this is generated for your module, please do not change it
-(id)moduleGUID {
	return @"a1418c5f-8015-41c2-8229-51bd7148436d";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId {
	return @"com.pusher.pusher";
}

+(void)_logMessage:(NSString *)message {
	if(_instance && _instance.log) {
		[_instance.log call:@[message] thisObject:_instance];
	} else {
		NSLog(message);
	}
}

#pragma mark Lifecycle

-(void)startup {
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	_instance = self;
	PUSHER_LOG(@"[INFO] %@ loaded", self);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if([keyPath isEqualToString:@"connection.state"]) {
		PTPusherConnectionState old = [[change valueForKey:NSKeyValueChangeOldKey] integerValue];
		PTPusherConnectionState new = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
		
		[self fireEvent:[self _stringFromState:new] withObject:nil];
		[self fireEvent:@"status_change" withObject:@{ @"previous" : [self _stringFromState:old], @"current" : [self _stringFromState:new] }];
	}
	
	if([keyPath isEqualToString:@"channel_auth_endpoint"]) {
		NSString *endpoint = [change valueForKey:NSKeyValueChangeNewKey];
		
		if(pusher)
			pusher.authorizationURL = [NSURL URLWithString:endpoint];
	}
}

-(void)setup:(id)args {
	enum Arguments {
		kArgApplicationKey = 0,
		kArgCount,
		kArgOptions = kArgCount
	};
	
	ENSURE_ARG_COUNT(args, kArgCount);
  
  NSString *key = [TiUtils stringValue:[args objectAtIndex:kArgApplicationKey]];
	
	NSDictionary *options;
	if([args count] > kArgCount)
		options = [args objectAtIndex:kArgOptions];
	
  reconnectAutomaticaly = [TiUtils boolValue:@"reconnectAutomaticaly" properties:options def:YES];
  NSTimeInterval reconnectDelay = [TiUtils intValue:@"reconnectDelay" properties:options def:5];
	BOOL encrypted = [TiUtils boolValue:@"encrypted" properties:options def:YES];
	
  NSString *appID = [TiUtils stringValue:@"appID" properties:options];
  NSString *secret = [TiUtils stringValue:@"secret" properties:options];
	RELEASE_AND_REPLACE(authParams, [options valueForKey:@"auth"]);
	
	PUSHER_LOG(@"Setupping", nil);
  
	dispatch_sync(dispatch_get_main_queue(), ^{
		if(pusher) {
			[pusher disconnect];
			
			RELEASE_TO_NIL(pusher);
			[[NSNotificationCenter defaultCenter] removeObserver:self];
		}
		
		pusher = [[PTPusher pusherWithKey:key connectAutomatically:NO encrypted:encrypted] retain];
		pusher.reconnectDelay = reconnectDelay;
		pusher.delegate = self;
		[pusher addObserver:self forKeyPath:@"connection.state" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
		[self addObserver:self forKeyPath:@"channel_auth_endpoint" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
		
		if(_channel_auth_endpoint)
			pusher.authorizationURL = [NSURL URLWithString:_channel_auth_endpoint];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePusherEvent:) name:PTPusherEventReceivedNotification object:pusher];
		
		if(appID && secret) {
			RELEASE_TO_NIL(pusherAPI);
			
			pusherAPI = [[PTPusherAPI alloc] initWithKey:key appID:appID secretKey:secret];
		}
	});
}

-(void)connect:(id)args {
	pusher.reconnectAutomatically = reconnectAutomaticaly;
  [pusher connect];
}

-(void)disconnect:(id)args {
	pusher.reconnectAutomatically = NO;
  [pusher disconnect];
	
	RELEASE_AND_REPLACE(channels, [[NSMutableDictionary alloc] init]);
}

-(id)subscribe:(id)args {
  ENSURE_SINGLE_ARG(args, NSString)
  NSString *channel = args;
  
  ComPusherChannelProxy *channel_object = [[[ComPusherChannelProxy alloc] _initWithPageContext:[self pageContext]] autorelease];
  [channel_object _configureWithPusher:self andChannel:channel];
  [channel_object _subscribe];
  
  if(![channels valueForKey:channel])
    [channels setValue:[[NSMutableSet alloc] init] forKey:channel];
  
  [[channels valueForKey:channel] addObject:channel_object];
  
  return channel_object;
}

-(void)unsubscribe:(id)args {
  ENSURE_SINGLE_ARG(args, NSString)
  NSString *channelName = args;
	
	PTPusherChannel *channel = [pusher channelNamed:channelName];
	
	if(channel) {
		[channel unsubscribe];
		[channels removeObjectForKey:channel];
	}
}

-(void)sendEvent:(id)args {
  ENSURE_UI_THREAD_1_ARG(args)
  
  enum Args {
    kArgName = 0,
    kArgChannel,
    kArgData,
    kArgCount
  };
  
  ENSURE_ARG_COUNT(args, kArgCount);
  NSString *eventName = [TiUtils stringValue:[args objectAtIndex:kArgName]];
  NSString *channelName = [TiUtils stringValue:[args objectAtIndex:kArgChannel]];
  NSDictionary *data  = [args objectAtIndex:kArgData];
  
  if(pusherAPI)
		[pusherAPI triggerEvent:eventName onChannel:channelName data:data socketID:pusher.connection.socketID];
  else
    [self throwException:@"PusherAPI is not initialized" subreason:@"Please call the setup method with both the appID and the secret" location:CODELOCATION];
}

#pragma mark - Notifications

- (void)handlePusherEvent:(NSNotification *)note {
  PTPusherEvent *pusher_event = [note.userInfo objectForKey:PTPusherEventUserInfoKey];
  
	[[channels valueForKey:pusher_event.channel] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ComPusherChannelProxy *proxy = (ComPusherChannelProxy *)obj;
    [proxy fireEvent:@"bind_all" withObject:pusher_event.data];
	}];
  
	[self fireEvent:@"bind_all" withObject:pusher_event.data];
}

-(void)bind:(id)args {
	NSString *type = [args objectAtIndex:0];
	KrollCallback* listener = [[args objectAtIndex:1] retain];
	ENSURE_TYPE(listener,KrollCallback);
	
	TiObjectRef callbackFunction = [listener function];
	
	// First make sure that the binding doesn't exist already
	NSMutableDictionary *map = [bindings objectForKey:type];
	if(map) {
		TiObjectRef callbackFunction = [listener function];
		NSValue *callbackValue = [NSValue valueWithPointer:callbackFunction];
		PTPusherEventBinding *binding = [map objectForKey:callbackValue];
		
		if(binding)
			// Binding already exists, ignore!
			return;
	}
	
	PTPusherEventBinding *binding = [pusher bindToEventNamed:type handleWithBlock:^(PTPusherEvent *pusher_event) {
		[[listener context] invokeBlockOnThread:^{
			[listener call:@[pusher_event.data] thisObject:self];
		}];
	}];
	
	NSValue *callbackValue = [NSValue valueWithPointer:callbackFunction];
	map = [bindings objectForKey:type];
	if(!map)
		map = [[[NSMutableDictionary alloc] init] autorelease];
	
	[map setObject:binding forKey:callbackValue];
	[bindings setObject:map forKey:type];
}

-(void)unbind:(id)args {
	NSString *type = [args objectAtIndex:0];
	KrollCallback* listener = [args objectAtIndex:1];
	ENSURE_TYPE(listener,KrollCallback);
	
	NSMutableDictionary *map = [bindings objectForKey:type];
	if(map) {
		TiObjectRef callbackFunction = [listener function];
		NSValue *callbackValue = [NSValue valueWithPointer:callbackFunction];
		PTPusherEventBinding *binding = [map objectForKey:callbackValue];
		
		if(binding) {
			[pusher removeBinding:binding];
			[map removeObjectForKey:callbackValue];
			[bindings setObject:map forKey:type];
		}
	}
}

-(void)fireEvent:(NSString *)type withObject:(id)data {
	NSDictionary *map = [bindings objectForKey:type];
	[map enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		TiObjectRef callbackFunction = [(NSValue *)key pointerValue];
		KrollCallback *callback = [KrollObject toID:[self.executionContext krollContext] value:callbackFunction];
		
		NSArray *payload = @[];
		if(data) { payload = @[data]; }
		
		[[callback context] invokeBlockOnThread:^{
			[callback call:payload thisObject:self];
		}];
	}];
}

-(void)_bindEvent:(NSString*)type {
  [pusher bindToEventNamed:type target:self action:@selector(handleNewEvent:)];
}

-(void)handleNewEvent:(PTPusherEvent *)event {
  if([self _hasListeners:event.name]) {
    [self fireEvent:event.name withObject:event.data];
  }
}

-(void)pusher:(PTPusher *)p connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error {
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	
	if([reachability currentReachabilityStatus] == NotReachable) {
		// change status to unavailable
		[self fireEvent:@"unavailable" withObject:nil];
		[self fireEvent:@"status_change" withObject:@{ @"previous" : [self _stringFromState:pusher.connection.state], @"current" : @"unavailable" }];
		
		// there is no point in trying to reconnect at this point
		pusher.reconnectAutomatically = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
																						 selector:@selector(reachabilityChanged:)
																								 name:kReachabilityChangedNotification
																							 object:reachability];
		[reachability startNotifier];
	}
}

-(void)pusher:(PTPusher *)pusher connectionWillReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay {
	[self fireEvent:@"connecting_in" withObject:@(delay)];
}

-(void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {
	[[channels valueForKey:channel.name] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ComPusherChannelProxy *channelProxy = (ComPusherChannelProxy *)obj;
		
		[channelProxy fireEvent:@"pusher:subscription_succeeded" withObject:nil];
	}];
}

-(void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error {
	[[channels valueForKey:channel.name] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ComPusherChannelProxy *channelProxy = (ComPusherChannelProxy *)obj;
		
		[channelProxy fireEvent:@"pusher:subscription_error" withObject:@(error.code)];
	}];
}

-(void)pusher:(PTPusher *)pusher willAuthorizeChannelWithRequest:(NSMutableURLRequest *)request {
	if(authParams && [authParams objectForKey:@"headers"]) {
		NSDictionary *params = [authParams valueForKey:@"headers"];
		[params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSString *authKey = (NSString *)key;
			NSString *authValue = (NSString *)obj;
			
			[request setValue:authValue forHTTPHeaderField:authKey];
		}];
	}
}

#pragma mark - Rechability

-(void)reachabilityChanged:(NSNotification *)note {
	Reachability *reachability = note.object;
	
	if([reachability currentReachabilityStatus] != NotReachable) {
		// We seem to have some kind of reachability, so try again
		
		if(reconnectAutomaticaly) {
			[pusher connect];
			
			// we can stop observing reachability changes now
			[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:reachability];
			[reachability stopNotifier];
			
			// re-enable auto-reconnect
			pusher.reconnectAutomatically = YES;
		}
	}
}

#pragma mark - Properties

-(id)connection {
	return self;
}

-(id)state {
	return [self _stringFromState:pusher.connection.state];
}

#pragma mark - Private Methods
-(NSString *)_stringFromState:(PTPusherConnectionState)state {
	switch(state) {
		case PTPusherConnectionClosed:
			return @"disconnected";
		case PTPusherConnectionOpening:
			return @"connecting";
		case PTPusherConnectionOpenHandshakeReceived:
			return @"connected";
		case PTPusherConnectionOpenAwaitingHandshake:
			return @"connecting";
		case PTPusherConnectionClosing:
			return @"initialized";
	}
}

@end
