//
//  DropcamViewController.m
//  MyTagList2
//
//  Created by cao on 10/31/14.
//
//

#import "DropcamViewController.h"
#import "Tag.h"
@implementation NSString(Shots)

-(int64_t)filetime{
	return [[self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"vt"]] longLongValue];
}
-(NSDate*)nsdate{
	return [NSDate dateWithTimeIntervalSince1970:((
											[self filetime] / 10000000) - 11644473600)];
}
@end
@implementation DropcamViewController

-(void)loadOlderThan:(int64_t)olderThan topN:(int)topN{
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"DropCamLink.asmx/GetSnapshots2"]
						jsonObj:@{@"slaveId": [NSNumber numberWithInt:_tag.slaveId],
								  @"topN": [NSNumber numberWithInt:topN], @"olderThan": [NSNumber numberWithLongLong:olderThan],
								  @"includeVideos": [NSNumber numberWithBool:YES]  }
				  completeBlock:^(NSDictionary* data){
					  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
					  [self append:[data objectForKey:@"d"]];
				  }errorBlock:^(NSError* err, id* showFrom){
					  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
					  return YES;
				  }setMac:self.xSetMac ];
}
-(void)loaderNewerThan:(int64_t) newerThan{
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
	[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/GetNewSnapshots2"]
						jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId],
								   @"newerThan": [NSNumber numberWithLongLong:newerThan], @"includeVideos": [NSNumber numberWithBool:YES]}
				  completeBlock:^(NSDictionary* data){
					  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
					  [self prepend:[data objectForKey:@"d"]];
				  }errorBlock:^(NSError* err, id* showFrom){
					  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
					  return YES;
				  }setMac:self.xSetMac ];
}

//- (id)initForTag:(NSMutableDictionary*) tag withLoader:(downloadShotsBlock_t) loader andNewLoader:(downloadNewShotsBlock_t)newLoader;
- (id)initForTag:(NSMutableDictionary*) tag
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	
	if(self){
		self.tag=tag;
		//self.loader = loader;
		//self.newLoader = newLoader;
		self.title=tag.name;
		_dates=[NSMutableArray new];
		_shots=[NSMutableArray new];
		_olderThan = getfiletime();
	}
	return self;
}

-(void)reload{
	[_shots removeAllObjects];
	[_dates removeAllObjects];
	[self.tableView reloadData];
	_olderThan = getfiletime();
	[self loadOlderThan:_olderThan topN:32];
}
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	if(!_runLoader)return;
	
	CGPoint offset = aScrollView.contentOffset;
	CGRect bounds = aScrollView.bounds;
	CGSize size = aScrollView.contentSize;
	UIEdgeInsets inset = aScrollView.contentInset;
	float y = offset.y + bounds.size.height - inset.bottom;
	float h = size.height;
	
	float reload_distance = 20;
	if(y > h + reload_distance) {
		_runLoader=NO;
		[self loadOlderThan:_olderThan topN:32];
	}
}

/*-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(section==0)return nil;
	HeaderLabel *label = [[[HeaderLabel alloc] init] autorelease];
	label.text=[_dates objectAtIndex:section-1];
	label.backgroundColor=[UIColor colorWithWhite:1 alpha:0.8];
	label.textAlignment=NSTextAlignmentRight;
	return label;
}*/
-(void)prepend:(NSArray *)snapshots{
	
//	[self.refreshControl endRefreshing];
	
	[self.tableView beginUpdates];
	BOOL insertedSection=NO;
	for(NSString* entry in snapshots) {
		if([entry hasSuffix:@"t"])self.timeLapseFn=entry;
		
		NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:((
																	[entry longLongValue] / 10000000) - 11644473600)];
		NSString* dateString = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		
		if(_dates.count>0 && [dateString isEqualToString:[_dates objectAtIndex:0]]){
			
			NSMutableArray* firstDay =[_shots objectAtIndex:0];
			[firstDay insertObject:entry atIndex:0];
			
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1 ]] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			if(!insertedSection)
				[self.tableView endUpdates];
			insertedSection=YES;

			//[self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
			//[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _dates.count)]
			//			  withRowAnimation:UITableViewRowAnimationTop];
			[_dates insertObject:dateString atIndex:0];
			
			NSMutableArray* firstDay = [[@[entry] mutableCopy] autorelease];
			[_shots insertObject:firstDay atIndex:0];

			//[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1 ]] withRowAnimation:UITableViewRowAnimationTop];
		}
	}
	if(insertedSection)
		[self.tableView reloadData];
	else
		[self.tableView endUpdates];
	
}
-(void)append:(NSArray *)snapshots{
	
//	if(self.refreshControl.refreshing)
	//	[self.refreshControl endRefreshing];
	
	//	if(searchWasActive)[self.searchDisplayController.searchResultsTableView beginUpdates];
	[self.tableView beginUpdates];
	
	for(NSString* entry in snapshots) {
		
		if([entry hasSuffix:@"t"])
		{
			if(!_tag.beeping)continue;
			self.timeLapseFn=entry;
		}
		
		_olderThan =[entry filetime];
		NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:((
																	_olderThan / 10000000) - 11644473600)];
		NSString* dateString = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		if(_dates.count>0 && [dateString isEqualToString:[_dates objectAtIndex:_dates.count-1]]){
			
			NSMutableArray* lastDay =[_shots objectAtIndex:_shots.count-1];
			[lastDay addObject:entry];
			
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_shots.count ]] withRowAnimation:UITableViewRowAnimationFade];
		}else{
			[_dates addObject:dateString];
			
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:_dates.count] withRowAnimation:UITableViewRowAnimationFade];
			
			NSMutableArray* lastDay = [[NSMutableArray new] autorelease];
			[_shots addObject:lastDay];
			[lastDay addObject:entry];
			
			[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastDay.count-1 inSection:_shots.count ]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	//if(searchWasActive)[self.searchDisplayController.searchResultsTableView endUpdates];
	[self.tableView endUpdates];
	_runLoader = (snapshots.count>=32);
}

