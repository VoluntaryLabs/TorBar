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
    [self updateStatus];
    //[self.torProcess launch];

    
    [self listenForNetworkChange];
}

- (void)listenForNetworkChange
{
    _networkMonitor = [[NetworkMonitor alloc] init];
    [_networkMonitor start];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:)
                                                 name:NetworkMonitorChangeNotification
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

		
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"AppIcon" ofType:@"tif"];
	_menuIcon= [[NSImage alloc] initWithContentsOfFile:path];
	[_statusItem setTitle:@""];
	[_statusItem setImage:_menuIcon];
}

- (void)setupTor
{
    NSString *dataPath = [NSString stringWithString:[[NSFileManager defaultManager] applicationSupportDirectory]];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    _torProcess = [[TorProcess alloc] init];
    _torProcess.torPort = [mainBundle objectForInfoDictionaryKey:@"TorPort"];
    _torProcess.serverDataFolder = dataPath;
}

- (IBAction)clickedOnStatusItem:(id)sender
{
    [self toggleTorRunning];
}

- (void)toggleTorRunning
{
    if (_torProcess.isRunning)
    {
        [_torProcess terminate];
    }
    else
    {
        [_torProcess launch];
    }
    
    [self updateStatus];
    [self updatePref];
}

- (void)updateStatus
{
    if (_torProcess.isRunning)
    {
        [_statusItem setTitle:@"running"];
    }
    else
    {
        [_statusItem setTitle:@"stopped"];
    }
}

- (void)networkChanged:(NSNotification *)aNote
{
    if ([self shouldRunForNetworkName:_networkMonitor.ssid])
    {
        [_torProcess launch];
    }
    else
    {
        [_torProcess terminate];
    }
    
    [self updateStatus];
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
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"networkPrefs"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
