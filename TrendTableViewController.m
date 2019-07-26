#import "TrendTableViewController.h"
#import "NSTimer+Blocks.h"
#import "AsyncURLConnection.h"
#import "LoginController.h"
#import "EventsViewController.h"
#import "RawDataChart.h"

@interface TrendTableViewController ()

@end

@implementation TrendTableViewController
@synthesize savedSearchTerm=_savedSearchTerm;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate: (id<MasterViewControllerDelegate>) delegate
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (self) {
		_savedSearchTerm=nil;
		_filteredTrendList =[NSMutableArray new];
		[self setDelegate:delegate];
		
		self.automaticallyAdjustsScrollViewInsets = true;
		
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			self.clearsSelectionOnViewWillAppear = NO;
		}
		
		_reorderBtn =[[UIBarButtonItem alloc] initWithTitle:@"Arrange" style:UIBarButtonItemStylePlain target:self action:@selector(startReordering)];
		[self.navigationItem setRightBarButtonItem:_reorderBtn];

	}
	return self;
}

- (void)dealloc
{
	self.filteredTrendList=nil;
	self.savedSearchTerm=nil;
	self.trendList=nil;
	self.reorderBtn=nil;
	self.reorderDoneBtn=nil;
	self.pb2span=nil;
	self.uuid2events=nil;
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.tableView registerNib:[UINib nibWithNibName:@"TrendTableViewCell" bundle:nil] forCellReuseIdentifier:@"trendViewCell"];  //  Class:TrendTableViewCell.self forCellReuseIdentifier:@"trendViewCell"];
	[self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"TrendTableViewCell" bundle:nil] forCellReuseIdentifier:@"trendViewCell"];

	segmentedControl =
	[[[MultiSelectSegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Show Humidity", @"Show Lux", nil]] autorelease];
	segmentedControl.frame = CGRectMake(10, 10, self.tableView.frame.size.width-20, 34);
	segmentedControl.delegate = self;
	UIView* footer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)] autorelease];
	[footer addSubview:segmentedControl];
	self.tableView.tableFooterView = footer;
}
-(void)viewDidLayoutSubviews{
	segmentedControl.frame = CGRectMake(10, 10, self.tableView.frame.size.width-20, 34);
}
-(void)multiSelect:(MultiSelectSegmentedControl*) multiSelecSegmendedControl didChangeValue:(BOOL) value atIndex: (NSUInteger) index
{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveTrendsOption"]
						jsonObj:@{
								  @"showRH": [multiSelecSegmendedControl.selectedSegmentIndexes containsIndex:0] ?@YES:@NO,
								  @"showLux": [multiSelecSegmendedControl.selectedSegmentIndexes containsIndex:1] ?@YES:@NO
								  }
				  completeBlock:^(NSDictionary* retval){
					  [self loadFromServer];
				  }
					 errorBlock:^(NSError* err, id* showFrom)
	 			{
					return YES;
				} setMac:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	should_run_comet=NO;
	[comet cancel]; [comet release]; comet=nil;
}
-(void)viewDidAppear:(BOOL)animated{
	NSLog(@"tvc.viewWillAppear, _trendList=%@", _trendList);
	if(_trendList.count==0 || reloadPending)
		[self loadFromServer];
	else {
		[self setSplitViewRatio];
		if(comet==nil)[self getNextUpdate];
	}
	[super viewDidAppear:animated];
}

-(void)setSplitViewRatio{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		UISplitViewController* svc = (UISplitViewController*)self.topPVC.navigationController.parentViewController;
//		if(	svc.preferredPrimaryColumnWidthFraction<0.6){
			[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
				[UIView animateWithDuration:0.25f animations:^{
					svc.preferredPrimaryColumnWidthFraction=0.6;
				}];
			} repeats:NO];
