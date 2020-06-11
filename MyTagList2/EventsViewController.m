#import "EventsViewController.h"
#import "NSTimer+Blocks.h"

extern int64_t getfiletime(void);

int64_t getfiletime(void)
{
    struct timeval tv;
    int64_t result = EPOCH_DIFF;
    gettimeofday(&tv,NULL);
    result += tv.tv_sec;
    result *= 10000000LL;
    result += tv.tv_usec * 10;
    return result;
}

@implementation HeaderLabel
- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {0, 0, 0, 5};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
@implementation TopPagingViewController
@synthesize mvc=_mvc,evc=_evc, pcDots=_pcDots;
@synthesize mvc_left, mvc_right, evc_left, evc_right, tvc_left, tvc_right;

-(id)initWithMvc:(MasterViewController*)mvc andEvc:(EventsViewController*)evc andTvc:(TrendTableViewController *)tvc{
	self= [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
								 options:nil];
	if(self){
		self.mvc = mvc;
		self.evc_left= mvc.navigationItem.leftBarButtonItem;   // logout
		self.tvc_right = tvc.navigationItem.rightBarButtonItem;  // rearrange
		self.mvc_right= [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Trends",nil) style:UIBarButtonItemStylePlain
														 target:self action:@selector(openTvc:)] autorelease];
		self.evc_right  = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tags",nil) style:UIBarButtonItemStylePlain
																	   target:self action:@selector(openMvc:)] autorelease];
		self.tvc_left  = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tags",nil) style:UIBarButtonItemStylePlain
														   target:self action:@selector(openMvcLeft:)] autorelease];
		self.mvc_left =[[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Events",nil) style:UIBarButtonItemStylePlain
												  target:self action:@selector(openEvc:)] autorelease];
		mvc.topPVC = self;
		tvc.topPVC = self;
		self.evc=evc;
		self.tvc = tvc;
		evc.topPVC = self;
		self.dataSource = self;
		self.delegate=self;
		
		//self.automaticallyAdjustsScrollViewInsets = true;
		//self.wantsFullScreenLayout=NO;
		//self.definesPresentationContext=YES;
		//evc.modalPresentationStyle = mvc.modalPresentationStyle=UIModalPresentationCurrentContext;
		//evc.edgesForExtendedLayout = mvc.edgesForExtendedLayout = UIRectEdgeNone;
		if([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
			self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	return self;
}
-(void)dealloc{
	self.mvc=nil;
	self.evc=nil;
	self.tvc=nil;
	self.evc_right=nil;
	self.evc_left=nil;
	self.mvc_right=nil;
	self.mvc_left=nil;
	self.tvc_left=nil;
	self.tvc_right=nil;
	self.pcDots=nil;
	[super dealloc];
}
-(BOOL)isTagManagerChoiceVisible{
	return self.navigationController.topViewController==self && (_pcDots.currentPage>=1);
}
-(BOOL)isMVCVisible{
	return self.navigationController.topViewController==self && (_pcDots.currentPage==1);
}
-(UINavigationItem*)navigationItem{
	return _mvc.navigationItem;
//	if(_pcDots.currentPage==0)return _evc.navigationItem;
//	else return _mvc.navigationItem;
}

/*-(NSArray*)toolbarItems{
	return _mvc.toolbarItems;
}*/

/*-(void)openMvcNoAnimation{
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	[self setMvcBar];
}*/
/*-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration{
    CGSize navBarSize = self.navigationController.navigationBar.bounds.size;
	CGRect f = self.pcDots.frame;
	if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)) {
        f.origin.y=navBarSize.height*3.0/4.0;
    }else{
		f.origin.y =navBarSize.height*5.0/6.0;
	}
	self.pcDots.frame=f;
}*/

#define tagScopes @[@"All",@"TooHot",@"Normal",@"TooCold",@"N/A"]
#define eventScopes @[@"All",@"Temp",@"RH",@"Lux", @"Motion",@"Other"];

-(void)viewDidLoad{
	[super viewDidLoad];

	self.searchController = [[UISearchController alloc]	 initWithSearchResultsController:nil];
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.definesPresentationContext = YES;

	if(@available(iOS 11.0, *)){
		self.navigationItem.searchController = self.searchController;
		self.navigationItem.hidesSearchBarWhenScrolling=YES;
	}else{
		self.searchController.hidesNavigationBarDuringPresentation=NO;
		_mvc.tableView.tableHeaderView = self.searchController.searchBar;
	}
	//self.navigationController.navigationBar.translucent=YES;

	[self.searchController.searchBar sizeToFit];

	
	//self.automaticallyAdjustsScrollViewInsets = false;
	//[[self view] setFrame:CGRectMake(0, 0, [[self view] bounds].size.width, [[self view] bounds].size.height + 37)];
	//[self openMvcNoAnimation];
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

	UINavigationController *navController = self.navigationController;
    CGSize navBarSize = navController.navigationBar.bounds.size;
    CGPoint origin = CGPointMake( navBarSize.width/2, navBarSize.height*5.0/6.0 );
    self.pcDots = [[[UIPageControl alloc] initWithFrame:CGRectMake(origin.x, origin.y,
                                                                       0, 0)] autorelease];
	//[UIPageControl appearance].pageIndicatorTintColor = [UIColor colorWithRed:1.0 green:(float)0x6b/(float)0xff blue:(float)0x5f/(float)0xff alpha:0.25];
	//[UIPageControl appearance].currentPageIndicatorTintColor =[UIColor colorWithRed:1.0 green:(float)0x6b/(float)0xff blue:(float)0x5f/(float)0xff alpha:1];
	[UIPageControl appearance].pageIndicatorTintColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.25];
	[UIPageControl appearance].currentPageIndicatorTintColor =[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    [_pcDots setNumberOfPages:3];

	[navController.navigationBar addSubview:_pcDots];
}
-(void)restorePreviousPage{
	id topPage = [[NSUserDefaults standardUserDefaults] objectForKey:@"TopPage"];
	NSLog(@"Loading previously selected topPage=%@", topPage);
	
	if(topPage!=nil && [topPage integerValue]==2){
		[self setViewControllers:@[_tvc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished){
			if(finished)	[self setTvcBar];
		}];
		
	}else if(topPage!=nil && [topPage integerValue]==0){
		[self setViewControllers:@[_evc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished){
			if(finished)[self setEvcBar];
		}];
		
	}else{
		[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished){
			if(finished){
				[self setMvcBar];
			}
		}];
	}

}
-(void)openEvc:(id)sender{
	[self setViewControllers:@[_evc] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished){
		if(finished)[self setEvcBar];
	}];
}
-(void)openMvc:(id)sender{
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
		if(finished)[self setMvcBar];
	}];
}
-(void)openMvcLeft:(id)sender{
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished){
		if(finished)[self setMvcBar];
	}];
}
-(void)openTvc:(id)sender{
	[self setViewControllers:@[_tvc] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
		if(finished)	[self setTvcBar];
	}];
}
-(void)setTvcBar{
	
//	if(@available(iOS 13.0, *))
//		self.searchController.automaticallyShowsScopeBar = YES;
	
	self.searchController.searchBar.placeholder = @"Search by name";
	self.searchController.searchBar.scopeButtonTitles = tagScopes;
	self.searchController.searchResultsUpdater = _tvc;
	self.searchController.searchBar.delegate = _tvc;
	if(@available(iOS 11.0, *)){
	}else{
		_tvc.tableView.tableHeaderView = self.searchController.searchBar;
	}

	if(self.searchController.active)[_tvc updateSearchResultsForSearchController:self.searchController];
	
	[_pcDots setCurrentPage:2];
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	self.navigationItem.title=_tvc.title;
	
	self.navigationItem.leftBarButtonItem = tvc_left;
	self.navigationItem.rightBarButtonItem = tvc_right;

	[[NSUserDefaults standardUserDefaults]setInteger:2 forKey:@"TopPage"];
}
-(void)setEvcBar{
	
//	self.searchController.active=NO;
//	if(@available(iOS 13.0, *))
//		self.searchController.searchBar.showsScopeBar = NO;
	
	self.searchController.searchBar.placeholder = @"Search by keyword";
	self.searchController.searchBar.scopeButtonTitles = eventScopes;
	self.searchController.searchBar.selectedScopeButtonIndex = _savedSearchScopeEvc;
	self.searchController.searchResultsUpdater = _evc;
	self.searchController.searchBar.delegate = _evc;
	if(@available(iOS 11.0, *)){
	}else{
		_evc.tableView.tableHeaderView = self.searchController.searchBar;
	}
	if(self.searchController.active)[_evc updateSearchResultsForSearchController:self.searchController];

	[_pcDots setCurrentPage:0];
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	self.navigationItem.title=_evc.title;
	self.navigationItem.leftBarButtonItem = evc_left;
	self.navigationItem.rightBarButtonItem = evc_right;
	
	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:1 green:(float)0x6b/(float)0xff
																				blue:(float)0x5f/(float)0xff alpha:1];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
	} completion:nil];
	
	[[NSUserDefaults standardUserDefaults]setInteger:0 forKey:@"TopPage"];

	
