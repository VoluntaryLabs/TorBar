//
//  TorBar.m
//  TorBarExample
//


#import "TorBar.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>


@implementation TorBar

-(void)dealloc
{
    [self.torProcess terminate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [self setupStatusItem];
    [self setupTor];
    //[self.torProcess launch];

    
    [self listenForNetworkChange];
    [self startUpdateTimer];
}

- (void)startUpdateTimer
{
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(updateStatus)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)listenForNetworkChange
{
    _networkMonitor = [[SINetworkMonitor alloc] init];
    [_networkMonitor start];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:)
                                                 name:SINetworkMonitorChangeNotification
                                               object:_networkMonitor];
}

- (void)setupStatusItem
{
	_statusItem = [[NSStatusBar systemStatusBar]
				   statusItemWithLength:NSVariableStatusItemLength];
	[_statusItem setHighlightMode:YES];
	[_statusItem setEnabled:YES];
	[_statusItem setToolTip:@"TorBar"];
	
	[_statusItem setAction:@selector(clickedOnStatusItem:)];
	[_statusItem setTarget:self];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"StatusMenu"];
    [_statusItem setMenu:menu];
    
    _toggleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Run Tor" action:@selector(toggleTorRunning) keyEquivalent:@""];
    [_toggleMenuItem setTarget:self];
    [menu addItem:_toggleMenuItem];
    [menu setAutoenablesItems:NO];
    
    _launchMenuItem = [[NSMenuItem alloc] initWithTitle:@"Launch On Login" action:@selector(toggleLaunchOnLogin:) keyEquivalent:@""];
    [_launchMenuItem setTarget:self];
    [menu addItem:_launchMenuItem];
    [self updateLaunchMenuItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@""];
    [quitMenuItem setTarget:self];
    [menu addItem:quitMenuItem];
}

/*
- (void)setStatusItemIcon
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"AppIcon" ofType:@"tif"];
	_menuIcon= [[NSImage alloc] initWithContentsOfFile:path];
	[_statusItem setTitle:@""];
	[_statusItem setImage:_menuIcon];
}
*/

- (void)setupTor
{
    NSString *dataPath = [NSString stringWithString:[[NSFileManager defaultManager] applicationSupportDirectory]];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    _torProcess = [[TorProcess alloc] init];
    _torProcess.torPort = [mainBundle objectForInfoDictionaryKey:@"TorPort"];
    _torProcess.serverDataFolder = dataPath;
}

// menu actions


- (IBAction)clickedOnStatusItem:(id)sender
{
    [self toggleTorRunning];
}

- (void)toggleTorRunning
{
    [self setRunning:!_torProcess.isRunning];
    
    [self updatePref];
}

- (void)setRunning:(BOOL)doRun
{
    if (doRun && _networkMonitor.ssid != nil)
    {
        [_torProcess launch];
    }
    else
    {
        [_torProcess terminate];
    }

    [self updateStatus];
}

- (IBAction)quit:(id)sender
{
    [NSApplication.sharedApplication terminate:self];
}

// status

- (void)setStatusTitle:(NSString *)aTitle
{
    if (![_statusItem.title isEqualTo:aTitle])
    {
        [_statusItem setTitle:aTitle];
    }
}

- (void)updateStatus
{
    NSString *mainStatus = @"";
    NSString *status = @"";

    if (_torProcess.isRunning)
    {
        mainStatus = @"Tor On";
        status = [NSString stringWithFormat:@"Run On (%@)", _networkMonitor.ssid];
        
        /*
        NSNumber *bps = _torProcess.bpsRead;
        
        if (bps.integerValue)
        {
            status = [NSString stringWithFormat:@"%@ %iKbps", status, bps.intValue/(8*1024)];
        }
        */
        [_toggleMenuItem setState:NSOnState];
        [_toggleMenuItem setEnabled:YES];
    }
    else
    {
        [_toggleMenuItem setState:NSOffState];

        if (_networkMonitor.ssid == nil)
        {
            mainStatus = @"Tor Off (No Network)";
            status = @"Run On (No Network)";
           [_toggleMenuItem setEnabled:NO];
        }
        else
        {
            mainStatus = @"Tor Off";
            status = [NSString stringWithFormat:@"Run On (%@)", _networkMonitor.ssid];
            [_toggleMenuItem setState:NSOffState];
            [_toggleMenuItem setEnabled:YES];
        }
    }
    
    [self setStatusTitle:mainStatus];
    [self setToggleTitle:status];
}