-(void)refresh{
	if(_shots.count==0 || [[_shots objectAtIndex:0] count]==0){
		_olderThan = getfiletime();
		[self loadOlderThan:_olderThan topN:32];

		return;
	}
	[self loaderNewerThan:[[[_shots objectAtIndex:0] objectAtIndex:0] longLongValue]];
}
-(void)timeLapseBtnUpdate:(BOOL)started{
	if(started)timeLapseCell.title=@"Stop time lapse";
	else timeLapseCell.title=@"Start time lapse";
}
-(void)updateTag:(NSMutableDictionary*)tag{
	if(!_tag.beeping && tag.beeping)[self timeLapseBtnUpdate:YES];
	else if(_tag.beeping && !tag.beeping)[self timeLapseBtnUpdate:NO];
	self.tag=tag;
	[self refresh];
}
-(void)editAction:(id)sender{

	if(self.tableView.isEditing){
		[self.tableView setEditing:NO animated:YES];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)] autorelease];

	}else{
		[self.tableView setEditing:YES animated:YES];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editAction:)] autorelease];
	}
}
-(void)recordVideoFor:(int)seconds{
	[recordVideoCell showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/RecordVideo"]
						jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId],  @"second": [NSNumber numberWithInt:seconds] }
				  completeBlock:^(NSDictionary* data){
					  [recordVideoCell revertLoading];
					  [self prepend:[data objectForKey:@"d"]];
				  }errorBlock:^(NSError* err, id* showFrom){
					  [recordVideoCell revertLoading];
					  *showFrom=recordVideoCell;
					  return YES;
				  }setMac:self.xSetMac ];
}
-(void)recordTimeLapseFor:(int)minutes{
	[timeLapseCell showLoading];

	[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/RecordTimeLapse"]
						jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId],  @"minute": [NSNumber numberWithInt:minutes] }
				  completeBlock:^(NSDictionary* data){
					  [timeLapseCell revertLoading];
					  [self prepend:@[[data objectForKey:@"d"]]];
					  _tag.beeping=YES;
					  [self timeLapseBtnUpdate:YES];
				  }errorBlock:^(NSError* err, id* showFrom){
					  [timeLapseCell revertLoading];
					  *showFrom=timeLapseCell;
					  return YES;
				  }setMac:self.xSetMac ];
}
-(void)stopTimeLapse{
	[timeLapseCell showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/StopTimeLapse"]
						jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId] }
				  completeBlock:^(NSDictionary* data){
					  [timeLapseCell revertLoading];
					  [self prepend:@[[data objectForKey:@"d"]]];
					  _tag.beeping=NO;
					  [self timeLapseBtnUpdate:NO];
					  
					  for(NSInteger i=0;i<_shots.count;i++){
						  NSArray* day = [_shots objectAtIndex:i];
						  for(NSInteger j =0;j<day.count;j++){
							  if([_timeLapseFn isEqualToString:[day objectAtIndex:j]]){
								[self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i+1]];
								  break;
							  }
						  }
					  }
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  [timeLapseCell revertLoading];
					  *showFrom=timeLapseCell;
					  return YES;
				  }setMac:self.xSetMac ];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section==0){
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		if(cell == snapshotCell){
			[snapshotCell showLoading];
			[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/Snapshot"]
								jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId],  @"number": @1 }
						  completeBlock:^(NSDictionary* data){
							  [snapshotCell revertLoading];
							  [self prepend:[data objectForKey:@"d"]];
						  }errorBlock:^(NSError* err, id* showFrom){
							  [snapshotCell revertLoading];
							  *showFrom=snapshotCell;
							  return YES;
						  }setMac:self.xSetMac ];
		}else if(cell == recordVideoCell){
			ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
			[sheet addRedButtonWithTitle:@"5 second video" block:^(NSInteger index){
				[self recordVideoFor:5];
			}];
			[sheet addButtonWithTitle:@"10 second video" block:^(NSInteger index){
				[self recordVideoFor:10];
			}];
			[sheet addButtonWithTitle:@"15 second video" block:^(NSInteger index){
				[self recordVideoFor:15];
			}];
			[sheet addButtonWithTitle:@"20 second video" block:^(NSInteger index){
				[self recordVideoFor:20];
			}];
			[sheet addButtonWithTitle:@"30 second video" block:^(NSInteger index){
				[self recordVideoFor:30];
			}];
			[sheet addButtonWithTitle:@"45 second video" block:^(NSInteger index){
				[self recordVideoFor:45];
			}];
			[sheet addButtonWithTitle:@"1 minute video" block:^(NSInteger index){
				[self recordVideoFor:60];
			}];
			[sheet addCancelButtonWithTitle:@"Cancel"];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromRect:cell.bounds inView:cell.contentView animated:YES];
			else [sheet showInView:[[self view] window]];
			[sheet release];
		}else if(cell == timeLapseCell){
			if(_tag.beeping){
				[self stopTimeLapse];
			}else{
				ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
				[sheet addRedButtonWithTitle:@"2 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:120];
				}];
				[sheet addButtonWithTitle:@"3 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:180];
				}];
				[sheet addButtonWithTitle:@"6 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:360];
				}];
				[sheet addButtonWithTitle:@"12 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:720];
				}];
				[sheet addButtonWithTitle:@"24 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:1440];
				}];
				[sheet addButtonWithTitle:@"48 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:2880];
				}];
				[sheet addButtonWithTitle:@"72 hour to 90 seconds" block:^(NSInteger index){
					[self recordTimeLapseFor:4320];
				}];
				[sheet addCancelButtonWithTitle:@"Cancel"];
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromRect:cell.bounds inView:cell.contentView animated:YES];
				else [sheet showInView:[[self view] window]];
				[sheet release];
			}
		}
	}else{
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		NSString *shot  = [[_shots objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row];
		if([shot hasSuffix:@"v"]){
			[self playVideo:shot fromCell:cell];
		}else if([shot hasSuffix:@"t"]){
			[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"DropCamLink.asmx/GetTimeLapseInfo"]
								jsonObj:@{@"slaveId": [NSNumber numberWithInt:_tag.slaveId]}
						  completeBlock:^(NSDictionary* retval){
							  NSDictionary* stat = [retval objectForKey:@"d"];
							  
							  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
							  iToast* t =[[iToast makeText:@"Time lapse is under way."
												 andDetail:[NSString stringWithFormat:@"Will finish at: %@\nCurrent progress: %.0f%%, %d frames captured\nStarted at %@", [stat nsdateFor:@"endTime"], [[stat objectForKey:@"completed"] floatValue]*100,
															[[stat objectForKey:@"currentSeq"] intValue], [stat nsdateFor:@"startTime"]
															]] setDuration:iToastDurationLong];
							  [t showFrom:cell];
							  
						  }errorBlock:^(NSError* err, id* showFrom){
							  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
							  *showFrom = cell;
							  return YES;
						  }setMac:self.xSetMac ];
		}
		else{
			[self viewImage:shot fromCell:cell];
		}
	}
}

