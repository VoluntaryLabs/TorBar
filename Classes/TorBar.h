//
//  TorBar.h
//  TorBarExample
//


#import <Foundation/Foundation.h>
#import <TorServerKit/TorServerKit.h>

@interface TorBar : NSObject

@property (strong) NSStatusItem *statusItem;
@property (strong) NSImage *menuIcon;
@property (strong) TorProcess *torProcess;


@end
