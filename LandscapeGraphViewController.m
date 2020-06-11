//
//  LandscapeGraphViewController.m
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "LandscapeGraphViewController.h"
#import "ShinobiChart+Screenshot.h"
#import "NSTimer+Blocks.h"

NSString * const LogScalePrefKey = @"LogScalePrefKey";


NSString * const showedGraphLandscapeTooltip = @"showedGraphLandscapeTooltip";
NSString * const showedGraphPinchTooltip = @"showedGraphPinchTooltip";

@interface LandscapeGraphViewController ()

@end

@implementation LandscapeGraphViewController
{
	//	UIImage* barBackground, *barShadow;
	NSDate* rawDataMin, *rawDataMax;
}
@synthesize chart=_chart, portraitVC=_portraitVC;


- (BOOL)splitViewController: (UISplitViewController*)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);
{
	return YES;
}
-(void)enableOrDisableDataRangeLimit{
	SChartDateRange* dataRange = (SChartDateRange*)self.chart.xAxis.dataRange;
	if([dataRange.minimum integerValue] > self.chart.earliestDate.timeIntervalSince1970 + 3600*36 || [dataRange.maximum integerValue]<self.chart.latestDate.timeIntervalSince1970-3600*36){
		self.chart.xAxis.allowPanningOutOfMaxRange=YES;
		NSLog(@"dataRange=(%@,%@), wanted (%@,%@)", dataRange.minimumAsDate, dataRange.maximumAsDate, self.chart.earliestDate,self.chart.latestDate);
	}else
		self.chart.xAxis.allowPanningOutOfMaxRange=NO;
}
-(void)setRangeWithMinimum:(NSDate*)min andMaximum:(NSDate*)max{
	
	[self.chart updateZoomPanMinDate:min MaxDate:max Done:^(){
		[self enableOrDisableDataRangeLimit];
		[self.chart.xAxis setRangeWithMinimum:min andMaximum:max withAnimation:NO];
	}];
}

