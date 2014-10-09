//
//  NSApplication+LoginItem.h
//  TorBar
//
//  Created by Steve Dekorte on 10/8/14.
//
//

#import <Cocoa/Cocoa.h>

@interface NSApplication (LoginItem)

- (void)setLaunchesOnLogin:(BOOL)aBool;
- (BOOL)launchesOnLogin;

//- (void)addAppAsLoginItem;
//- (void)deleteAppFromLoginItem;

@end
