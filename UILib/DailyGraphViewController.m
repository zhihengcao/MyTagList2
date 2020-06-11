#import "DailyGraphViewController.h"
#import <math.h>
#import "ShinobiChart+Screenshot.h"
#import "RawDataChart.h"
#import "Tag.h"

#pragma mark ChartTableViewCell
@implementation ChartTableViewCell
@synthesize chart;

- (void)layoutSubviews
{
	[super layoutSubviews];
	chart.frame=self.bounds;
}
- (id)initSingleTagGraphWithReuseId:(NSString*)reuseId
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
	if (self) {
		chart = [[SingleTagChart alloc] initWithFrame:self.bounds];
/*		for (UIGestureRecognizer *gestureRecognizer in [[singleTagChart.canvas overlay] gestureRecognizers]) {
			gestureRecognizer.delegate = self; // In this example, I created the charts in a view controller, and set the same view controller to be the delegate
		}*/
		self.backgroundView = chart;
		self.selectionStyle=UITableViewCellSelectionStyleNone;
	}
	return self;
}

- (id)initMultiTagGraphWithReuseId:(NSString*)reuseId andType:(id<StatTypeTranslator>)type;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
	if (self) {
		chart = [[MultiTagChart alloc] initWithFrame:self.bounds andType:type];
/*		for (UIGestureRecognizer *gestureRecognizer in [[multiTagChart.canvas overlay] gestureRecognizers]) {
			gestureRecognizer.delegate = self; // In this example, I created the charts in a view controller, and set the same view controller to be the delegate
		}*/
		self.backgroundView = chart;
		self.selectionStyle=UITableViewCellSelectionStyleNone;
	}
	return self;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

-(void)dealloc{
	self.chart=nil;
	[super dealloc];
}

@end

#pragma mark ShareTextDescription
@implementation ShareTextDescription {
}
@synthesize iosURL, webURL;

-(id)initWithUUID:(NSArray*)uuids andName:(NSString*)name andType:(NSString*)type fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate{
	self=[super initWithPlaceholderItem:NSLocalizedString(@"...Captured by Wireless Sensor Tags",nil)];
	if(self){
		NSMutableArray* uuids2 = [[[NSMutableArray alloc]initWithCapacity:uuids.count] autorelease];
		for(id o in uuids){
			if(o != [NSNull null])[uuids2 addObject:o];
		}
		self.iosURL = [NSString stringWithFormat:@"wtg://%@@%@/%@/%.0f/%.0f", type, name,
				  [uuids2 componentsJoinedByString:@":"], [fromDate timeIntervalSince1970], [toDate timeIntervalSince1970]  ];
		if(uuids.count==1){
			if(![type isEqualToString:@"motion"]){
				self.webURL=[WSROOT stringByAppendingFormat:@"eth/tempStats.html?%@&%@", [uuids2 objectAtIndex:0],
						[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}else{
				self.webURL=[WSROOT stringByAppendingFormat:@"eth/stats.html?%@&%@", [uuids2 objectAtIndex:0],
						[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
		}else{
			self.webURL=[WSROOT stringByAppendingFormat:@"eth/tempStatsMulti.html?%@&%@", [uuids2 componentsJoinedByString:@":"],type];
		}
	}
	return self;
}
-(void)dealloc{
	self.webURL=nil; self.iosURL=nil;
	[super dealloc];
}
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
	
	if ([activityType isEqualToString:UIActivityTypeMessage] || [activityType isEqualToString:UIActivityTypePostToWeibo]) {
		return [NSString stringWithFormat:@"Open graph:\n%@\nOpen in iOS app:\n<%@>...Captured by http://wirelesstag.net",
				webURL, iosURL];
	}
	else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        return NSLocalizedString(@"...Captured by http://wirelesstag.net",nil);
    } else{
		return [NSString stringWithFormat:@"<html><body><ul><li><a href='%@'>Open graph in Web browser</a></li><li><a href='%@'>Open in iOS app</a> (Install <a href='https://itunes.apple.com/us/app/wireless-tag-list/id508973799'>the iOS app</a>).</li></ul><div style='text-align:right'>...Captured by my <a href='http://wirelesstag.net'>Wireless Sensor Tags</a>",
				webURL, iosURL];
    }
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return @"";
}

@end

#pragma mark - GraphViewController
@implementation GraphViewController
@synthesize dataLoader=_dataLoader;
@synthesize shareHandler=_shareHandler, logDownloader=_logDownloader;

-(void)viewWillAppear:(BOOL)animated{
	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(float)0x5e/(float)0xff green:(float)0x87/(float)0xff
																				blue:(float)0xb0/(float)0xff alpha:1];
	
//		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		{
			[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];
			self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
		}
		
		
	} completion:^(BOOL finished) {
	}];
	
	[super viewWillAppear:animated];
}
-(void)dealloc{

	self.dataLoader=nil;
	self.shareHandler=nil;
	self.logDownloader=nil;
	[super dealloc];
}
-(void)viewDidLoad{
	[super viewDidLoad];

/*	[self.navigationController.navigationBar setBackgroundImage:[UIImage new]
							 forBarMetrics:UIBarMetricsDefault];
	self.navigationController.navigationBar.shadowImage = [UIImage new];
	self.navigationController.navigationBar.translucent = YES;
*/
}
-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
}

