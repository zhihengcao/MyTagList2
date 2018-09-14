#import "EventsViewController.h"


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
@synthesize mvc_left, mvc_right, evc_left, evc_right;

-(id)initWithMvc:(MasterViewController*)mvc andEvc:(EventsViewController*)evc{
	self= [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
								 options:nil];
	if(self){
		self.mvc = mvc;
		self.evc_left=mvc.navigationItem.leftBarButtonItem;
		self.mvc_right=mvc.navigationItem.rightBarButtonItem;
		self.evc_right  = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tags",nil) style:UIBarButtonItemStylePlain
																	   target:self action:@selector(openMvc:)] autorelease];
		self.mvc_left =[[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Events",nil) style:UIBarButtonItemStylePlain
												  target:self action:@selector(openEvc:)] autorelease];
		mvc.topPVC = self;
		self.evc=evc;
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
	self.evc_right=nil;
	self.evc_left=nil;
	self.mvc_right=nil;
	self.mvc_left=nil;
	self.pcDots=nil;
	[super dealloc];
}
-(BOOL)isMVCVisible{
	return self.navigationController.topViewController==self && _pcDots.currentPage==1;
}
-(UINavigationItem*)navigationItem{
	return _mvc.navigationItem;
//	if(_pcDots.currentPage==0)return _evc.navigationItem;
//	else return _mvc.navigationItem;
}

/*-(NSArray*)toolbarItems{
	return _mvc.toolbarItems;
}*/

-(void)openMvcNoAnimation{
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	[self setMvcBar];
}
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

-(void)viewDidLoad{
	[super viewDidLoad];

	//self.automaticallyAdjustsScrollViewInsets = false;
	//[[self view] setFrame:CGRectMake(0, 0, [[self view] bounds].size.width, [[self view] bounds].size.height + 37)];
	[self openMvcNoAnimation];
	
	UINavigationController *navController = self.navigationController;
    CGSize navBarSize = navController.navigationBar.bounds.size;
    CGPoint origin = CGPointMake( navBarSize.width/2, navBarSize.height*5.0/6.0 );
    self.pcDots = [[[UIPageControl alloc] initWithFrame:CGRectMake(origin.x, origin.y,
                                                                       0, 0)] autorelease];
	//[UIPageControl appearance].pageIndicatorTintColor = [UIColor colorWithRed:1.0 green:(float)0x6b/(float)0xff blue:(float)0x5f/(float)0xff alpha:0.25];
	//[UIPageControl appearance].currentPageIndicatorTintColor =[UIColor colorWithRed:1.0 green:(float)0x6b/(float)0xff blue:(float)0x5f/(float)0xff alpha:1];
	[UIPageControl appearance].pageIndicatorTintColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.25];
	[UIPageControl appearance].currentPageIndicatorTintColor =[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    [_pcDots setNumberOfPages:2];
	[_pcDots setCurrentPage:1];
    [navController.navigationBar addSubview:_pcDots];
}
-(void)openEvc:(id)sender{
	
	[self setViewControllers:@[_evc] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished){
	}];
	[self setEvcBar];
}
-(void)openMvc:(id)sender{
	[self setViewControllers:@[_mvc] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
	}];
	[self setMvcBar];
}

-(void)setEvcBar{
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
	} completion:^(BOOL finished) {
	}];
	