//	self.navigationItem.leftBarButtonItem =
}
-(void)setMvcBar{

//	if(@available(iOS 13.0, *))
	//	self.searchController.automaticallyShowsScopeBar = YES;

	self.searchController.searchBar.scopeButtonTitles = tagScopes;
	self.searchController.searchBar.selectedScopeButtonIndex = _savedSearchScopeMvc;
	
	self.searchController.searchBar.placeholder = @"Search by name";
	self.searchController.searchResultsUpdater = _mvc;
	self.searchController.searchBar.delegate = _mvc;
	if(@available(iOS 11.0, *)){
	}else{
		_mvc.tableView.tableHeaderView = self.searchController.searchBar;
	}
	if(self.searchController.active)
		[_mvc updateSearchResultsForSearchController:self.searchController];

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		UISplitViewController* svc = (UISplitViewController*)self.navigationController.parentViewController;
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			
			[UIView animateWithDuration:0.25f animations:^{
				svc.preferredPrimaryColumnWidthFraction=0.4f;
			}];
		} repeats:NO];
	}
	[_pcDots setCurrentPage:1];
	
	[self.navigationController setToolbarHidden:NO animated:YES];
	
	self.navigationItem.title=_mvc.title;
	self.navigationItem.leftBarButtonItem = mvc_left;
	self.navigationItem.rightBarButtonItem = mvc_right;

	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UINavigationBar appearance].tintColor;
	} completion:^(BOOL finished) {
	}];

	[[NSUserDefaults standardUserDefaults]setInteger:1 forKey:@"TopPage"];

}
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{

	if(!completed)return;
	if([previousViewControllers objectAtIndex:0]==_mvc){
		if(swipingToTVC)
			[self setTvcBar];
		else
			[self setEvcBar];
	}else{
		[self setMvcBar];
	}
}
-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers{
	if([pendingViewControllers objectAtIndex:0]==_tvc)swipingToTVC=YES;
	else swipingToTVC=NO;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if(viewController==_mvc){
		return _evc;
	}
	else if(viewController==_tvc){
		return _mvc;
	}else
		return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	if(viewController==_evc){
		return _mvc;
	}
	else if(viewController==_mvc){
		return _tvc;
	}else{
		return nil;
	}
}
/*-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	if(@available(iOS 11.0,*))
		self.navigationItem.hidesSearchBarWhenScrolling = NO;
}
-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	if(@available(iOS 11.0,*))
		self.navigationItem.hidesSearchBarWhenScrolling = YES;
}*/
@end
@implementation EventsViewController
@synthesize loader=_loader, savedSearchTerm=_savedSearchTerm;

