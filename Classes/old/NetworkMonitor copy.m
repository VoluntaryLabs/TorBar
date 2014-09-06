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

- (id)fetchSSIDInfo
{
    //CFArrayRef array = CNCopySupportedInterfaces();
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    
    /*
    id info = nil;
    NSString *ifnam = @"";
    
    for (ifnam in ifs)
    {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        
        if (info && [info count])
        {
            break;
        }
    }
    
    if ([info count] >= 1 && [ifnam caseInsensitiveCompare:_prevSSID] !=  NSOrderedSame)
    {
        // Trigger some event
        _prevSSID = ifnam;
    }
    return info;
    */
    
    return nil;
}

@end