//	self.navigationItem.leftBarButtonItem =
}
-(void)setMvcBar{
	[_pcDots setCurrentPage:1];
	
	[self.navigationController setToolbarHidden:NO animated:NO];
	
	self.navigationItem.title=_mvc.title;
	self.navigationItem.leftBarButtonItem = mvc_left;
	self.navigationItem.rightBarButtonItem = mvc_right;

	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UINavigationBar appearance].tintColor;
	} completion:^(BOOL finished) {
	}];

}
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{

	if(!completed)return;
	if([previousViewControllers objectAtIndex:0]==_mvc){
		[self setEvcBar];
	}else{
		[self setMvcBar];
	}
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if(viewController==_mvc){
		return _evc;
	}
	else{
		return nil;
	}
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	if(viewController==_evc){
		return _mvc;
	}
	else{
		return nil;
	}
}

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
		_filteredEvents=[NSMutableArray new];
		olderThan = getfiletime();
	}
	return self;
}
-(void)reload{
	[_events removeAllObjects];
	[_filteredEvents removeAllObjects];
	[_dates removeAllObjects];
	[self.tableView reloadData];
	if(searchWasActive)
		[self.searchDisplayController.searchResultsTableView reloadData];
	olderThan = getfiletime();
	_loader(self, olderThan,32);
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
    HeaderLabel *label = [[[HeaderLabel alloc] init] autorelease];
    label.text=[_dates objectAtIndex:section];
    label.backgroundColor=[UIColor colorWithWhite:1 alpha:0.8];
    label.textAlignment=NSTextAlignmentRight;
    return label;
}
-(void)prependEvents:(NSArray *)events1D{

	if([self.refreshControl isRefreshing])
		[self.refreshControl endRefreshing];
//	[self.tableView beginUpdates];
	
	for(NSMutableDictionary* entry in events1D) {

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
			
//			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0 ]] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[_dates insertObject:dateString atIndex:0];
//			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
			
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
			
//			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0 ]] withRowAnimation:UITableViewRowAnimationTop];
		}
	}
//	[self.tableView endUpdates];
	[self.tableView reloadData];
	if(searchWasActive)[self.searchDisplayController.searchResultsTableView reloadData];
	
}
-(void)appendEvents:(NSArray *)events1D{
	
	if(self.refreshControl.refreshing)
		[self.refreshControl endRefreshing];

//	if(searchWasActive)[self.searchDisplayController.searchResultsTableView beginUpdates];
	[self.tableView beginUpdates];
	
	for(NSMutableDictionary* entry in events1D) {
		olderThan =[[entry objectForKey:@"filetime"] longLongValue];
		NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:((
																	olderThan / 10000000) - 11644473600)];
		[entry setObject:timestamp forKey:@"nsdate"];
		NSString* dateString = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		if(_dates.count>0 && [dateString isEqualToString:[_dates objectAtIndex:_dates.count-1]]){
			
			NSMutableArray* lastDay =[_events objectAtIndex:_events.count-1];
			[lastDay addObject:entry];
			NSMutableArray* lastDayFiltered=nil;
			if(searchWasActive && [self shouldAddToFilteredList:entry]){
				lastDayFiltered=[_filteredEvents objectAtIndex:_filteredEvents.count-1];
			   [lastDayFiltered addObject:entry];
			}
			/*if(searchWasActive)
				[self.searchDisplayController.searchResultsTableView  insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDayFiltered.count-1 inSection:_filteredEvents.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];*/

			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_events.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];
		}else{
			[_dates addObject:dateString];
			/*if(searchWasActive)
				[self.searchDisplayController.searchResultsTableView insertSections:[NSIndexSet indexSetWithIndex:_dates.count-1] withRowAnimation:UITableViewRowAnimationFade];*/

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
			
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_events.count-1 ]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	//if(searchWasActive)[self.searchDisplayController.searchResultsTableView endUpdates];
	[self.tableView endUpdates];
	if(searchWasActive)[self.searchDisplayController.searchResultsTableView reloadData];
	
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
	
	if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];
    }
	
//	[self.tableView reloadData];
	
}
-(void)dealloc{
	[_dates release];
	[_filteredEvents release];
	[_events release];
	self.savedSearchTerm=nil;
	self.loader=nil;
	self.newLoader=nil;
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
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [_filteredEvents count];
    }
	else
		return [_events count];
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return [_dates objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
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
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        event = [[_filteredEvents objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }else{
		event = [[_events objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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
-(BOOL)shouldAddToFilteredList:(NSDictionary*) event{
	NSString *tagName = [event objectForKey:@"tagName"];
	NSString *eventName = [event objectForKey:@"eventText"];
	
	if(NSNotFound != [tagName rangeOfString:_savedSearchTerm options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
	{
		return YES;
	}
	if(NSNotFound != [eventName rangeOfString:_savedSearchTerm options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
	{
		return YES;
	}
	return NO;
}
#pragma mark UISearchDisplayController Delegate Methods
- (void)filterListBySearchText:(NSString*)searchText
{
	[_filteredEvents removeAllObjects]; // First clear the filtered array.
	self.savedSearchTerm=searchText;
	
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


@end