//			self.topPVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
//		}
	}else{
		[NSTimer scheduledTimerWithTimeInterval:0.01 block:^{
			[self.tableView reloadData];
//			self.topPVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		} repeats:NO];
	}
}
-(void)updatePbiFromTrend:(NSMutableDictionary*)t{
	NSMutableArray* filetimes =[t objectForKey:@"filetime"];
	NSMutableArray* temperature =[t objectForKey:@"temperature"];
	NSMutableArray* rh = [t objectForKey:@"rh"];
	NSMutableArray* lux = [t objectForKey:@"lux"];
	
	while(filetimes.count>1){
		if([filetimes.firstObject longLongValue]==0){
			[filetimes removeObjectAtIndex:0];
			[temperature removeObjectAtIndex:0];
			if(rh!=nil && rh!=[NSNull null])
				[rh removeObjectAtIndex:0];
			if(lux!=nil && lux!=[NSNull null])
				[lux removeObjectAtIndex:0];
		}else
			break;
	}
	NSNumber* pbi = [t objectForKey:@"pbi"];
	if( pbi && [pbi intValue]!=0){
		double interval_avg=0;
		for(int i=1;i<filetimes.count;i++){
			interval_avg+=([filetimes[i] longLongValue] - [filetimes[i-1] longLongValue]);
		}
		interval_avg/=(filetimes.count-1);
		interval_avg/=10000000;
		if([pbi doubleValue]/interval_avg<1.2 && interval_avg/[pbi doubleValue]<1.2){
			NSMutableArray* span = [_pb2span objectForKey:pbi];
			if(span)
			{
				if( [filetimes.firstObject longLongValue] < [[span objectAtIndex:0] longLongValue] )
					[span replaceObjectAtIndex:0 withObject:filetimes.firstObject];
				if( [filetimes.lastObject longLongValue] > [[span objectAtIndex:1] longLongValue] )
					[span replaceObjectAtIndex:1 withObject:filetimes.lastObject];
			}
			else{
				[_pb2span setObject: [NSMutableArray arrayWithObjects:filetimes.firstObject, filetimes.lastObject, nil] forKey:pbi];
			}
		}else{
			[t removeObjectForKey:@"pbi"];
		}
	}
}

-(void)loadFromServer{
	reloadPending=NO;
	[comet cancel]; [comet release]; comet=nil;

	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetTrends"]
						jsonObj:@{
								  @"allTagManagers": [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]?@YES:@NO
								  }
				  completeBlock:^(NSDictionary* retval){
					  
					  NSDictionary* retd =    [retval objectForKey:@"d"];
					  
					  self.pb2span = [[NSMutableDictionary new] autorelease];
					  self.trendList = [retd objectForKey:@"trends"];
					  
					  BOOL anyCap=NO, anyLux=NO;

					  for(NSMutableDictionary* t in _trendList){
						  [self updatePbiFromTrend:t];
						  NSMutableArray* rh = [t objectForKey:@"rh"];
						  if(rh!=[NSNull null] && rh!=nil)anyCap=YES;
						  NSMutableArray* lux = [t objectForKey:@"lux"];
						  if(lux!=[NSNull null] && lux!=nil)anyLux=YES;
					  }
					  NSMutableIndexSet* set = [[NSMutableIndexSet new] autorelease];
					  if(anyCap)[set addIndex:0];
					  if(anyLux)[set addIndex:1];
					  segmentedControl.selectedSegmentIndexes = set;
					  
					  NSLog(@"GetTrends returned %ld trend", self.trendList.count);
					  
					  NSDate* serverNow =
					  [NSDate dateWithTimeIntervalSince1970:((
															  [[retd objectForKey:@"serverTime"] longLongValue] / 10000000) - 11644473600)];
					  NSDate* now = [[NSDate alloc] init];
					  serverTime2LocalTime = [serverNow timeIntervalSinceDate:now];
					  [now release];
					  
					  temp_unit = useDegF = [[[retd objectForKey:@"tms"] objectForKey:@"temp_unit"] intValue]==1;
					  
					  [self.tableView reloadData];
					  
					  [self setSplitViewRatio];
					  
					  [self getNextUpdate];			// restart getting comet using the new mac.
					  
				  }errorBlock:^(NSError* err, id* showFrom)
	 				{
					  should_run_comet=NO;
					  return YES;
				  } setMac:nil];
}
-(void)reload{
	if(self.isVisible){
		NSLog(@"tvc.reload called, isVisible=1, loadFromServer");
		[self loadFromServer];
	}else{
		NSLog(@"tvc.reload called, isVisible=0, set reloadPending=1");
		reloadPending=YES;
		[_trendList removeAllObjects];
	}
}
-(void)removeData{
	[_trendList removeAllObjects];
	self.uuid2events=nil;
}

