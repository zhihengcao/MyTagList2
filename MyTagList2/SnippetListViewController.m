//
//  SnippetListViewController.m
//  MyTagList2
//
//  Created by cao on 9/24/13.
//
//

#import "SnippetListViewController.h"
#import "OptionPicker.h"
#import "ActionSheetDatePicker.h"
#import "OptionsViewController.h"
#import "MapRegionPicker.h"
#import "AsyncURLConnection.h"
#import "iToast.h"

@implementation  ScriptLogEntry
@synthesize msg, time;
-(void)dealloc{
	self.msg=nil; self.time=nil;
	[super dealloc];
}
@end

@implementation ScriptConfigViewController
@synthesize name=_name, placeHolders=_placeHolders, schedules=_schedules, regions=_regions, delegate=_delegate, literals=_literals, literalsCells=_literalsCells, phones=_phones, logs=_logs;

static NSArray* mobileDevices = nil;

- (id)initWithName: (NSString*)n andLogs:(NSArray*)logs andPlaceHolders:(NSArray*) p andSchedules:(NSArray*) s andRegions:(NSArray*) r andLiterals:(NSArray *)l andPhones:(NSArray *)phones andDelegate:(id<ScriptConfigViewControllerDelegate>)delegate Done:(scriptConfigDoneBlock_t)done DonwloadLog:(downloadScriptLogBlock_t)downloadLog{

	self = [super initWithStyle:UITableViewStyleGrouped];
	
	if(self){
		_done=[done copy];
		_downloadLog = [downloadLog copy];
		self.name = n;
		_logs = [logs retain];
		self.placeHolders = p;
		self.schedules = s;
		self.regions = r;
		self.literals = l;
		self.phones = phones;
		self.delegate = delegate;

		pCount=_placeHolders.count;
		sCount=_schedules.count;
		rCount=_regions.count;
		lCount=_literals.count;

		if(p!=nil)
			for(NSMutableDictionary* ph in p){
				NSMutableArray* uuids = [ph objectForKey:@"uuids"];
				if(uuids == (id)[NSNull null]){
					//NSLog(@"supportedTypes: %d,%d,%d",[ph objectForKey:@"supportedTypes"],nil)
					uuids = [NSMutableArray arrayWithObjects:[_delegate listOnlyUuidOfTagWithTypes:[ph objectForKey:@"supportedTypes"]], nil];
					if(uuids.count==1)
						[ph setObject:uuids forKey:@"uuids"];
				}
			}

		self.title = @"Configure App";
		currentEditSection = -1;
		geocoder = [[CLGeocoder alloc]init];
		day_of_week = [[NSArray
						arrayWithObjects:@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday",@"Friday", @"Saturday", nil] retain];
		tod_f = [[NSDateFormatter alloc] init] ; 	[tod_f setDateFormat:@"h:mm a"];

	}
	return self;
}
- (void)dealloc
{
	[_done release];
	[_downloadLog release];
	[self releaseSubViews];
	[day_of_week release];
	[tod_f release];
    self.name=nil;
	self.logs=nil;
	self.placeHolders=nil;
	self.schedules=nil;
	self.regions=nil;
	self.literals = nil;
	self.phones = nil;
	[geocoder release];
    [super dealloc];
}

-(void)setLogs:(NSArray *)logs{
	
	[self.tableView beginUpdates];

	NSArray* old_logs = _logs;
	_logs=[logs retain];
	
	if(old_logs.count==0 && _logs.count>0){
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
	}else if(_logs.count==0 && old_logs.count>0){
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
	}
	if(_logs.count>0)
		[self animateLogListFromOld:old_logs ToNew:_logs];
	
	[self.tableView endUpdates];
	[old_logs release];
}
-(void)animateLogListFromOld:(NSArray*)old_list ToNew:(NSArray*)new_list{
	
	if(old_list.count > new_list.count)
	{
		NSUInteger base = new_list.count+1;
		NSUInteger diff = old_list.count +1- base;
		
		NSMutableArray* ips =[[[NSMutableArray alloc] initWithCapacity:diff] autorelease];
		for(NSUInteger i=base;i<base+diff;i++)
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:1]];
		[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationBottom];
	}
	else if(old_list.count < new_list.count){
		NSUInteger base = old_list.count+1;
		NSUInteger diff = new_list.count +1- base;
		
		NSMutableArray* ips =[[[NSMutableArray alloc] initWithCapacity:diff] autorelease];
		for(NSUInteger i=base;i<base+diff;i++)
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:1]];
		[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
	}