@end

#import "LandscapeGraphViewController.h"

#pragma mark - DailyGraphViewController
@implementation DailyGraphViewController
@synthesize data=_data;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}
/*-(void) orientationChanged:(id)obj
{
	UIDeviceOrientation devOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(devOrientation) && !viewIsLandscape ) {
		if(_landscapeVC==nil){
			if(isMultiTag){
				_landscapeVC = [[LandscapeGraphViewController alloc]initSecondaryMultiTagWithFrame:self.view.frame Title:self.title andSpanLoader:self.dataSpanLoader andHourlyLoader:self.hourlyDataLoader andType:self.type andDataLoader:self.dataLoader];
			}else{
				_landscapeVC = [[LandscapeGraphViewController alloc]initSecondarySingleTagWithFrame:self.view.frame Title:self.title andSpanLoader:self.dataSpanLoader andHourlyLoader:self.hourlyDataLoader andType:self.type andDataLoader:self.dataLoader];
			}
			_landscapeVC.logDownloader=self.logDownloader;
			_landscapeVC.shareHandler = self.shareHandler;
			
			//_landscapeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
		}
		//[self presentModalViewController:self.landscapeVC animated:NO];
		[self.navigationController pushViewController:self.landscapeVC animated:NO];
		viewIsLandscape = YES;
    }
	else if (UIDeviceOrientationIsPortrait(devOrientation) && viewIsLandscape)
    {
        //[self dismissModalViewControllerAnimated:NO];
		[self.navigationController popToViewController:self animated:NO];
        viewIsLandscape = NO;
    }
}*/
-(id)initSecondaryWithTitle:(NSString *)title andData:(NSMutableDictionary*)data andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
		self.title=title;
		self.navigationItem.title=title;
		self.dataLoader= loader;
		self.data=data;
		
		self.type=type;
		isMultiTag = [((NSString*)[data objectForKey:@"__type"]) isEqualToString:@"MyTagList.ethLogs+MultiTagStatsHourly"];
		if(isMultiTag){
			self.id2nameMapping=[[[NSMutableDictionary alloc]init] autorelease];
			for(int i=0;i<[[self.data objectForKey:@"ids"] count];i++){
				[self.id2nameMapping setObject:[[self.data objectForKey:@"names"]objectAtIndex:i] forKey:[[self.data objectForKey:@"ids"]objectAtIndex:i]];
			}
		}

	}
	return self;
}

/*
-(id)initPrimaryWithTitle:(NSString *)title andSpanLoader:(asyncLoadSpan_t)spanLoader andData:(NSDictionary*)data andType:(NSString *)type andDataLoader:(syncLoadRawData_t)loader{
	
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		self.type = findTranslator(type);
		self.title=title==nil? [self.type.name stringByAppendingString:@" Graph"]:title;
		self.dataSpanLoader = spanLoader;
		self.data=data;
		self.hourlyDataLoader = ^(onHourlyData done){
			done(data);
		};
		self.dataLoader= loader;
		temp_unit =[[self.data objectForKey:@"temp_unit"] boolValue];
		viewIsLandscape=NO;

		isMultiTag = [((NSString*)[data objectForKey:@"__type"]) isEqualToString:@"MyTagList.ethLogs+MultiTagStatsHourly"];
		if(isMultiTag){
			self.id2nameMapping=[[[NSMutableDictionary alloc]init] autorelease];
			for(int i=0;i<[[self.data objectForKey:@"ids"] count];i++){
				[self.id2nameMapping setObject:[[self.data objectForKey:@"names"]objectAtIndex:i] forKey:[[self.data objectForKey:@"ids"]objectAtIndex:i]];
			}
		}

		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	}
	return self;
}
*/

-(void)releaseSubViews{
//	self.landscapeVC=nil;
	
}
-(void)dealloc{
	NSLog(@"DailyGraphViewController::dealloc");
	self.date2DLI=nil;
	self.tempBaseline=nil; self.capBaseline=nil; self.luxBaseline=nil;
	self.data=nil;
	self.id2nameMapping=nil;
	[self releaseSubViews];
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.wantsFullScreenLayout=YES;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
																						   target:self action:@selector(downloadButtonPressed:)];

