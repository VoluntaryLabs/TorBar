//
//  NetworkMonitor.m
//  TorBar
//
//  Created by Steve Dekorte on 9/6/14.
//
//

#import "NetworkMonitor.h"
#import <SystemConfiguration/SystemConfiguration.h>
//#import <SystemConfiguration/SCNetworkReachability.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation NetworkMonitor

- (id)init
{
    self = [super init];
    [self start];
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void)start
{
    if (!_ssidTimer)
    {
        _ssidTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(fetchSSIDInfo)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)stop
{
    if (_ssidTimer)
    {
        [_ssidTimer invalidate];
        _ssidTimer = nil;
    }
}

- (void)fetchSSIDInfo
{
    NSTask *task = [[NSTask alloc] init];
    
    [task setCurrentDirectoryPath:@"/"];
    [task setLaunchPath:@"/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"];
    [task setArguments:@[@"-I"]];
    
    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    
    [task launch];
    [task waitUntilExit];
    
    NSFileHandle *read = [out fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    //NSLog(@"output: '%@'", stringRead);

    // find SSID
    NSArray *lines = [stringRead componentsSeparatedByString:@"\n"];
    NSString *prefix = @"           SSID: ";
    NSString *ssid = nil;
    
    for (NSString *line in lines)
    {
        if ([line hasPrefix:prefix])
        {
            ssid = [line substringWithRange:NSMakeRange(prefix.length, line.length - prefix.length)];
            break;
        }
    }
    
    [self setSSID:ssid];
}

- (void)setSSID:(NSString *)newSsid
{
    // update if it's changed
    if (
        _ssid != newSsid
        && ![_ssid isEqualToString:newSsid]
        )
    {
        NSLog(@"changedNetwork to '%@'", newSsid);
        
        _ssid = newSsid;
        [[NSNotificationCenter defaultCenter] postNotificationName:NetworkMonitorChangeNotification
                                                            object:self
                                                          userInfo:nil];
    }
}

@end
