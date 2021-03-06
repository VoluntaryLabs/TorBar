//
//  NetworkMonitor.h
//  TorBar
//
//  Created by Steve Dekorte on 9/6/14.
//
//

#import <Foundation/Foundation.h>

#define NetworkMonitorChangeNotification @"NetworkMonitorChange"

@interface NetworkMonitor : NSObject

@property (strong) NSTimer *ssidTimer;
@property (strong) NSString *ssid;

- (void)start;
- (void)stop;

@end