/*	if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
		self.navigationItem.leftBarButtonItem = ((UISplitViewController*)self.navigationController.parentViewController).displayModeButtonItem;
	}
*/
	//self.navigationController.navigationBar.topItem.title = @"";
	/*self.navigationItem.backBarButtonItem =
		[[[UIBarButtonItem alloc] initWithTitle:@"Back"
									  style:UIBarButtonItemStyleBordered
									 target:nil
									 action:nil] autorelease];*/
		
	self.tableView.separatorColor = [UIColor clearColor];
	viewIsLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation); // UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
}
- (void)viewDidUnload
{
	//[self dismissModalViewControllerAnimated:NO];
	[super viewDidUnload];
	[self releaseSubViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return isMultiTag? ((NSArray*)[_data objectForKey:@"stats"]).count :
	((NSArray*)[_data objectForKey:@"temps"]).count;
}
-(void)downloadButtonPressed:(id)sender{
	NSArray* dates;
	if(isMultiTag)dates =[_data objectForKey:@"stats"];
	else dates=[_data objectForKey:@"temps"];

	self.logDownloader(self, sender, [[dates lastObject] objectForKey:@"date"],[[dates firstObject] objectForKey:@"date"]);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return  200;
}
-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;

/*	if(![[NSUserDefaults standardUserDefaults] boolForKey:showedGraphLandscapeTooltip]){
		[DailyGraphViewController showTooltipNamed:@"landscape_notice" fromView:self.view];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:showedGraphLandscapeTooltip];
	}
 */
}

-(void)setRangeWithMinimum:(NSDate*)min andMaximum:(NSDate*)max
{
	NSArray* dates;
	if(isMultiTag)dates =[_data objectForKey:@"stats"];
	else dates=[_data objectForKey:@"temps"];
	NSInteger starti=0;
	for(NSInteger i=0;i<dates.count;i++){
		NSTimeInterval ti = [[MultiDayAxis dateFromString:[[dates objectAtIndex:i] objectForKey:@"date"]] timeIntervalSince1970];
		if(ABS(ti-[max timeIntervalSince1970])<3600*24){
			starti=i;break;
		}
	}
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:starti inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ChartTableViewCell *cell = (ChartTableViewCell *)[tableView
												  dequeueReusableCellWithIdentifier:@"ChartCell"];
    if(!cell){
		if(isMultiTag)
			cell=[[[ChartTableViewCell alloc]initMultiTagGraphWithReuseId:@"ChartCell" andType:self.type] autorelease];
		else{
			cell=[[[ChartTableViewCell alloc]initSingleTagGraphWithReuseId:@"ChartCell" ] autorelease];
			cell.chart.dewPointMode=self.dewPointMode;
			cell.chart.capIsChipTemperatureMode = self.capIsChipTemperatureMode;
			SingleTagChart* stchart =(SingleTagChart*)cell.chart;
			stchart.date2DLI=self.date2DLI;
			stchart.tempBaseline = self.tempBaseline;
			stchart.capBaseline = self.capBaseline;
			stchart.luxBaseline = self.luxBaseline;
		}
		cell.chart.useLogScaleForLight = [[NSUserDefaults standardUserDefaults]boolForKey:LogScalePrefKey];
	}
	if(isMultiTag){
		[(MultiTagChart*)cell.chart setDataSingleDay:[((NSArray*)[self.data objectForKey:@"stats"]) objectAtIndex:indexPath.row]
								  andMapping:self.id2nameMapping];
		cell.chart.dataLoader= self.dataLoader;
	}else{
		[(SingleTagChart*)cell.chart setDataSingleDay:[((NSArray*)[self.data objectForKey:@"temps"]) objectAtIndex:indexPath.row]];
		
		cell.chart.dataLoader=self.dataLoader;
	}
    return cell;
}

+(void)showTooltipNamed:(NSString*)imageName fromView:(UIView*)superView{
	UIImageView* view =[[[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]] autorelease];
	view.alpha=0;
	view.center = CGPointMake(superView.bounds.origin.x+superView.bounds.size.width/2, superView.bounds.origin.y+superView.bounds.size.height/2);
	[superView addSubview:view];
	[UIView animateWithDuration:0.5 delay:1.0 options:0 animations:^{
		view.alpha = 0.8f;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
			view.alpha=0;
		}completion:^(BOOL finished) {
			[view removeFromSuperview];
		}];
	}];
}

@end