-(void)zoomButtonPressed:(id)sender{
	
	NSTimeInterval ti = [_chart.latestDate timeIntervalSinceDate:_chart.earliestDate];
	
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	
	if((isMultiTag && [self.type isKindOfClass:[LuxTypeTranslator class]]) || (!isMultiTag && ((SingleTagChart*)self.chart).hasALS)){
		
		SChartAxis* yaxis =  isMultiTag? self.chart.yAxis : [self.chart.allYAxes objectAtIndex:1];
		BOOL isLog =[yaxis isKindOfClass:[SChartLogarithmicAxis class]];
		
		[sheet addButtonWithTitle:isLog?NSLocalizedString(@"Switch to Linear Scale",nil):NSLocalizedString(@"Switch to Log Scale",nil) block:^(NSInteger index){
			
			SChartDateRange* range = _chart.xAxis.axisRange;
			NSLog(@"min=%@, max=%@", range.minimumAsDate, range.maximumAsDate);
			
			[[NSUserDefaults standardUserDefaults]setBool:!isLog forKey:LogScalePrefKey];

			self.chart.useLogScaleForLight = !isLog;

			[NSTimer scheduledTimerWithTimeInterval:0.4 block:^{
				[self enableOrDisableDataRangeLimit];
				[self.chart.xAxis setRangeWithMinimum:range.minimumAsDate andMaximum:range.maximumAsDate withAnimation:YES];
			} repeats:NO];
			
		}];
	}
	[sheet addButtonWithTitle:NSLocalizedString(@"Last 24 Hours",nil) block:^(NSInteger index){
		
		[self.chart updateZoomPanMinDate: [_chart.latestDate dateByAddingTimeInterval:-3600*24] MaxDate:_chart.latestDate Done:^(){
			// going to raw may increase the latestDate.
			[self enableOrDisableDataRangeLimit];
			[_chart.xAxis setRangeWithMinimum:[_chart.latestDate dateByAddingTimeInterval:-3600*24] andMaximum:_chart.latestDate withAnimation:YES];
		}];
	}];
	if(ti>3600*24)
		[sheet addButtonWithTitle:NSLocalizedString(@"Last Week",nil) block:^(NSInteger index){
			[self.chart updateZoomPanMinDate: [_chart.latestDate dateByAddingTimeInterval:-3600*24*7] MaxDate:_chart.latestDate Done:^(){
				// going to raw may increase the latestDate.
				[self enableOrDisableDataRangeLimit];
				[_chart.xAxis setRangeWithMinimum:[_chart.latestDate dateByAddingTimeInterval:-3600*24*7] andMaximum:_chart.latestDate withAnimation:YES];
			}];
		}];
	if(ti>3600*24*7)
		[sheet addButtonWithTitle:NSLocalizedString(@"Last Month",nil) block:^(NSInteger index){
			[self.chart updateZoomPanMinDate: [_chart.latestDate dateByAddingTimeInterval:-3600*24*30] MaxDate:_chart.latestDate Done:^(){
				// going to raw may increase the latestDate.
				[self enableOrDisableDataRangeLimit];
				[_chart.xAxis setRangeWithMinimum:[_chart.latestDate dateByAddingTimeInterval:-3600*24*30] andMaximum:_chart.latestDate withAnimation:YES];
			}];
			
		}];
	[sheet addButtonWithTitle:NSLocalizedString(@"All Data",nil) block:^(NSInteger index){
		
		//[self.chart updateZoomPanMinDate: _chart.earliestDate MaxDate:_chart.latestDate Done:^(){
		//	[_chart.xAxis setRangeWithMinimum:_chart.earliestDate andMaximum:_chart.latestDate withAnimation:NO];
		//}];

		[self setRangeWithMinimum:_chart.earliestDate andMaximum:_chart.latestDate];
	}];
	
	

/*	[sheet addButtonWithTitle:@"Start Anim" block:^(NSInteger index){
		
		// 4:32AM -> 20:07PM in 21sec; 15h 35min / (21/0.2) = 534.2857 sec per frame
		NSDate* startDate = [[MultiDayAxis dateFromString:@"8/10/2016"] dateByAddingTimeInterval:-3600*4];
		__block NSTimeInterval counter=0;
		__block NSTimer* timer  = [NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
			
			[_chart.xAxis setRangeWithMinimum:[startDate dateByAddingTimeInterval:counter]
								   andMaximum:[startDate dateByAddingTimeInterval:counter+3600*9] withAnimation:YES];

			counter+=534.2857f/2.0f;
			if(counter>935*60){
				[timer invalidate];
				[self.chart justShownCompleteDay:[MultiDayAxis dateFromString:@"8/10/2016"]];
			}
		} repeats:YES];

	}];
	*/
	
	[sheet addButtonWithTitle:NSLocalizedString(@"Daily Graphs",nil) block:^(NSInteger index){
		
		if(_portraitVC==nil){
			if(_chart.hourlyData==nil){
				_chart.hourlyDataLoader(^(NSMutableDictionary* data){
					_chart.hourlyData=data;
					_portraitVC = [[DailyGraphViewController alloc] initSecondaryWithTitle:self.title andData:_chart.hourlyData andType:self.type andDataLoader:self.dataLoader];
					_portraitVC.dewPointMode=self.chart.dewPointMode;
					_portraitVC.capIsChipTemperatureMode = self.chart.capIsChipTemperatureMode;
					_portraitVC.logDownloader = self.logDownloader; // portrait mode does not have share button.
					[self.navigationController pushViewController:_portraitVC animated:YES];
				});
				return;
			}else{
				_portraitVC = [[DailyGraphViewController alloc] initSecondaryWithTitle:self.title andData:_chart.hourlyData andType:self.type andDataLoader:self.dataLoader];
				_portraitVC.dewPointMode=self.chart.dewPointMode;
				_portraitVC.capIsChipTemperatureMode = self.chart.capIsChipTemperatureMode;
				_portraitVC.logDownloader = self.logDownloader; // portrait mode does not have share button.
			}
			if(!isMultiTag){
				SingleTagChart* stchart =(SingleTagChart*)self.chart;
				_portraitVC.date2DLI = stchart.date2DLI;
				_portraitVC.tempBaseline = stchart.tempBaseline;
				_portraitVC.capBaseline = stchart.capBaseline;
				_portraitVC.luxBaseline = stchart.luxBaseline;
			}
		}
		[self.navigationController pushViewController:_portraitVC animated:YES];

	}];

	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender animated:YES];
	else [sheet showInView:_chart.window];
	[sheet release];
	
}
-(void)shareButtonPressed:(id)sender{
	
	[super showLoadingBarItem:sender];

	dispatch_queue_t snapshotQueue = dispatch_queue_create("com.MyTagList.snapshotQueue", NULL);
	dispatch_async(snapshotQueue, ^{
		
		ShinobiChart* chart =self.chart;
		UIImage* img =[chart snapshot];
		NSLog(@"img x=%f y=%f scale=%f", img.size.width, img.size.height, img.scale);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[super revertLoadingBarItem:sender];
			SChartDateRange* range =(SChartDateRange*)chart.xAxis.axisRange;
			self.shareHandler(self, sender, img, range.minimumAsDate, range.maximumAsDate);
		});
	});
	dispatch_release(snapshotQueue);
	
}

