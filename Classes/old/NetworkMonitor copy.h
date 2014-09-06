//
//  NetworkMonitor.h
//  TorBar
//
//  Created by Steve Dekorte on 9/6/14.
//
//

#import <Foundation/Foundation.h>

@interface NetworkMonitor : NSObject

@property (strong) NSString *prevSSID;
@property (strong) NSTimer *ssidTimer;

- (void)start;
- (void)stop;

@end
