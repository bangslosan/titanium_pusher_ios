/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiModule.h"

#import "PTPusher.h"
#import "PTPusherAPI.h"
#import "PTPusherDelegate.h"

#define PUSHER_LOG(format, args) \
  [ComPusherModule _logMessage:[NSString stringWithFormat:format, args]];

@interface ComPusherModule : TiModule <PTPusherDelegate>

@property (nonatomic,readonly) PTPusher *pusher;
@property (nonatomic,readonly) PTPusherAPI *pusherAPI;

+(void)_logMessage:(NSString *)args;

@end