- (id)initWithLoader:(downloadEventsBlock_t)loader andNewLoader:(downloadNewEventsBlock_t)newLoader
{
	self = [super initWithNibName:@"SearchTableView_iPhone" bundle:nil];
	
	if(self){
		self.loader = loader;
		self.newLoader = newLoader;
		self.title=@"Event History";
		_dates=[NSMutableArray new];
		_events=[NSMutableArray new];
		_uuid2events = [NSMutableDictionary new];
		_filteredEvents=[NSMutableArray new];
		olderThan = getfiletime();
	}
	return self;
}
-(void)reloadFromServer{
	[self removeEvents];
//	if(searchWasActive)[self.searchDisplayController.searchResultsTableView reloadData];

	olderThan = getfiletime();
	_loader(self, olderThan,32);
}
-(void)reload{
	if(self.isVisible)
		[self reloadFromServer];
	else{
		[self removeEvents];
	}
}
-(void)removeEvents{
	[_events removeAllObjects];
	[_uuid2events removeAllObjects];
	[_filteredEvents removeAllObjects];
	[_dates removeAllObjects];
	NSLog(@"%@: Removed all dates", [NSThread currentThread]);
	[self.tableView reloadData];
}
-(void)viewWillAppear:(BOOL)animated{
	if(_events.count==0)
		[self reloadFromServer];
	[super viewWillAppear:animated];
}
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	if(!runLoader)return;
	
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
	
    float reload_distance = 20;
    if(y > h + reload_distance) {
		runLoader=NO;
		_loader(self, olderThan, 32);
    }
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(_dates.count<=section)return nil;
    HeaderLabel *label = [[[HeaderLabel alloc] init] autorelease];
    label.text=[_dates objectAtIndex:section];
	label.backgroundColor=[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
    label.textAlignment=NSTextAlignmentRight;
    return label;
}
-(void)prependEvents:(NSArray *)events1D{

	if([self.refreshControl isRefreshing])
		[self.refreshControl endRefreshing];
//	[self.tableView beginUpdates];
	
	BOOL			searchWasActive = self.topPVC.searchController.active;
	
	for(NSMutableDictionary* entry in events1D) {

		[self addToMotionEventTable:entry];

		NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:((
																	[[entry objectForKey:@"filetime"]longLongValue] / 10000000) - EPOCH_DIFF)];
		[entry setObject:timestamp forKey:@"nsdate"];
		NSString* dateString = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		
		if(_dates.count>0 && [dateString isEqualToString:[_dates objectAtIndex:0]]){
			
			NSMutableArray* firstDay =[_events objectAtIndex:0];
			[firstDay insertObject:entry atIndex:0];
			
			NSMutableArray* firstDayFiltered=nil;
			if(searchWasActive && [self shouldAddToFilteredList:entry]){
				firstDayFiltered=[_filteredEvents objectAtIndex:0];
				[firstDayFiltered insertObject:entry atIndex:0];
			}
			
		}else{
			[_dates insertObject:dateString atIndex:0];
			
			NSMutableArray* firstDay =  [[NSMutableArray new] autorelease]; //[[@[entry] mutableCopy] autorelease];
			[firstDay addObject:entry];
			[_events insertObject:firstDay atIndex:0];

			NSMutableArray* firstDayFiltered=nil;
			if(searchWasActive){
				firstDayFiltered=[[NSMutableArray new] autorelease];
				[_filteredEvents insertObject:firstDayFiltered atIndex:0];
				if([self shouldAddToFilteredList:entry]){
					[firstDayFiltered addObject:entry];
				}
			}
			
		}
	}