-(void)getNextUpdate{
	should_run_comet=YES;
	if(comet!=nil)return;

	NSString* url, *soapAction, *xml;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]) {
		url=@"ethComet.asmx?op=GetNextTrendUpdateForAllManagers";
		soapAction = @"http://mytaglist.com/ethComet/GetNextTrendUpdateForAllManagers" ;
		xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetNextTrendUpdateForAllManagers xmlns=\"http://mytaglist.com/ethComet\" /></soap:Body></soap:Envelope>";
	}else{
		url=@"ethComet.asmx?op=GetNextTrendUpdate";
		soapAction = @"http://mytaglist.com/ethComet/GetNextTrendUpdate" ;
		xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetNextTrendUpdate xmlns=\"http://mytaglist.com/ethComet\" /></soap:Body></soap:Envelope>";
	}
	
	comet = [[AsyncSoapURLConnection soapRequest: [WSROOT stringByAppendingString: url]
																				soapAction: soapAction
																					   xml: xml
																			 completeBlock:^(id retval){

																				 NSMutableDictionary* t = retval;
																				 for(int i=0;i<_trendList.count;i++){
																					 if( [((NSDictionary*)[_trendList objectAtIndex:i]).uuid isEqualToString:t.uuid]  ){
																						 [self updatePbiFromTrend:t];
																						 
																						 [_trendList replaceObjectAtIndex:i withObject:t];
																						 
																						 if([self.searchDisplayController isActive])
																							 [self.searchDisplayController.searchResultsTableView reloadData];
																						 else
																						 {
																							 [self.tableView beginUpdates];
																							 [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
																							 [self.tableView endUpdates];
																						 }
																						 break;
																					 }
																				 }
																				 [comet release]; comet=nil;
																				 if(should_run_comet)
																					 [self getNextUpdate];
																				 
																			 }errorBlock:^(NSError* e, id* showFrom){
																				 [comet release]; comet=nil;
																				 if(should_run_comet)
																					 [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
																						 //[self getNextUpdate];
																						 [self reload];
																					 } repeats:NO];

																				 return NO;
																			 }] retain];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_trendList.count==0)return;
	
	NSDictionary *t;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		t = [_filteredTrendList objectAtIndex:indexPath.row];
	}else{
		t = [_trendList objectAtIndex:[indexPath row]];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[_delegate tagSelected:t.uuid fromCell:[tableView cellForRowAtIndexPath:indexPath]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return  180;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		return _filteredTrendList.count;
	}else{
		return _trendList.count;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TrendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trendViewCell" forIndexPath:indexPath];
	if(cell==nil)
		cell = 	(TrendTableViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"TrendTableViewCell"
																	 owner:self  options:nil] objectAtIndex:0];

 

	NSMutableDictionary* t;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		if(indexPath.row >= _filteredTrendList.count)return cell;
		t = [_filteredTrendList objectAtIndex:indexPath.row];
	}
	else{
		if(indexPath.row >= _trendList.count)return cell;
		t = [_trendList objectAtIndex:indexPath.row];
	}

	/*TrendTableViewCell *cell = [t objectForKey:@"cell"];
	if(cell==nil){
		cell = 	(TrendTableViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"TrendTableViewCell"
																	 owner:nil  options:nil] objectAtIndex:0];
		
		[t setObject:cell forKey:@"cell"];
	}*/

	
	id events = [_uuid2events objectForKey:t.uuid];
	if(events){
		NSArray* filetimes = [t objectForKey:@"filetime"];
		NSMutableArray* eventsToShow = [[NSMutableArray new]autorelease];
		// find only those between filetimes.firstObject, filetimes.lastObject
		for(NSArray* e in events){
			NSNumber* event_filetime = [e objectAtIndex:0];
			if( [event_filetime longLongValue]> [filetimes.firstObject longLongValue] && [event_filetime longLongValue]<[filetimes.lastObject longLongValue]){
				NSString* eventText =[e objectAtIndex:1];
				if(NO==[eventText hasPrefix:@"is closed"])
					[eventsToShow addObject:e];
			}
		}
		[eventsToShow sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
			return [((NSArray*)obj1).firstObject compare:((NSArray*)obj2).firstObject];
		}];
		
		[t setObject:eventsToShow forKey:@"events"];
	}

