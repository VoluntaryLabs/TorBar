//
//  TorProcess.h.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TorProcess : NSObject

@property (retain, nonatomic) NSTask *torTask;
@property (retain, nonatomic) NSString *serverDataFolder;
@property (retain, nonatomic) NSString *torPort;
@property (retain, nonatomic) NSPipe *inpipe;

- (void)launch;
- (void)terminate;
- (BOOL)isRunning;

// stats

- (NSNumber *)currentConnectionCount;
- (NSNumber *)kilobytesPerSecondDown;
- (NSNumber *)kilobytesPerSecondUp;

@end
