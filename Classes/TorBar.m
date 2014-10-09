//
//  TorBar.m
//  TorBarExample
//


#import "TorBar.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "NSApplication+LoginItem.h"

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
    int state = NSApplication.sharedApplication.launchesOnLogin ? NSOnState : NSOffState;
    
    if (_launchMenuItem.state != state)
    {
        [_launchMenuItem setState:state];
    }
}

- (IBAction)toggleLaunchOnLogin:(id)sender
{
    [NSApplication.sharedApplication setLaunchesOnLogin:!NSApplication.sharedApplication.launchesOnLogin];
    [self updateLaunchMenuItem];
}


@end