//	dispatch_async(dispatch_get_main_queue(), ^{
		NSNumber* pbi = [t objectForKey:@"pbi"];
		if(pbi)
			[cell setTrend:t useDegF:useDegF andFiletimeSpan:[_pb2span objectForKey:pbi]];
		else
			[cell setTrend:t useDegF:useDegF andFiletimeSpan:nil];
		//});

	//[cell.chart setNeedsDisplay];
	return cell;
}


-(void)reorderDoneButtonPressed{
	[self setEditing:NO animated:YES];
	[self.topPVC.navigationItem setRightBarButtonItem:_reorderBtn];
	self.reorderDoneBtn=nil;
}
-(void)startReordering{
//	if(!self.isVisible || !should_run_comet)return;
	
	self.reorderDoneBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																		 target:self action:@selector(reorderDoneButtonPressed)] autorelease];
	
	[self.topPVC.navigationItem setRightBarButtonItem:_reorderDoneBtn];
	[self setEditing:YES animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleNone;
}
-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSLog(@"from=%ld, to=%ld", sourceIndexPath.row, destinationIndexPath.row);
	
	NSDictionary* tag1 = [[_trendList objectAtIndex:sourceIndexPath.row] retain];
	NSString* tag_prev = destinationIndexPath.row==0? nil : ((NSDictionary*)[_trendList objectAtIndex:destinationIndexPath.row-1]).uuid;
	NSString* tag_next = destinationIndexPath.row == _trendList.count-1? nil : ((NSDictionary*)[_trendList objectAtIndex:destinationIndexPath.row]).uuid;
	[_delegate swapOrderOf:tag1.uuid between:tag_prev and:tag_next];

	[_trendList removeObjectAtIndex:sourceIndexPath.row];
	[_trendList insertObject:tag1 atIndex:destinationIndexPath.row];
	[tag1 release];
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


-(BOOL)shouldAddToFilteredList:(NSDictionary*) trend{
	NSString *tagName = trend.name;
	
	if(NSNotFound != [tagName rangeOfString:_savedSearchTerm options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
	{
		return YES;
	}
	return NO;
}
#pragma mark UISearchDisplayController Delegate Methods
- (void)filterListBySearchText:(NSString*)searchText
{
	[_filteredTrendList removeAllObjects]; // First clear the filtered array.
	self.savedSearchTerm=searchText;
	
	for (int i=0;i<_trendList.count;i++)
	{
		NSDictionary* t = [_trendList objectAtIndex:i];
		if([self shouldAddToFilteredList:t])
			[_filteredTrendList addObject:t];
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[self filterListBySearchText:searchString];
	searchWasActive=YES;
	return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	return NO;
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
}
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller{
	contentOffsetBeforeSearch = [self.tableView contentOffset];
	self.navigationController.navigationBarHidden=YES;
}
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
	searchWasActive=NO;
	self.navigationController.navigationBarHidden=NO;
	[self.tableView setContentOffset:contentOffsetBeforeSearch animated:YES];
}

@end