-(void)playVideo:(NSString*)fn fromCell:(UITableViewCell*)cell{
	MPMoviePlayerViewController* pc = [[MPMoviePlayerViewController alloc]
					   initWithContentURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@webcams/%@/%@.mp4", WSROOT, _tag.uuid, fn]]];

	
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		if([pc respondsToSelector:@selector(setPreferredContentSize:)])
			pc.preferredContentSize=CGSizeMake(768,432);
		pc.contentSizeForViewInPopover = CGSizeMake(768,432);
		
		pc.navigationItem.title =
		[NSDateFormatter localizedStringFromDate:[fn nsdate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];

		UIPopoverController *pvc = [[[UIPopoverController alloc] initWithContentViewController:
									 [[[UINavigationController alloc]initWithRootViewController:pc]autorelease]] autorelease];
		
		[pvc presentPopoverFromRect:cell.bounds inView:cell.contentView
							  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}else{
		[self presentMoviePlayerViewControllerAnimated:pc];
	}
	[pc.moviePlayer play];
	[pc release];
}
-(void)viewWillAppear:(BOOL)animated{
	self.navigationController.toolbarHidden=YES;
	[super viewWillAppear:animated];
}

-(void)viewImage:(NSString*)path fromCell:(UITableViewCell*)cell{
	[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;

	// Instantiate and set up the coverImageViewController.
	[WebImageOperations processImageDataWithURLString:[NSString stringWithFormat:@"%@webcams/%@/%@.jpg",WSROOT,
													   _tag.uuid, path]
											 andBlock:^(NSData *d) {
												 
												 [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
												 
												 UIImage* image = [[[UIImage alloc]initWithData:d] autorelease];
												 if(image!=nil){
													 UIViewController *ivc = [[[UIViewController alloc] init] autorelease];
													 ivc.navigationItem.title =
													 [NSDateFormatter localizedStringFromDate:[path nsdate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
													 
													 if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
													  
													  if([ivc respondsToSelector:@selector(setPreferredContentSize:)])
														  ivc.preferredContentSize=CGSizeMake(768,432);
													  ivc.contentSizeForViewInPopover = CGSizeMake(768,432);
														 
													  UIPopoverController *pvc = [[[UIPopoverController alloc] initWithContentViewController:[[[UINavigationController alloc]initWithRootViewController:ivc]autorelease]] autorelease];
													  
													  [pvc presentPopoverFromRect:cell.bounds inView:cell.contentView
													  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
													  
													  }else{
														  // Desperate attempts to make image display below the status bar.
														  [ivc setModalPresentationStyle:UIModalPresentationFullScreen];
														  [ivc wantsFullScreenLayout];
														  
														  // Make the window visible. Without a visible window the modal view won't come up.
														  //[_window makeKeyAndVisible];
														  //[self presentViewController:coverImageViewController animated:YES completion:nil];
														  [self.navigationController pushViewController:ivc animated:YES];
													  }
													 UIImageView *iv = [[[UIImageView alloc] initWithImage:image] autorelease];
													 iv.contentMode = UIViewContentModeScaleAspectFit;
													 [ivc setView:iv];
												 }
												 
											 }];

}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section>0;
}
// [snapshot] [record video] [make time lapse/stop time lapse]
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section>0? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}
-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return YES;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if(editingStyle==UITableViewCellEditingStyleDelete)
	{
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/DeleteSnapshot"]
							jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId],
									   @"fn": [[_shots objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] }
					  completeBlock:^(NSDictionary* data){
						  [[_shots objectAtIndex:indexPath.section-1] removeObjectAtIndex:indexPath.row];
						  [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
					  }errorBlock:^(NSError* err, id* showFrom){
						  *showFrom=[tableView cellForRowAtIndexPath:indexPath];
						  return YES;
					  }setMac:self.xSetMac ];
	}
}
-(NSString*)xSetMac{
	if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])
		return _tag.mac;
	else
		return nil;
}
-(void)releaseSubViews
{
	[snapshotCell release]; snapshotCell=nil;
	[recordVideoCell release]; recordVideoCell=nil;
	[timeLapseCell release]; timeLapseCell=nil;
}
- (void)viewDidUnload
{
	[super viewDidUnload];
	[self releaseSubViews];
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)] autorelease];
	