- (void)setToggleTitle:(NSString *)aTitle
{
    if (![_toggleMenuItem.title isEqualTo:aTitle])
    {
        [_toggleMenuItem setTitle:aTitle];
    }
}

- (void)networkChanged:(NSNotification *)aNote
{
    BOOL doRun = [self shouldRunForNetworkName:_networkMonitor.ssid];
    [self setRunning:doRun];
}

- (void)setShouldRun:(BOOL)shouldRun forNetworkName:(NSString *)networkName
{
    NSNumber *aBool = [NSNumber numberWithBool:shouldRun];
    NSMutableDictionary *dict = self.prefsDict;
    [dict setObject:aBool forKey:networkName];
    [self setPrefsDict:dict];
}

- (BOOL)shouldRunForNetworkName:(NSString *)networkName
{
    if (networkName == nil)
    {
        return NO;
    }
    
    NSDictionary *dict = self.prefsDict;
    NSNumber *aBool = [dict objectForKey:networkName];
    
    if (aBool)
    {
        return aBool.boolValue;
    }
    
    return NO;
}

- (void)updatePref
{
    if (_networkMonitor.ssid)
    {
        [self setShouldRun:_torProcess.isRunning forNetworkName:_networkMonitor.ssid];
    }
}

// prefs dict

- (NSMutableDictionary *)prefsDict
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"networkPrefs"];
    
    if (dict)
    {
        return [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    
    return [NSMutableDictionary dictionary];
}

- (void)setPrefsDict:(NSDictionary *)dict
{
    [NSUserDefaults.standardUserDefaults setObject:dict forKey:@"networkPrefs"];
    [NSUserDefaults.standardUserDefaults synchronize];
}

// launchOnLogin

- (void)updateLaunchMenuItem
{
    int state = self.launchOnLogin ? NSOnState : NSOffState;
    
    if (_launchMenuItem.state != state)
    {
        [_launchMenuItem setState:state];
        
        if (state == NSOnState)
        {
            [self addAppAsLoginItem];
        }
        else
        {
            [self deleteAppFromLoginItem];
        }
    }
}

- (IBAction)toggleLaunchOnLogin:(id)sender
{
    [self setLaunchOnLogin:!self.launchOnLogin];
}

- (BOOL)launchOnLogin
{
    return [NSUserDefaults.standardUserDefaults boolForKey:@"launchOnLogin"];
}

- (void)setLaunchOnLogin:(BOOL)aBool
{
    [NSUserDefaults.standardUserDefaults setBool:aBool forKey:@"launchOnLogin"];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self updateLaunchMenuItem];
}


- (void)addAppAsLoginItem
{
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
    // This will retrieve the path for the application
    // For example, /Applications/test.app
    CFURLRef url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
    
    // Create a reference to the shared file list.
    // We are adding it to the current user only.
    // If we want to add it all users, use
    // kLSSharedFileListGlobalLoginItems instead of
    //kLSSharedFileListSessionLoginItems
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems)
    {
        //Insert an item to the list.
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                     kLSSharedFileListItemLast, NULL, NULL,
                                                                     url, NULL, NULL);
        if (item)
        {
            CFRelease(item);
        }
    }
    
    CFRelease(loginItems);
}

- (void)deleteAppFromLoginItem
{
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    
    // This will retrieve the path for the application
    // For example, /Applications/test.app
    CFURLRef url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:appPath]);
    
    // Create a reference to the shared file list.
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItems)
    {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray  *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));

        for(int i = 0; i< [loginItemsArray count]; i++)
        {
            LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFBridgingRetain([loginItemsArray
                                                                        objectAtIndex:i]);
            //Resolve the item with URL
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                NSString * urlPath = [(NSURL*)CFBridgingRelease(url) path];
                if ([urlPath compare:appPath] == NSOrderedSame){
                    LSSharedFileListItemRemove(loginItems,itemRef);
                }
            }
        }
    }
}

@end
