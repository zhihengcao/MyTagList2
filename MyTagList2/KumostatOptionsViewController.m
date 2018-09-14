
#import "KumostatOptionsViewController.h"

@implementation KumostatOptionsViewController

/*- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
	self= [super initWithStyle:UITableViewStylePlain];
	if(self)
		self.delegate=delegate;
	return self;
}*/

-(void)releaseViews{
	[heat3 release]; heat3=nil;
	[heat2 release]; heat2=nil;
	[heat1 release]; heat1=nil;
	[ac3 release]; ac3=nil;
	[ac2 release]; ac2=nil;
	[ac1 release]; ac1=nil;
	[fan3 release]; fan3=nil;
	[fan2 release]; fan2=nil;
	[fan1 release]; fan1=nil;
}
-(void)dealloc{
	[self releaseViews];
	self.config=nil;
	[super dealloc];
}

-(void)navbarSave{
	
	NSMutableDictionary* c = self.config;
	[c setObject:[NSNumber numberWithInt:heat3.value] forKey:@"heat3"];
	[c setObject:[NSNumber numberWithInt:heat2.value] forKey:@"heat2"];
	[c setObject:[NSNumber numberWithInt:heat1.value] forKey:@"heat1"];
	[c setObject:[NSNumber numberWithInt:ac3.value] forKey:@"ac3"];
	[c setObject:[NSNumber numberWithInt:ac2.value] forKey:@"ac2"];
	[c setObject:[NSNumber numberWithInt:ac1.value] forKey:@"ac1"];
	[c setObject:[NSNumber numberWithInt:fan3.value] forKey:@"fan3"];
	[c setObject:[NSNumber numberWithInt:fan2.value] forKey:@"fan2"];
	[c setObject:[NSNumber numberWithInt:fan1.value] forKey:@"fan1"];
	
	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self];
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];
	heat3.value = [[c objectForKey:@"heat3"] intValue];
	heat2.value = [[c objectForKey:@"heat2"] intValue];
	heat1.value = [[c objectForKey:@"heat1"] intValue];
	ac3.value = [[c objectForKey:@"ac3"] intValue];
	ac2.value = [[c objectForKey:@"ac2"] intValue];
	ac1.value = [[c objectForKey:@"ac1"] intValue];
	fan3.value = [[c objectForKey:@"fan3"] intValue];
	fan2.value = [[c objectForKey:@"fan2"] intValue];
	fan1.value = [[c objectForKey:@"fan1"] intValue];
	[super setConfig:c];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	heat3 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Heat Level 3" delegate:self];
	heat2 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Heat Level 2" delegate:self];
	heat1 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Heat Level 1" delegate:self];
	ac3 = [IASKPSWiringSpecifierViewCell newWithTitle:@"AC Level 3" delegate:self];
	ac2 = [IASKPSWiringSpecifierViewCell newWithTitle:@"AC Level 2" delegate:self];
	ac1 = [IASKPSWiringSpecifierViewCell newWithTitle:@"AC Level 1" delegate:self];
	fan3 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Fan Level 3" delegate:self];
	fan2 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Fan Level 2" delegate:self];
	fan1 = [IASKPSWiringSpecifierViewCell newWithTitle:@"Fan Level 1" delegate:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"\nConfigure which wires are energized for each state. For example if you have multi-stage fan but do not need 3 stage heat, you can borrow * to use as fan level 2 and 3. \nIf you don't need to change anything, just tap the back button. ";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 9;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	return heat3.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	switch(ip.row){
		case 0: return heat3;
		case 1: return heat2;
		case 2: return heat1;
		case 3: return ac1;
		case 4: return ac2;
		case 5: return ac3;
		case 6: return fan1;
		case 7: return fan2;
		case 8: return fan3;
		default: return nil;
	}
}

@end