/*	UIRefreshControl *refreshControl = [[[UIRefreshControl alloc] init] autorelease];
	[refreshControl addTarget:self action:@selector(refresh)
			 forControlEvents:UIControlEventValueChanged];
	self.refreshControl = refreshControl;
*/
	snapshotCell = [TableLoadingButtonCell newWithTitle:@"Take snapshot" Progress:@"Taking..." andIcon:@"icon_snapshot.png"];
	recordVideoCell =[TableLoadingButtonCell newWithTitle:@"Record short video" Progress:@"Recording..."];
	timeLapseCell =[TableLoadingButtonCell newWithTitle:@"" Progress:@"Working..." andIcon:@"icon_timelapse.png"];
	[self timeLapseBtnUpdate:_tag.beeping];
	
//	[self.tableView reloadData];
}
-(void)dealloc{
	[self releaseSubViews];
	[_dates release];
	[_shots release];
	self.tag=nil;
	self.timeLapseFn=nil;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [_shots count]+1;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if(section==0)return nil;
	return [_dates objectAtIndex:section-1];
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
	if(section==0)return 3;
	return [[_shots objectAtIndex:section-1 ] count];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	[[TagTableViewCell shotsCache] removeAllObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0){
		switch (indexPath.row) {
			case 0: return snapshotCell;
			case 1: return recordVideoCell;
			case 2: return timeLapseCell;
		}
		return nil;
	}else{
		TagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shotsCell"];
		
		if (!cell) {
			cell = [[[TagTableViewCell alloc] initForShotEntryWithID:@"shotsCell"] autorelease];
		}
		
		NSString *shot  = [[_shots objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row];
		[cell setShotEntry:shot forTag:_tag];
		return cell;
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section==0?44:102;
}


@end
