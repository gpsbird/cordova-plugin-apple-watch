//
//  AppleWatch.m
//  Copyright (c) 2015 Lee Crossley - http://ilee.co.uk
//

#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "AppleWatch.h"
#import "MMWormhole.h"

@interface AppleWatch ()

@property (nonatomic, strong) MMWormhole* wormhole;

@end

@implementation AppleWatch

- (void) init:(CDVInvokedUrlCommand*)command;
{
    CDVPluginResult* pluginResult = nil;

    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *appGroupId = [args objectForKey:@"appGroupId"];

    if ([appGroupId length] == 0)
    {
        appGroupId = [NSString stringWithFormat:@"group.%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    }

    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:appGroupId optionalDirectory:nil];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:appGroupId];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) registerNotifications:(CDVInvokedUrlCommand*)command;
{
    CDVPluginResult* pluginResult = nil;

    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];

    if ([[UIApplication sharedApplication] hasPermissionToScheduleLocalNotifications])
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(true)];
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:(false)];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) sendMessage:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];

    NSString *queueName = [args objectForKey:@"queueName"];
    NSString *message = [args objectForKey:@"message"];

    [self.wormhole passMessageObject:message identifier:queueName];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) sendNotification:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];

    UILocalNotification *localNotification = [[UILocalNotification alloc] init];

    localNotification.alertTitle = [args objectForKey:@"title"];
    localNotification.alertBody = [args objectForKey:@"body"];
    localNotification.applicationIconBadgeNumber = [[args objectForKey:@"badge"] intValue];

    localNotification.fireDate = [NSDate date];
    notification.soundName = UILocalNotificationDefaultSoundName;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) addListener:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *queueName = [args objectForKey:@"queueName"];

    [self.wormhole listenForMessageWithIdentifier:queueName listener:^(id message) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
        [pluginResult setKeepCallbackAsBool:YES];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) removeListener:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *queueName = [args objectForKey:@"queueName"];

    [self.wormhole stopListeningForMessageWithIdentifier:queueName];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) purgeQueue:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *queueName = [args objectForKey:@"queueName"];

    [self.wormhole clearMessageContentsForIdentifier:queueName];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) purgeAllQueues:(CDVInvokedUrlCommand*)command;
{
    [self.wormhole clearAllMessageContents];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

@end