//	[self.tableView endUpdates];
	[self.tableView reloadData];
	//if(searchWasActive)[self.searchDisplayController.searchResultsTableView reloadData];
	
}
-(void)addToMotionEventTable:(NSMutableDictionary*)entry
{
	if([[entry objectForKey:@"sensorType"] intValue]==0){  // Motion events
		NSString* uuid = entry.uuidFromEventEntry;
		if(uuid){
			NSMutableArray* motionEvents = [_uuid2events objectForKey:uuid];
			if(!motionEvents){
				motionEvents=[[NSMutableArray new]autorelease];
				[_uuid2events setObject:motionEvents forKey:uuid];
			}
			[motionEvents addObject:@[[entry objectForKey:@"filetime"], [entry objectForKey:@"eventText"]]];
		}
	}
}
-(void)appendEvents:(NSArray *)events1D{
	
	if(self.refreshControl.refreshing)
		[self.refreshControl endRefreshing];

	BOOL searchWasActive = self.topPVC.searchController.active;

	if(!searchWasActive)
		[self.tableView beginUpdates];
	
	for(NSMutableDictionary* entry in events1D) {
		[self addToMotionEventTable:entry];
		
		olderThan =[[entry objectForKey:@"filetime"] longLongValue];
		NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:((
																	olderThan / 10000000) - 11644473600)];
		[entry setObject:timestamp forKey:@"nsdate"];
		NSString* dateString = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		if(_dates.count>0 && [dateString isEqualToString:[_dates lastObject]]){
			
			NSMutableArray* lastDay =[_events lastObject];
			[lastDay addObject:entry];

			NSMutableArray* lastDayFiltered=nil;
			if(searchWasActive && [self shouldAddToFilteredList:entry]){
				lastDayFiltered=[_filteredEvents lastObject];
			   [lastDayFiltered addObject:entry];
			}
			
			if(!searchWasActive)
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_events.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];
			
		}else{
			[_dates addObject:dateString];

			if(!searchWasActive)
				[self.tableView insertSections:[NSIndexSet indexSetWithIndex:_dates.count-1] withRowAnimation:UITableViewRowAnimationFade];

			NSMutableArray* lastDay = [[NSMutableArray new] autorelease];
			[_events addObject:lastDay];
			[lastDay addObject:entry];
			
			NSMutableArray* lastDayFiltered=nil;
			if(searchWasActive){
				lastDayFiltered=[[NSMutableArray new] autorelease];
				[_filteredEvents addObject:lastDayFiltered];
				if([self shouldAddToFilteredList:entry]){
					[lastDayFiltered addObject:entry];
					//NSLog(@"adding section %d row %d", _dates.count-1, lastDayFiltered.count-1);
//					[self.searchDisplayController.searchResultsTableView  insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDayFiltered.count-1 inSection:_filteredEvents.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];
				}
			}
			if(!searchWasActive)
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_events.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	if(searchWasActive)[self.tableView reloadData];
	else  [self.tableView endUpdates];
	
	runLoader = (events1D.count>=32);
}
-(void)refresh{
	if(_events.count==0){
		olderThan = getfiletime();
		_loader(self,olderThan,32);
		return;
	}
	_newLoader(self, [[[[_events objectAtIndex:0] objectAtIndex:0] objectForKey:@"filetime"] longLongValue]);
}
- (void)viewDidLoad
{
    [super viewDidLoad];

	UIRefreshControl *refreshControl = [[[UIRefreshControl alloc] init] autorelease];
	[refreshControl addTarget:self action:@selector(refresh)
			 forControlEvents:UIControlEventValueChanged];
	self.refreshControl = refreshControl;
	
    // create a filtered list that will contain products for the search results table.
	_filteredEvents = [[NSMutableArray arrayWithCapacity:[_events count]] retain];
	
	/*if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];
    }*/
	
//	[self.tableView reloadData];
	
}
-(void)dealloc{
	[_dates release];
	[_filteredEvents release];
	[_events release];
	self.savedSearchTerm=nil;
	self.loader=nil;
	self.newLoader=nil;
	self.uuid2events=nil;
	[super dealloc];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
		return YES;
	}
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSLog(@"%@: numberOfSectionsInTableView: returning %ld", [NSThread currentThread], _dates.count);
/*	if (self.topPVC.searchController.active)
	{
        return [_filteredEvents count];
    }
	else*/
	return [_dates count];
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if(_dates.count<=section)
		return nil;
	return [_dates objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
	if (self.topPVC.searchController.active)
	{
        return [[_filteredEvents objectAtIndex:section] count];
    }
	else
		return [[_events objectAtIndex:section ] count];
}