//	[self.tableView reloadData];
}

// name, tags(N), schedule(N)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (_logs.count>0?2:1)+_placeHolders.count + _schedules.count + _regions.count + _literals.count + _phones.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==0)return @"Name:";
	else if(section==1 && _logs.count>0)return @"Latest Logs:";
	else{
		if(_logs.count>0)section--;
		if(section<=pCount){
			return [[((NSDictionary*)[_placeHolders objectAtIndex:section-1]) objectForKey:@"name"] stringByAppendingString:@":"];
		}
		else if(section<=pCount+sCount){
			return [[((NSDictionary*)[_schedules objectAtIndex:section-1-pCount]) objectForKey:@"name"] stringByAppendingString:@" at:"];
		}
		else if(section<=pCount+sCount+rCount){
			return [[((NSDictionary*)[_regions objectAtIndex:section-1-pCount-sCount]) objectForKey:@"name"] stringByAppendingString:@":"];
		}
		else if(section<=pCount+sCount+rCount+lCount){
			return [[((NSDictionary*)[_literals objectAtIndex:section-1-pCount-sCount-rCount]) objectForKey:@"name"] stringByAppendingString:@":"];
		}
		else{
			return [[((NSDictionary*)[_phones objectAtIndex:section-1-pCount-sCount-rCount-lCount]) objectForKey:@"name"] stringByAppendingString:@":"];
		}
	}
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
	if(section==0)return 1;
	else if(section==1 && _logs.count>0)return _logs.count+1;
	else{
		if(_logs.count>0)section--;
		
		if(section<=pCount){
			NSDictionary* ph =[_placeHolders objectAtIndex:section-1];
			NSMutableArray* uuids =[ph objectForKey:@"uuids"];
			//NSLog(@"numberOfRowsInSection %ld is %ld +1", section, uuids.count);
			return uuids.count+1;
		}
		else if(section<=pCount+sCount){
			return 8;		// time and 7 check boxes of dow
		}else if(section<=pCount+sCount+rCount){
			// map image cell view >
			// # of devices with checkmark
			NSDictionary* ph =[_regions objectAtIndex:section-1-pCount-sCount];
			NSMutableArray* uuids =[ph objectForKey:@"devices"];
			return uuids.count+1;
		}else if(section<=pCount+sCount+rCount+lCount){
			return 1;
		}else{
			NSDictionary* ps =[_phones objectAtIndex:section-1-pCount-sCount-lCount];
			NSMutableArray* uuids =[ps objectForKey:@"devices"];
			return uuids.count;
		}
	}
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}

-(void)setDefaultDevicesEntryFor:(NSArray*)regOrPhones{
	if(mobileDevices==nil){
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/GetDevicesTemplate"]
						 jsonString: @"{}"
					  completeBlock:^(NSDictionary* retval){
						  mobileDevices =[[retval objectForKey:@"d"] retain];

						  for(NSMutableDictionary* r in regOrPhones)
							  [r setValue:[[mobileDevices copy] autorelease] forKey:@"devices"];

						  [self.tableView reloadData];
						  
						  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
					  }
						 errorBlock:^(NSError* err, id* showFrom){
							 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
							 return YES;
						 }setMac:nil];
	}else{
		for(NSMutableDictionary* r in regOrPhones)
			[r setValue:[[mobileDevices copy] autorelease] forKey:@"devices"];
	}
}