-(void)dealloc{
	self.chart=nil;
	self.portraitVC=nil;
	[super dealloc];
}

-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	[self setSplitViewRatio:0.1];

	self.navigationController.toolbarHidden=YES;
	//	[self.navigationController.parentViewController toggleMasterVisible:nil];
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:showedGraphPinchTooltip]){
		[DailyGraphViewController showTooltipNamed:@"pinch_zoom_notice" fromView:self.view];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:showedGraphPinchTooltip];
	}
/*
	if([self.navigationController.parentViewController isKindOfClass:[UISplitViewController class]]){
		UISplitViewController* spv =(UISplitViewController*)self.navigationController.parentViewController;
		if(spv.delegate!=self){
			spv.delegate = self;
			[spv willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
		}
	}
	*/
}
// only called if created by DetailViewController
/*-(void) orientationChanged:(id)obj
{
	UIDeviceOrientation devOrientation = [UIDevice currentDevice].orientation;
	if (UIDeviceOrientationIsLandscape(devOrientation) && !viewIsLandscape ) {
		[self.navigationController popToViewController:self animated:NO];
		viewIsLandscape = YES;
	}
	else if (UIDeviceOrientationIsPortrait(devOrientation) && viewIsLandscape)
	{
		if(_portraitVC==nil){
			_portraitVC = [[DailyGraphViewController alloc] initSecondaryWithTitle: self.title andSpanLoader:self.dataSpanLoader andHourlyLoader:self.hourlyDataLoader andType:self.type andDataLoader:self.dataLoader andId2nameMapping:self.id2nameMapping];
			_portraitVC.logDownloader = self.logDownloader; // portrait mode does not have share button.
		}
		NSLog(@"pushing");
		[self.navigationController pushViewController:_portraitVC animated:NO];
		viewIsLandscape = NO;
	}
}*/


// called from detailviewcontroller
- (id)initPrimaryWithTitle:(NSString*)title andFrame:(CGRect)frame
			 andSpanLoader:(asyncLoadSpan_t)spanLoader
		   andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader
				   andType:(NSString*)type andDataLoader:(syncLoadRawData_t)loader
{
	isMultiTag= (type!=nil);
	
	self = [super init];
	//frame.size.height -=self.view.safeAreaInsets
	//self.view.safeAreaLayoutGuide
	if(isMultiTag)
	{
		self.type= findTranslator(type);
		self.chart =[[[MultiTagChart alloc] initWithFrame:frame andType:self.type] autorelease];
		//self.multiTagChart.title = title;
		self.title=title;
		_chart.dataLoader = loader;
		_chart.hourlyDataLoader=hourlyLoader;
		_chart.spanLoader = spanLoader;

	}else{
		self.type = TemperatureTypeTranslator.instance;
		
		self.chart =[[[SingleTagChart alloc]initWithFrame:frame] autorelease];
		//self.singleTagChart.title = title;
		self.title=title;
		_chart.dataLoader=loader;
		_chart.hourlyDataLoader=hourlyLoader;
		_chart.spanLoader = spanLoader;

	}
	
	self.chart.useLogScaleForLight = [[NSUserDefaults standardUserDefaults]boolForKey:LogScalePrefKey];
	
	self.dataLoader=loader;
	
	if(title==nil)title = [self.type.name stringByAppendingString:NSLocalizedString(@" Graph",nil)];
	
	NSTimeInterval ti =[[NSUserDefaults standardUserDefaults] doubleForKey:
						[graphTIPrefix stringByAppendingString:NSStringFromClass([self.type class])]];
	if(ti!=0){
		
		spanLoader(^(NSDictionary* metadata){
			[_chart updateMetadata:metadata];
			
			_chart.earliestDate=nsdateFromFileTime([[metadata objectForKey:@"from"] longLongValue]);
			_chart.latestDate=nsdateFromFileTime([[metadata objectForKey:@"to"] longLongValue]);
			[_chart setMultiDayXAxis];

			
			SChartDateRange* range = [[SChartDateRange alloc]initWithDateMinimum:
									  [_chart.latestDate dateByAddingTimeInterval:-ti] andDateMaximum:_chart.latestDate];
			_chart.zoomLevel = ZoomLevelFromTI(ti);
			
			if(_chart.zoomLevel>=ChartZoomLevelNormal){
				[_chart enteredNormalLevelWithRange:range done:^(){

					[_chart.xAxis setRangeWithMinimum:[_chart.latestDate dateByAddingTimeInterval:-ti] andMaximum:_chart.latestDate withAnimation:NO];
					
				}];
			}else{
				[_chart enteredRawLevelWithRange:range done:^(){
					
					[_chart.xAxis setRangeWithMinimum:[_chart.latestDate dateByAddingTimeInterval:-ti] andMaximum:_chart.latestDate withAnimation:NO];
				}];
			}
			
		});
		
	}else{
		[_chart enteredNormalLevelWithRange:nil done:^(){
			[_chart setMultiDayXAxis];
		}];
	}
	
	self.title=title;
	self.navigationItem.title=title;
	
/*	viewIsLandscape = YES;
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil]; */
	
	return self;
}