/*-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	TagTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.showComment = !cell.showComment;
	[tableView beginUpdates];
	[tableView endUpdates];
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    
    if (!cell) {
		cell = [[[TagTableViewCell alloc] initForEventEntryWithID:@"eventCell"] autorelease];
    }
	
	NSDictionary *event;
	if (self.topPVC.searchController.active)
	{
		if(indexPath.section >= _filteredEvents.count)return cell;
		NSArray* s = [_filteredEvents objectAtIndex:indexPath.section];
		if(indexPath.row >= s.count)return cell;
        event = [s objectAtIndex:indexPath.row];
    }else{
		if(indexPath.section >= _events.count)return cell;
		NSArray* s =[_events objectAtIndex:indexPath.section];
		if(indexPath.row >= s.count)return cell;
		event = [s objectAtIndex:indexPath.row];
	}
	[cell setEventEntry:event];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

	/*
	NSDictionary *event;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		event = [[_filteredEvents objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	}else{
		event = [[_events objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	}

	return [event objectForKey:@"comment"]!=[NSNull null]?110.0: 56.0;*/
	
	return 56.0;
	
}
-(BOOL)withinScope:(NSDictionary*)event{
	NSInteger savedSearchScope = self.topPVC.savedSearchScopeEvc;
	if(savedSearchScope==0)return YES;
	NSInteger sensorType = [[event objectForKey:@"sensorType"] integerValue];
	if(savedSearchScope==1 && sensorType!=1 && sensorType!=11)return NO;
	if(savedSearchScope==2 && sensorType!=2 && sensorType!=3 && sensorType!=12)return NO;
	if(savedSearchScope==3 && sensorType!=7 && sensorType!=17)return NO;
	if(savedSearchScope==4 && sensorType!=0)return NO;
	if(savedSearchScope==5 && (sensorType<=3 || sensorType==7 || sensorType==11 || sensorType==12 || sensorType==17))return NO;
	return YES;
}
-(BOOL)shouldAddToFilteredList:(NSDictionary*) event{
	if(![self withinScope:event])return NO;
	NSString *tagName = [event objectForKey:@"tagName"];
	NSString *eventName = [event objectForKey:@"eventText"];
	
	if( _savedSearchTerm.length==0
	   || NSNotFound != [tagName rangeOfString:_savedSearchTerm options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location ||
	   NSNotFound != [eventName rangeOfString:_savedSearchTerm options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
	{
		return YES;
	}
	return NO;
}

// sensorType: 0 motion, 1,11 temp,  2, 12 cap, 3 water, 7, 17 lux, 
// 	eventScopes =@[@"All",@"Temp",@"RH",@"Lux", @"Motion",@"Other"];
- (void)filterListBySearchText:(NSString*)searchText scope:(NSInteger)scope
{
	[_filteredEvents removeAllObjects]; // First clear the filtered array.
	self.savedSearchTerm=searchText;
	self.topPVC.savedSearchScopeEvc = scope;
	
	for (int i=0;i<_events.count;i++)
	{
		NSArray* eventsDay = [_events objectAtIndex:i];
		NSMutableArray* filteredDay = [[NSMutableArray new] autorelease];
		[_filteredEvents addObject:filteredDay];
		for(NSDictionary* event in eventsDay){
			if([self shouldAddToFilteredList:event])
				[filteredDay addObject:event];
		}
	}
}
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self filterListBySearchText:searchString scope: searchController.searchBar.selectedScopeButtonIndex];
	[self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	[self updateSearchResultsForSearchController:self.topPVC.searchController];
}

/*
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterListBySearchText:searchString];
	searchWasActive=YES;
  // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	return NO;
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
	self.topPVC.navigationController.navigationBarHidden=YES;
}
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller{
	contentOffsetBeforeSearch = [self.tableView contentOffset];
}
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
	[self.tableView setContentOffset:contentOffsetBeforeSearch animated:YES];
	searchWasActive=NO;
	self.topPVC.navigationController.navigationBarHidden=NO;
}
*/

@end