-(void)viewDidLoad{
	[super viewDidLoad];

	if(_regions.count>0 || _phones.count>0){
		NSMutableArray* emptyOnes = [[[NSMutableArray alloc]init] autorelease];
		for(NSMutableDictionary* ph in _regions){
			if(((NSArray*)[ph objectForKey:@"devices"]).count==0){
				[emptyOnes addObject:ph];
			}
		}
		for(NSMutableDictionary* ph in _phones){
			if(((NSArray*)[ph objectForKey:@"devices"]).count==0){
				[emptyOnes addObject:ph];
			}
		}
		[self setDefaultDevicesEntryFor:emptyOnes];
	}
	
	nameCell = [IASKPSTextViewSpecifierViewCell newEditableWithPlaceholder:@"Name (required)" delegate:self];
	nameCell.textField.text = self.name;
	downloadLogCell = [TableLoadingButtonCell newWithTitle:@"Download All" Progress:@"Downloading..."];
	
	if(lCount>0){
		_literalsCells = [[NSMutableArray alloc] initWithCapacity:lCount];
		for(int i=0;i<_literals.count;i++){
			NSDictionary* l =[_literals objectAtIndex:i];
			IASKPSTextViewSpecifierViewCell* cell =
				[[IASKPSTextViewSpecifierViewCell newEditableWithText:[l objectForKey:@"value"] delegate:self] autorelease];
			cell.textField.keyboardType = [[l objectForKey:@"isString"] boolValue]? UIKeyboardTypeDefault : UIKeyboardTypeDecimalPad;
			[_literalsCells insertObject: cell  atIndex:i];
		}
	}
	self.navigationItem.rightBarButtonItem
	= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:_placeHolders.count>0?UIBarButtonSystemItemDone:UIBarButtonSystemItemAdd target:self action:@selector(doneBtnPressed:)] autorelease];
	
	self.tableView.allowsSelectionDuringEditing = YES;
	
	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
}

