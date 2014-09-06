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
}

- (void)awakeFromNib
{
    [self setupStatusItem];
    [self setupTor];
    [self updateStatus];
    //[self.torProcess launch];
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


@end