/*
-(id)initSecondaryMultiTagWithFrame:(CGRect)frame Title:(NSString *)title andSpanLoader:(asyncLoadSpan_t)spanLoader andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader
{
	
	NSArray* dataDays = [data objectForKey:@"stats"];
	[self.multiTagChart setXAxisFor:dataDays];
	if(dataDays.count<=2){
		// zoom in if data is shorter than 48 hours
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.multiTagChart updateZoomPan];
		});
	}
	
	return self;
}
-(id)initSecondarySingleTagWithFrame:(CGRect)frame Title:(NSString *)title andSpanLoader:(asyncLoadSpan_t)spanLoader andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader
{
	self = [super init];
	
	self.type=type; isMultiTag=NO;
	
	NSArray* dataDays =[data objectForKey:@"temps"];
	[self.singleTagChart setXAxisFor:dataDays];
	[self.singleTagChart setDataMultipleDays:dataDays];
	if(dataDays.count<=2){
		// zoom in if data is shorter than 48 hours
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.singleTagChart updateZoomPan];
		});
	}
	return self;
}*/

-(void)loadView{
	self.wantsFullScreenLayout = NO;
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
		self.edgesForExtendedLayout = UIRectEdgeNone;

	self.view = _chart;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor=[UIColor whiteColor];

	UIWindow* top =UIApplication.sharedApplication.keyWindow;
	if([top respondsToSelector:@selector(safeAreaInsets)]){
		CGFloat safeAreaBottom=top.safeAreaInsets.bottom;
		_chart.canvasInset = UIEdgeInsetsMake(0, 0, safeAreaBottom*0.7f, 0);
	}
}
-(void)viewWillAppear:(BOOL)animated{

/*	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
		UINavigationBar* bar = self.navigationController.navigationBar;
		bgImage = bar.backIndicatorImage;
		[bar setBackgroundImage:[[UIImage new] autorelease]
				  forBarMetrics:UIBarMetricsDefault];
		shadowImage = [bar.shadowImage retain];
		bar.shadowImage = [[UIImage new] autorelease];
	}
 */
	[[UIBarButtonItem appearance]
	 setBackButtonTitlePositionAdjustment:UIOffsetMake(-1000, -1000)
	 forBarMetrics:UIBarMetricsLandscapePhone];
	
	//	if([bar respondsToSelector:@selector(setBarTintColor:)])
	//		bar.barTintColor= [UIColor colorWithWhite:1 alpha:0.4];
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
	
	[super viewWillAppear:animated];
}
-(void)restoreSplitViewRatio{
	if(originalSplitViewRatio==0)return;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		UISplitViewController* svc = (UISplitViewController*)self.parentViewController.parentViewController;
		if(	svc.preferredPrimaryColumnWidthFraction!=originalSplitViewRatio){

			//svc.preferredPrimaryColumnWidthFraction=originalSplitViewRatio;

			[NSTimer scheduledTimerWithTimeInterval:0.7 block:^{
				//[UIView animateWithDuration:0.25f animations:^{
					svc.preferredPrimaryColumnWidthFraction=originalSplitViewRatio;
					originalSplitViewRatio=0;
				//}];
			} repeats:NO];
		}
	}
}
-(void)setSplitViewRatio:(float)ratio{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		UISplitViewController* svc = (UISplitViewController*)self.parentViewController.parentViewController;
		originalSplitViewRatio = svc.preferredPrimaryColumnWidthFraction;
		
		if(	svc.preferredPrimaryColumnWidthFraction!=ratio){
			[NSTimer scheduledTimerWithTimeInterval:0.7 block:^{
//				[UIView animateWithDuration:0.25f animations:^{
					svc.preferredPrimaryColumnWidthFraction=ratio;
//				}];
			} repeats:NO];
			svc.preferredPrimaryColumnWidthFraction=ratio;
		}
	}
}
-(void)viewWillDisappear:(BOOL)animated{

	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
		UINavigationBar* bar = self.navigationController.navigationBar;
		[bar setBackgroundImage:bgImage  forBarMetrics:UIBarMetricsDefault]; [bgImage release];
		bar.shadowImage=shadowImage; [shadowImage release];
	}
	//	if([bar respondsToSelector:@selector(setBarTintColor:)])
	//		bar.barTintColor= [UIColor colorWithWhite:1 alpha:1];
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
	[super viewWillDisappear:animated];

	[self restoreSplitViewRatio];

	if(_chart.askForReview && ![[NSUserDefaults standardUserDefaults] boolForKey:@"AskedForReview2"]){
/*		if ([UIAlertController class]) {
			
		} else {
			// use UIAlertView
		} 
 */
		
/*		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rate Us 5 Stars!",nil)
										message:NSLocalizedString(@"If you enjoy Wireless Tags, would you mind taking a moment to give us a 5 star rating in the App Store? It will only take a minute. Thanks for your support!",nil)
							cancelButtonItem:[RIButtonItem itemWithLabel:NSLocalizedString(@"Remind me later",nil) action:^{}]
							otherButtonItems:[RIButtonItem itemWithLabel:NSLocalizedString(@"Rate Wireless Tag",nil) action:^{
			
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=508973799&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8" ]];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AskedForReview1"];
 */
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Rate This Product",nil)
									 message:NSLocalizedString(@"If you enjoy Wireless Tag by Cao Gadgets, would you mind taking a moment to give it a 5 star rating? It will only take a minute. Thanks for your support!",nil)
							cancelButtonItem:[RIButtonItem itemWithLabel:NSLocalizedString(@"Remind me later",nil) action:^{}]
							otherButtonItems:[RIButtonItem itemWithLabel:NSLocalizedString(@"Rate Wireless Tag",nil) action:^{
			
//			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"https://www.amazon.com/review/create-review/ref=cm_cr_dp_d_wr_but_top?ie=UTF8&channel=glance-detail&asin=B00FE9TEOU" ]];
			[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"https://www.google.com/search?hl=en-US&gl=us&q=CAO+GADGETS+LLC,+4603,+50+Tesla,+Irvine,+CA+92618&ludocid=1632316189981625371#lrd=0x80dce7df4e54475f:0x16a726ed28f94c1b,3"]];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AskedForReview2"];

		}],
		   [RIButtonItem itemWithLabel:NSLocalizedString(@"No, thanks",nil) action:^{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AskedForReview2"];
		}], nil]autorelease ] show];
		
	}
}

-(void)downloadButtonPressed:(id)sender{
	SChartDateRange* range = _chart.xAxis.axisRange;
	self.logDownloader(self, sender, [MultiDayAxis stringFromDate:range.minimumAsDate] ,[MultiDayAxis stringFromDate:range.maximumAsDate]);
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	//UISwipeGestureRecognizer *swipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)] autorelease];
	//swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
	//[self.view addGestureRecognizer:swipeGestureRecognizer];
	
	//self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
	
	NSMutableArray* rightButtons = [[[NSMutableArray alloc]initWithCapacity:3] autorelease];
	
	if(self.shareHandler!=nil)
		[rightButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																			  target:self action:@selector(shareButtonPressed:)]];
	if(self.logDownloader!=nil){
		[rightButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
																			  target:self action:@selector(downloadButtonPressed:)]];
	}
	
	[rightButtons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																		  target:self action:@selector(zoomButtonPressed:)]];
	
	self.navigationItem.rightBarButtonItems = rightButtons;
	/*	if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
		self.navigationItem.leftBarButtonItem = ((UISplitViewController*)self.navigationController.parentViewController).displayModeButtonItem;
	 }
	 */
}

@end