-(void)releaseSubViews
{
	[nameCell release];nameCell=nil;
	[downloadLogCell release]; downloadLogCell=nil;
	self.literalsCells = nil;
}
- (void)viewDidUnload
{
	[super viewDidUnload];
	[self releaseSubViews];
}
- (void)doneBtnPressed:(id)sender{
	for(NSMutableDictionary* ph in _placeHolders){
		if([ph objectForKey:@"uuids"] == [NSNull null]){
			[[[iToast makeText:[NSString stringWithFormat:@"Please specify %@", [ph objectForKey:@"name"]] andDetail:@""] setDuration:iToastDurationNormal] showFrom:sender];
			return;
		}
	}
	for(NSMutableDictionary* r in _regions) {
		if(r.circularRegion==nil){
			[[[iToast makeText:[NSString stringWithFormat:@"Please specify %@", [r objectForKey:@"name"]] andDetail:@""] setDuration:iToastDurationNormal] showFrom:sender];
			return;
		}
//		[r removeObjectForKey:@"title"];
//		[r removeObjectForKey:@"detail"];
		for(NSMutableDictionary* dev in [r objectForKey:@"devices"]){
			[dev removeObjectForKey:@"name"];
		}
	}
	for(int i=0; i<_literalsCells.count;i++){
		IASKPSTextViewSpecifierViewCell* cell = [_literalsCells objectAtIndex:i];
		NSDictionary* l = [_literals objectAtIndex:i];
		if(cell.textField.text.length==0){
			[[[iToast makeText:[NSString stringWithFormat:@"Please specify %@", [l objectForKey:@"name"]] andDetail:@""] setDuration:iToastDurationNormal] showFrom:sender];
			return;
		}
		else{
			[l setValue:cell.textField.text forKey:@"value"];
		}
	}
	for(NSDictionary* ps in _phones){
		for(NSMutableDictionary* dev in [ps objectForKey:@"devices"]){
			[dev removeObjectForKey:@"name"];
		}
	}
	_done( nameCell.textField.text, _placeHolders, _schedules, _regions, _literals, _phones);
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section==currentEditSection;
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.row==0? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}
-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return YES;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}
// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)ip{
	
	NSInteger section =_logs.count>0?ip.section-1:ip.section;
	
	NSMutableDictionary* ph =[_placeHolders objectAtIndex:section-1];
	NSMutableArray* uuids = [ph objectForKey:@"uuids"];
	if(uuids == (id)[NSNull null]){
		uuids = [[[NSMutableArray alloc]init] autorelease];
		[ph setObject:uuids forKey:@"uuids"];
	}
	if(editingStyle==UITableViewCellEditingStyleDelete)
	{
		[uuids removeObjectAtIndex:ip.row-1];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation: UITableViewRowAnimationFade];
	}
	else if(editingStyle==UITableViewCellEditingStyleInsert){
		
		NSMutableArray* choices = [_delegate listTagsWithTypes:[ph objectForKey:@"supportedTypes"] excludingUuids:uuids];
					
		OptionPicker *picker = [[OptionPicker alloc]initWithOptions:choices
														   Selected:-1 Done:^(NSInteger selected, BOOL now){
															   [tableView beginUpdates];
															   if([[ph objectForKey:@"allowMultiple"] boolValue] || uuids.count==0){
																   [uuids insertObject:((NSDictionary*)[choices objectAtIndex:selected]).uuid atIndex:0];
																   [tableView insertRowsAtIndexPaths:
																	[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:ip.section ]] withRowAnimation: UITableViewRowAnimationFade];
															   }else{
																   [uuids removeAllObjects];
																   [uuids insertObject:((NSDictionary*)[choices objectAtIndex:selected]).uuid atIndex:0];
																   [tableView reloadRowsAtIndexPaths:
																	[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:ip.section ]] withRowAnimation: UITableViewRowAnimationFade];

															   }
															   [tableView endUpdates];
														   }];
		picker.dismissUI=^(BOOL animated){
			[self.navigationController popViewControllerAnimated:animated];
		};
		[self.navigationController pushViewController:picker animated:YES];
		[picker release];
	}
}
#define RECENT_PLACES_KEY @"recentPlaces5"
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	[tableView deselectRowAtIndexPath:ip animated:YES];

	UITableViewCell* btn = (UITableViewCell*)[tableView cellForRowAtIndexPath:ip];
	if(btn==downloadLogCell){
		_downloadLog(downloadLogCell);
		return;
	}
	NSInteger section =_logs.count>0?ip.section-1:ip.section;

	if(section>0){
		if(section <= pCount){
			if(!tableView.isEditing){
				currentEditSection = ip.section;
				[tableView setEditing:YES animated:YES];

				NSMutableDictionary* ph =[_placeHolders objectAtIndex:section-1];
				NSMutableArray* uuids = [ph objectForKey:@"uuids"];
				if(uuids.count==0){
					[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:ip];
				}

			}else if(ip.row==0){
				currentEditSection=-1;
				[tableView setEditing:NO animated:YES];
			}
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:ip.section]] withRowAnimation:UITableViewRowAnimationNone];

		}else if(section<=pCount+sCount){
			NSMutableDictionary* sch = [_schedules objectAtIndex:section-pCount-1];
			if(ip.row==0){
				IASKPSTextFieldSpecifierViewCell* cell = (IASKPSTextFieldSpecifierViewCell*)[tableView cellForRowAtIndexPath:ip];
				ActionSheetDatePicker *datePicker = [[[ActionSheetDatePicker alloc] initWithTitle:@""
																				   datePickerMode:UIDatePickerModeTime selectedDate:
													  [MSOptionsViewController tod2NSDate:[[sch objectForKey:@"tod"] intValue]  ]
																						doneBlock:^(ActionSheetDatePicker* picker, NSDate* date, id origin){
																									cell.textField.text = [tod_f stringFromDate:date];
																								 [sch setObject:[NSNumber numberWithInt:[MSOptionsViewController NSDate2tod:date]] forKey:@"tod"];
																							 } cancelBlock:nil origin:cell] autorelease];
				[datePicker addCustomButtonWithTitle:@"Now" value:[MSOptionsViewController roundDateTo15Minutes:[NSDate date]]];
				[datePicker showActionSheetPicker];

			}else{
				int dow = [[sch objectForKey:@"dow"] intValue];
				if(dow & (1<<(ip.row-1))){
					dow &= ~(1<<(ip.row-1));
				}else{
					dow |= (1<<(ip.row-1));
				}
				[sch setObject:[NSNumber numberWithInt:dow] forKey:@"dow"];
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
			}
		}else if(section<=pCount+sCount+rCount){
			NSMutableDictionary* reg =[_regions objectAtIndex:section-1-pCount-sCount];
			if(ip.row==0){
				NSMutableDictionary* recents = [[NSUserDefaults standardUserDefaults] objectForKey:RECENT_PLACES_KEY];
				if(recents==nil){
					recents = [[[NSMutableDictionary alloc]init] autorelease];
					[[NSUserDefaults standardUserDefaults] setObject:recents forKey:RECENT_PLACES_KEY];
				}
				MapRegionPicker *picker = [[MapRegionPicker alloc] initWithRegionEntry:reg RecentList:recents.allValues
																			 Done:^(NSMutableDictionary* regionEntry){
					
																				 /*reg.circularRegion = newReg;
																				 [reg setObject:[recentListEntry objectForKey:@"title"] forKey:@"title"];
																				 [reg setObject:[recentListEntry objectForKey:@"detail"] forKey:@"detail"];
																				 */
																				 // add to recent list only after it is chosen
																				 
																				 NSMutableDictionary* recents2 = [[[[NSUserDefaults standardUserDefaults] objectForKey:RECENT_PLACES_KEY] mutableCopy] autorelease];
																				 
																				 
																				 [recents2 setObject:regionEntry forKey:[regionEntry objectForKey:@"title"]];
																				 [[NSUserDefaults standardUserDefaults] setObject:recents2 forKey:RECENT_PLACES_KEY];
																				 
																				 //[[NSUserDefaults standardUserDefaults] synchronize];

																				 [self.navigationController popViewControllerAnimated:YES];
																				 [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];

																			 }];
				
				[self.navigationController pushViewController:picker animated:YES];
				
			}else{
				NSDictionary* device = [((NSArray*)[reg objectForKey:@"devices"]) objectAtIndex:ip.row-1];
				if([[device objectForKey:@"disabled"] boolValue])
					[device setValue:[NSNumber numberWithBool:NO] forKey:@"disabled"];
				else
					[device setValue:[NSNumber numberWithBool:YES] forKey:@"disabled"];
				
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
		else if(section<=pCount+sCount+rCount+lCount){
		}
		else{
			NSMutableDictionary* ps =[_phones objectAtIndex:section-1-pCount-sCount-rCount-lCount];
			NSDictionary* device = [((NSArray*)[ps objectForKey:@"devices"]) objectAtIndex:ip.row];

			if([[device objectForKey:@"disabled"] boolValue])
				[device setValue:[NSNumber numberWithBool:NO] forKey:@"disabled"];
			else
				[device setValue:[NSNumber numberWithBool:YES] forKey:@"disabled"];
			
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	NSInteger section =_logs.count>0?ip.section-1:ip.section;

	if(ip.section==0)return nameCell;
	else if(ip.section==1 && _logs.count>0){
		if(ip.row<_logs.count){
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogEntryCell"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
											   reuseIdentifier:@"LogEntryCell"]
						autorelease];
				cell.textLabel.font = [UIFont systemFontOfSize:14];
			}
			ScriptLogEntry* log =(ScriptLogEntry*)[_logs objectAtIndex:ip.row];
			cell.textLabel.text=log.msg;
			cell.detailTextLabel.text=[NSString stringWithFormat:@" at %@", [NSDateFormatter localizedStringFromDate:log.time dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
			if(log.type==0)cell.textLabel.textColor=[UIColor blackColor];
			else if(log.type==1)cell.textLabel.textColor=[UIColor orangeColor];
			else if(log.type==2)cell.textLabel.textColor=[UIColor redColor];
			return cell;
		}else{
			return downloadLogCell;
		}
	}
	else if(section<=pCount){
		NSDictionary* ph =[_placeHolders objectAtIndex:section-1];
		NSArray* uuids = [ph objectForKey:@"uuids"];
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										   reuseIdentifier:@"UITableViewCell"]
					autorelease];
		}
		if(ip.row==0){
			cell.textLabel.text = tableView.isEditing?@"Done Adding/Deleting": @"Add/Delete...";
		}else{
			cell.textLabel.text = [self.delegate findTagFromUuid:[uuids objectAtIndex:ip.row-1]].name;
		}

		return cell;
	}
	else if(section<=pCount+sCount){
		NSDictionary* sch =[_schedules objectAtIndex:section-1-pCount];
		
		if(ip.row==0){
			IASKPSTextFieldSpecifierViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"IASKPSTextFieldSpecifierViewCell2"];
			if (!cell) {
				cell = [[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:@"Time of Day: "] autorelease];
			}
			cell.textField.text = [tod_f stringFromDate:[MSOptionsViewController tod2NSDate:[[sch objectForKey:@"tod"] intValue]]];
			return cell;
		}else{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DOW"];
			if (!cell) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DOW"] autorelease];
			}
			cell.textLabel.text = [day_of_week objectAtIndex:ip.row-1];
			int dow = [[sch objectForKey:@"dow"] intValue];
			cell.accessoryType = dow&(1<<(ip.row-1)) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}else if(section<=pCount+sCount+rCount){
		__block NSMutableDictionary* reg =[_regions objectAtIndex:section-1-pCount-sCount];
		if(ip.row==0){
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationTitle"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
											   reuseIdentifier:@"LocationTitle"]
						autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}

			if([reg objectForKey:@"title"]!=[NSNull null]){
				cell.textLabel.text = [reg objectForKey:@"title"];
				cell.detailTextLabel.text = [reg objectForKey:@"detail"];
			}else if([reg objectForKey:@"id"]==[NSNull null]){
				cell.textLabel.text = @"Please specify...";
			}else{
				cell.textLabel.text = @"Loading...";
				[reg retain];
				[geocoder reverseGeocodeLocation:
				 [[[CLLocation alloc] initWithLatitude:[[reg objectForKey:@"centerLat"] doubleValue]
											 longitude:[[reg objectForKey:@"centerLong"]doubleValue]] autorelease]
						   completionHandler:^(NSArray* placemarks, NSError* error){
							   if (placemarks && placemarks.count > 0) {
								   CLPlacemark *topResult = [placemarks objectAtIndex:0];
								   [reg setObject:topResult.name forKey:@"title"];
								   [reg setObject:topResult.detailText forKey:@"detail"];
								   [self.tableView	 reloadRowsAtIndexPaths: [NSArray arrayWithObjects:ip, nil] withRowAnimation:UITableViewRowAnimationFade];
							   }
							   [reg release];
						   }
				 ];
			}
			return cell;
		}else{
			NSDictionary* device = [((NSArray*)[reg objectForKey:@"devices"]) objectAtIndex:ip.row-1];
			
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DOW"];
			if (!cell) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DOW"] autorelease];
			}
			cell.textLabel.text = [device objectForKey:@"name"];
			cell.accessoryType = [[device objectForKey:@"disabled"] boolValue] ?  UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
			return cell;
		}
	}
	else if(section<=pCount+sCount+rCount+lCount)
	{
		return [_literalsCells objectAtIndex:section-1-pCount-sCount-rCount];
	}
	else
	{
		NSMutableDictionary* ps =[_phones objectAtIndex:section-1-pCount-sCount-rCount-lCount];
		NSDictionary* device = [((NSArray*)[ps objectForKey:@"devices"]) objectAtIndex:ip.row];
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DOW"];
		if (!cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DOW"] autorelease];
		}
		cell.textLabel.text = [device objectForKey:@"name"];
		cell.accessoryType = [[device objectForKey:@"disabled"] boolValue] ?  UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
		return cell;
	}
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip
{
	NSInteger section =_logs.count>0?ip.section-1:ip.section;
	if(ip.section==0){
		UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:18.0];
		CGSize constraintSize = CGSizeMake(self.tableView.frame.size.width*14.0/16.0-50.0, MAXFLOAT);
		CGSize labelSize = [_name sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
		return labelSize.height + 34;
	}else if(section>pCount+sCount && section<=pCount+sCount+rCount && ip.row==0){
		return 60;  // location
	}/*else if(ip.section>pCount+sCount+rCount && ip.section<=pCount+sCount+rCount+lCount){

		if([[[_literals objectAtIndex:ip.section-pCount-sCount-rCount-1] objectForKey:@"isString"]boolValue])
			return 90;  // literal
		else
			return [super tableView:tableView heightForRowAtIndexPath:ip];
			
	}*/else
		return [super tableView:tableView heightForRowAtIndexPath:ip];
}

