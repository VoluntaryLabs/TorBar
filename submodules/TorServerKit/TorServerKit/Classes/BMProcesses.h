//
//  BMProcesses.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <errno.h>

@interface BMProcesses : NSObject

//static int GetBSDProcessList(struct kinfo_proc **procList, size_t *procCount);

+ (BMProcesses *)sharedBMProcesses;

- (BOOL)isProcessRunningWithName:(NSString *)name pid:(pid_t)pid;
- (NSDictionary *)infoForPID:(pid_t)pid;

@end