- (IBAction)hideKeyboard{
	[[self view]endEditing:YES];
}

@end


@implementation SnippetListViewController

//@synthesize dismissUI=_dismissUI;

- (id)initWithSnippets:(NSArray *)snippets Done:(snippetChoiceDoneBlock_t)done
{
//	self = [super initWithStyle:UITableViewStyleGrouped];
	self = [super initWithNibName:@"SearchTableView_iPhone" bundle:nil];

	if(self){
		_done=[done copy];
		self.snippets = snippets;
		self.title=@"Compatible KumoApps";
//		searchWasActive=NO;
	}
	return self;
}

- (void)dealloc
{
    [_snippets release];
	[_done release];
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

-(void) setSnippets:(NSArray *)snippets{
	[_snippets autorelease];
	_snippets = snippets;
	[_snippets retain];
	[[self tableView] reloadData];
}
-(NSArray*) snippets{
	return _snippets;
}

- (void)viewDidAppear:(BOOL)animated
{

    [super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}
-(void)viewDidDisappear:(BOOL)animated{
//    searchWasActive = [self.searchDisplayController isActive];
//    savedSearchTerm = [self.searchDisplayController.searchBar text];
	[super viewDidDisappear:animated];
}
-(void)viewDidUnload{
	[_filteredSnippets release]; _filteredSnippets=nil;
	[super viewDidUnload];
}
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
		self.tableView.tableHeaderView = self.searchController.searchBar;
	}
	self.searchController.searchBar.placeholder = @"Search by keyword";
	self.searchController.searchResultsUpdater = self;

	[self.searchController.searchBar sizeToFit];

	// create a filtered list that will contain products for the search results table.
	_filteredSnippets = [[NSMutableArray arrayWithCapacity:[_snippets count]] retain];
	
/*	if (savedSearchTerm)
	{
        [self.searchDisplayController setActive:searchWasActive];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        savedSearchTerm = nil;
    }
	*/
	[self.tableView reloadData];
	CGSize reqsz =  self.tableView.contentSize;
	self.preferredContentSize = CGSizeMake(350, reqsz.height>600?600:reqsz.height);
}
- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
	if (self.searchController.active)
	{
        return [_filteredSnippets count];
    }
	else
		return [_snippets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)ip
{
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:@"UITableViewCell"]
                autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;//UILineBreakModeWordWrap;
		cell.textLabel.numberOfLines = 0;
    }
	
	NSInteger optionIndex=[ip row];

	NSDictionary* snippet = (self.searchController.active)?
		(NSDictionary*)[_filteredSnippets objectAtIndex:optionIndex]:
		(NSDictionary*)[_snippets objectAtIndex:optionIndex];
	
	cell.textLabel.text = [snippet objectForKey:@"description"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ installs, by %@ at %@",
								 [snippet objectForKey:@"installed"],
								 [snippet objectForKey:@"author"], [snippet objectForKey:@"updated"]];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip
{
	NSDictionary* snippet = (NSDictionary*)[_snippets objectAtIndex:ip.row];
	NSString *cellText = [snippet objectForKey:@"description"];
	
	UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:18.0];
	CGSize constraintSize = CGSizeMake(self.tableView.frame.size.width*14.0/16.0-70.0, MAXFLOAT);
	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
	return labelSize.height + 32;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	NSInteger optionIndex = [ip row];
	if(self.searchController.active)
		_done([_filteredSnippets objectAtIndex:optionIndex]);
	else
		_done([_snippets objectAtIndex:optionIndex]);
	
	[tableView deselectRowAtIndexPath:ip animated:YES];
	//_dismissUI();
}

- (void)filterListBySearchText:(NSString*)searchText
{
	[_filteredSnippets removeAllObjects]; // First clear the filtered array.
	
	for (NSDictionary *snippet in _snippets)
	{
		NSString *cellText = [snippet objectForKey:@"description"];
		if(NSNotFound != [cellText rangeOfString:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
		{
			[_filteredSnippets addObject:snippet];
		}
	}
}
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self filterListBySearchText:searchString];
	[self.tableView reloadData];
}

/*
#pragma mark UISearchDisplayController Delegate Methods
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterListBySearchText:searchString];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	return NO;
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
	searchWasActive=YES;
//	controller.searchBar.text = @"*";
}
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller{
	contentOffsetBeforeSearch = [self.tableView contentOffset];
}
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
	[self.tableView setContentOffset:contentOffsetBeforeSearch animated:YES];
	searchWasActive=NO;
}
*/

@end
