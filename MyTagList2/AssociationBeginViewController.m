//
//  AssociationBeginViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AssociationBeginViewController.h"
#import "WebViewController.h"
#import "NSTimer+Blocks.h"

@implementation AssociationBeginViewController
@synthesize searchBtnCell=_searchBtnCell, delegate=_delegate, undeleteBtnCell=_undeleteBtnCell;

-(id)initWithDelegate:(id<AssociationDoneDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		self.delegate = delegate;
		dropcamLoginMode=NO; honeywellLoginMode=NO;
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
 	self.title = NSLocalizedString(@"Associate New...",nil);
	self.contentSizeForViewInPopover = CGSizeMake(480, 300);
}
-(void)dealloc{
	self.searchBtnCell=nil; self.storeBtnCell=nil; self.addNestBtnCell=nil; self.scannedThermostats = nil; self.undeleteBtnCell=nil;
	self.addWeMoBtnCell=nil; self.scannedWeMo=nil; self.addDropcamBtnCell=nil; self.addHoneywellBtnCell=nil; self.iftttBtnCell=nil;
	self.pwdCell=nil; self.scannedHoneywell=nil; self.emailCell=nil; self.hw_pwdCell=nil; self.hw_emailCell=nil;
	self.addManagerCell=nil; self.scannedDropcam=nil; self.tagsToUndelete=nil;
	[super dealloc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return (_delegate.showWeMoButton ?6: 5) + (_delegate.showDropcam?1:0);
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
	if(section==0)return 180;
	else return UITableViewAutomaticDimension;
}
/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	if(section==1)return 0;
	else return UITableViewAutomaticDimension;
}*/
-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
	if(section==0){
		CGRect frame = tableView.frame;
		frame.size.height = 230;
		
		NSData *data = [NSLocalizedString(@"Please pull out battery insulating tape from just <i>ONE</i> new Wireless Tag. Light should start to flash. <br/><ul><li>Never leave more than one tag flashing.</li><li>This process works best when Tag is a little away (e.g. in a different room) from the Tag Manager.</li></ul>For water/moisture sensor, please short the tip using a metal object or dipping into water to make the light flash. <br/><a href=\"http://mytaglist.com/media/how_to_associate_reed_sensor.pdf\">Instructions for Reed Sensor</a>",nil) dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *options = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)};
		
		NSMutableAttributedString *attributedText = [[[NSMutableAttributedString alloc] initWithData:data options:options documentAttributes:NULL error:NULL] autorelease];
		
		UITextView *textView = [[UITextView alloc] initWithFrame: frame];
		UIFont* font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
		[attributedText addAttribute:NSFontAttributeName  value:font range:NSMakeRange(0, attributedText.length)];
		[attributedText addAttribute:NSForegroundColorAttributeName  value:[UIColor colorWithWhite:0.4f alpha:1.0f] range:NSMakeRange(0, attributedText.length)];
		textView.backgroundColor = [UIColor clearColor];
		textView.editable = NO;
		textView.selectable=YES;
		textView.dataDetectorTypes=UIDataDetectorTypeLink;
		textView.scrollEnabled = NO;
		textView.textContainerInset = UIEdgeInsetsMake(8, 10, 0, 10);
		textView.attributedText = attributedText;
		textView.delegate = self;
		return textView;
	}
	else return nil;
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	[self.delegate redirectToURL:URL title:NSLocalizedString(@"Association Help",nil)];
	return NO;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if(section==0)
		return NSLocalizedString(@"Please remove battery insulating tape or insert battery into an unpaired Wireless Tag. If the tag is not already associated with a Tag Manager, a light should be flashing on the tag.",nil);
	else if(section==1)
		return NSLocalizedString(@"Add more tag managers to your account to extend signal coverage and/or to allow adding more tags.",nil);
	else if(section==2)
		return NSLocalizedString(@"Regulate temperature not at the thermostat, but at chosen Wireless Tag. Build historical temperature/humidity graph at your Thermostat. Run KumoApps such as 'turn off when window is left open', 'turn on when my phone gets close to a location.'",nil);
	else if(section==3)
		return NSLocalizedString(@"Regulate temperature not at the thermostat, but at chosen Wireless Tag. Run KumoApps such as 'set to away mode when window is left open', 'set to home mode when my phone gets close to a location.'",nil);//@"Regulate temperature using not thermometer inside the thermostat but one inside your chosen Wireless Tag. You can also install KumoApps such as 'set to home/turn on thermostat when my phone gets close to a location.'";
	else{
		if(!_delegate.showDropcam)section++;
		if(section==4)
			return NSLocalizedString(@"Run KumoApp to cloud-record short videos whenever a Wireless Tag detects motion. Make time lapses. No cloud recording subscription required!",nil);//@"Cloud-record videos taken from your Dropcam and make time lapses, even if you don't have Cloud Recording subscription. Install KumoApps such as 'record for 15 seconds when sensor detected motion or door is open and email footage to me'. ";
		else if(section==5)
			return NSLocalizedString(@"Activate the Wireless Tag IFTTT channel to make your tag work with hundreds of other IFTTT channels. (You need to create an account at IFTTT if you do not already have one)",nil);//@"Interact with hundreds of other IFTTT channels. There are 15+ types of triggers and 10+ types of actions in the WirelessTag channel to cover almost every feature of Wireless Sensor Tags and Kumo Sensors.";
		else if(section==6 && _delegate.showWeMoButton)
			return NSLocalizedString(@"Run KumoApps such as 'Turn on light when sensors detects motion' or 'turn on an appliance when my phone gets close to home.' Unlike IFTTT, KumoApp has much lower latency and works almost instantly.'",nil);//@"Allows you to use KumoApps such as 'Turn on light when sensor detected motion', or 'turn on an appliance when my phone gets close to home'. Unlike IFTTT, KumoApp has much lower latency and works almost instantly.";
		else return nil;
	}
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)return 2+self.tagsToUndelete.count;
	else if(section==1)return 1;
	else if(section==2)return honeywellLoginMode?3:1+self.scannedHoneywell.count;
	else if(section==3)return 1+self.scannedThermostats.count;
	else{
		if(!_delegate.showDropcam)section++;
		
		if(section==4)return dropcamLoginMode?3:1+self.scannedDropcam.count;
		else if(section==6 && _delegate.showWeMoButton)return 1+self.scannedWeMo.count;
		else return 1;
	}
}
-(UITableViewCell*) getVirtualTagEntryCellFor:(UITableView*)tableView{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThermostatEntryCell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:@"ThermostatEntryCell"]
				autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
	}
	return cell;
}

NSString * const DropCamEmailPrefKey = @"DropCamEmailPrefKey";
NSString * const DropCamPwdPrefKey = @"DropCamPwdPrefKey";
NSString * const HoneywellEmailPrefKey = @"HoneywellEmailPrefKey";
NSString * const HoneywellPwdPrefKey = @"HoneywellPwdPrefKey";

-(void)scanDropcamWithEmail:(NSString*)email andPassword:(NSString*)pwd{
	[_addDropcamBtnCell showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"DropCamLink.asmx/ScanDropCam"]
						jsonObj:@{@"username":email, @"password": pwd}
				  completeBlock:^(NSDictionary* retval){
					  [_addDropcamBtnCell revertLoading];
					  self.scannedDropcam = [retval objectForKey:@"d"];
					  
					  if(_scannedDropcam.count>0){
						  self.navigationItem.rightBarButtonItem =
						  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																		 action:@selector(associateVirtualTagBtnPressed:)] autorelease];
						  dropcamLoginMode=NO;
						  [[NSUserDefaults standardUserDefaults] setValue:email forKey:DropCamEmailPrefKey];
						  [[NSUserDefaults standardUserDefaults] setValue:pwd forKey:DropCamPwdPrefKey];
						  
						  [self updateTable];
					  }else{
						  [[NSUserDefaults standardUserDefaults] removeObjectForKey:DropCamEmailPrefKey];
						  [[NSUserDefaults standardUserDefaults] removeObjectForKey:DropCamPwdPrefKey];
						  [[[iToast makeText:NSLocalizedString(@"Dropcam email or password may be incorrect.",nil)]
							setDuration:iToastDurationNormal] showFrom:_addDropcamBtnCell];
					  }
					  [[NSUserDefaults standardUserDefaults]synchronize];
				  }
					 errorBlock:^(NSError* err, id* showFrom){
						 [_addDropcamBtnCell revertLoading];
						 *showFrom = _addDropcamBtnCell;
					  [[NSUserDefaults standardUserDefaults] removeObjectForKey:DropCamEmailPrefKey];
					  [[NSUserDefaults standardUserDefaults] removeObjectForKey:DropCamPwdPrefKey];
					  [[NSUserDefaults standardUserDefaults]synchronize];
						 
						 return YES;
					 }setMac:nil];
	
}
-(void)scanHoneywellWithEmail:(NSString*)email andPassword:(NSString*)pwd{
	[_addHoneywellBtnCell showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"HoneywellLink.asmx/ScanThermostats"]
						jsonObj:@{@"username":email, @"password": pwd}
				  completeBlock:^(NSDictionary* retval){
					  [_addHoneywellBtnCell revertLoading];
					  self.scannedHoneywell = [retval objectForKey:@"d"];
					  
					  if(_scannedHoneywell.count>0){
						  self.navigationItem.rightBarButtonItem =
						  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																		 action:@selector(associateVirtualTagBtnPressed:)] autorelease];
						  honeywellLoginMode=NO;
						  [[NSUserDefaults standardUserDefaults] setValue:email forKey:HoneywellEmailPrefKey];
						  [[NSUserDefaults standardUserDefaults] setValue:pwd forKey:HoneywellPwdPrefKey];
						  
						  [self updateTable];
					  }else{
						  [[NSUserDefaults standardUserDefaults] removeObjectForKey:HoneywellEmailPrefKey];
						  [[NSUserDefaults standardUserDefaults] removeObjectForKey:HoneywellPwdPrefKey];
						  [[[iToast makeText:NSLocalizedString(@"Honeywell Total Connect Comfort login email or password may be incorrect.",nil)]
							setDuration:iToastDurationNormal] showFrom:_addHoneywellBtnCell];
					  }
					  [[NSUserDefaults standardUserDefaults]synchronize];
				  }
					 errorBlock:^(NSError* err, id* showFrom){
						 [_addHoneywellBtnCell revertLoading];
						 *showFrom = _addHoneywellBtnCell;
					  [[NSUserDefaults standardUserDefaults] removeObjectForKey:HoneywellEmailPrefKey];
					  [[NSUserDefaults standardUserDefaults] removeObjectForKey:HoneywellPwdPrefKey];
					  [[NSUserDefaults standardUserDefaults]synchronize];
						 
						 return YES;
					 }setMac:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _emailCell.textField){
		[_pwdCell.textField becomeFirstResponder];
	}
	else if (textField == _pwdCell.textField) {

		if(_emailCell.textField.text.length==0){
			_emailCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:DropCamEmailPrefKey];
			_pwdCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:DropCamPwdPrefKey];
		}
		[self scanDropcamWithEmail:_emailCell.textField.text andPassword:_pwdCell.textField.text];
	}
	else if (textField == _hw_emailCell.textField){
		[_hw_pwdCell.textField becomeFirstResponder];
	}
	else if (textField == _hw_pwdCell.textField) {
		
		if(_hw_emailCell.textField.text.length==0){
			_hw_emailCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HoneywellEmailPrefKey];
			_hw_pwdCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HoneywellPwdPrefKey];
		}
		[self scanHoneywellWithEmail:_hw_emailCell.textField.text andPassword:_hw_pwdCell.textField.text];
	}

	return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0){
		if(indexPath.row==0){
			if(_searchBtnCell==nil)
				_searchBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Search a New Tag",nil) Progress:NSLocalizedString(@"Searching...",nil)];
			return _searchBtnCell;
		}else if(indexPath.row==1){
			if(_undeleteBtnCell==nil)
				_undeleteBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Undelete a Tag",nil) Progress:NSLocalizedString(@"Loading...",nil)];
			return _undeleteBtnCell;
		}else{
			NSDictionary* tag = [self.tagsToUndelete objectAtIndex:indexPath.row-2];
			UITableViewCell* cell = [self getVirtualTagEntryCellFor:tableView];
			cell.textLabel.text=[tag objectForKey:@"name"];

			NSDate* deleted = [NSDate dateWithTimeIntervalSince1970:(([[tag objectForKey:@"deleted"]longLongValue] / 10000000) - 11644473600)];
			NSDate* now = [[[NSDate alloc] init] autorelease];
			NSTimeInterval diff = [now timeIntervalSinceDate:deleted] + serverTime2LocalTime;

			cell.detailTextLabel.text=[NSString stringWithFormat:NSLocalizedString(@"Unpaired %@ ago",nil), [NSDictionary UserFriendlyTimeSpanString:NO ForInterval:diff]];
			//cell.accessoryType = [[tag objectForKey:@"_checked"]boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}
	else if(indexPath.section==1){
		if(_addManagerCell==nil)
			_addManagerCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Add a Tag Manager",nil) Progress:NSLocalizedString(@"Loading Web Interface...",nil)];
		return _addManagerCell;
	}
	else if(indexPath.section==2){
		
		if(indexPath.row==0){
			if(_addHoneywellBtnCell==nil)
				_addHoneywellBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Link/Unlink Honeywell Thermostats",nil) Progress:NSLocalizedString(@"Loading...",nil)];
			return _addHoneywellBtnCell;
		}else if(honeywellLoginMode){
			if(indexPath.row==1){
				if(_hw_emailCell==nil){
					_hw_emailCell =[IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Total Connect Comfort Email",nil) isLast:NO delegate:self];
					_hw_emailCell.textField.keyboardType=UIKeyboardTypeEmailAddress;
					[_hw_emailCell.textField setReturnKeyType:UIReturnKeyNext];
					_hw_emailCell.textField.delegate=self;
				}
				return _hw_emailCell;
			}else{
				if(_hw_pwdCell==nil){
					_hw_pwdCell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Total Connect Comfort Password",nil) isLast:NO delegate:self];
					_hw_pwdCell.textField.secureTextEntry=YES;
					_hw_pwdCell.textField.autocorrectionType=UITextAutocorrectionTypeNo;
					[_hw_pwdCell.textField setReturnKeyType:UIReturnKeyDone];
					_hw_pwdCell.textField.delegate=self;
				}
				return _hw_pwdCell;
			}
		}else{
			NSDictionary* tstat = [self.scannedHoneywell objectAtIndex:indexPath.row-1];
			UITableViewCell* cell = [self getVirtualTagEntryCellFor:tableView];
			cell.textLabel.text=[tstat objectForKey:@"name"];
			NSString* renamed_to =[tstat objectForKey:@"renamed_to"];
			cell.detailTextLabel.text=[NSString stringWithFormat:NSLocalizedString(@"Updated: %@ ago%@",nil), [tstat UserFriendlyTimeSpanString:NO],
									   renamed_to.length>0?[NSLocalizedString(@", Renamed to ",nil) stringByAppendingString:renamed_to]:@""];
			cell.accessoryType = tstat.slaveId!=0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}
	else if(indexPath.section==3){
		if(indexPath.row==0){
			if(_addNestBtnCell==nil){
				_addNestBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Link/Unlink Nest Thermostats",nil) Progress:NSLocalizedString(@"Loading...",nil)];
//				_addNestBtnCell.backgroundColor = [UIColor ]
			}
			return _addNestBtnCell;
		}else{
			NSDictionary* tstat = [self.scannedThermostats objectAtIndex:indexPath.row-1];
			UITableViewCell* cell = [self getVirtualTagEntryCellFor:tableView];
			cell.textLabel.text=[tstat objectForKey:@"name"];
			cell.detailTextLabel.text=[tstat objectForKey:@"comment"];
			cell.accessoryType = tstat.slaveId!=0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}
	else{
		NSUInteger section=indexPath.section;
		if(!_delegate.showDropcam)section++;

		if(section==4){
			if(indexPath.row==0){
				if(_addDropcamBtnCell==nil)
					_addDropcamBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Link/Unlink Dropcam",nil) Progress:NSLocalizedString(@"Loading...",nil)];
				return _addDropcamBtnCell;
			}else if(dropcamLoginMode){
				if(indexPath.row==1){
					if(_emailCell==nil){
						_emailCell =[IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Dropcam Email",nil) isLast:NO delegate:self];
						_emailCell.textField.keyboardType=UIKeyboardTypeEmailAddress;
						[_emailCell.textField setReturnKeyType:UIReturnKeyNext];
						_emailCell.textField.delegate=self;
					}
					return _emailCell;
				}else{
					if(_pwdCell==nil){
						_pwdCell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Dropcam Password",nil) isLast:NO delegate:self];
						_pwdCell.textField.secureTextEntry=YES;
						_pwdCell.textField.autocorrectionType=UITextAutocorrectionTypeNo;
						[_pwdCell.textField setReturnKeyType:UIReturnKeyDone];
						_pwdCell.textField.delegate=self;
					}
					return _pwdCell;
				}
			}else{
				NSDictionary* tstat = [self.scannedDropcam objectAtIndex:indexPath.row-1];
				UITableViewCell* cell = [self getVirtualTagEntryCellFor:tableView];
				cell.textLabel.text=[tstat objectForKey:@"name"];
				NSString* renamed_to =[tstat objectForKey:@"renamed_to"];
				cell.detailTextLabel.text=[NSString stringWithFormat:NSLocalizedString(@"Status: %@ %@",nil), [[tstat objectForKey:@"streaming"] boolValue]?NSLocalizedString(@"Streaming",nil):NSLocalizedString(@"Off",nil),
										   renamed_to.length>0?[NSLocalizedString(@", Renamed to ",nil) stringByAppendingString:renamed_to]:@""];
				cell.accessoryType = tstat.slaveId!=0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				return cell;
			}
		}
		else if(section==5){
			if(_iftttBtnCell==nil)
				_iftttBtnCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Activate WirelessTag IFTTT Channel",nil) Progress:NSLocalizedString(@"Loading...",nil)];
			return _iftttBtnCell;
		}
		else if(section==6 && _delegate.showWeMoButton){
			if(indexPath.row==0){
				if(_addWeMoBtnCell==nil)
					_addWeMoBtnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Link/Unlink WeMo LED/switches",nil) Progress:NSLocalizedString(@"Loading...",nil)];
				return _addWeMoBtnCell;
			}else{
				NSDictionary* tstat = [self.scannedWeMo objectAtIndex:indexPath.row-1];
				UITableViewCell* cell = [self getVirtualTagEntryCellFor:tableView];
				cell.textLabel.text=[tstat objectForKey:@"friendlyName"];
				cell.detailTextLabel.text=[NSLocalizedString(@"Associated as: ",nil) stringByAppendingString:[tstat objectForKey:@"renamed_to"]];
				cell.accessoryType = tstat.slaveId!=0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				return cell;
			}
		}
		else{
			if(_storeBtnCell==nil)
				_storeBtnCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Store...",nil) Progress:NSLocalizedString(@"Loading...",nil)];
			return _storeBtnCell;
		}
	}
}
-(void)viewWillDisappear:(BOOL)animated{
	[searchReq cancel];
	[searchReq release]; searchReq=nil;
	[super viewWillDisappear:animated];
}
-(void)viewWillAppear:(BOOL)animated{
	if([self.navigationController respondsToSelector:@selector(setPreferredContentSize:)])
		self.navigationController.preferredContentSize= CGSizeMake(480, 400);
	self.navigationController.contentSizeForViewInPopover = CGSizeMake(480, 400);

	self.navigationController.toolbarHidden=YES;
	[super viewWillAppear:animated];
}
-(void)scanNewTag{
	[searchReq release];
	searchReq = [[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ScanNewTag"]
					 jsonString:@"{timeout: 2500}"
				  completeBlock:^(NSDictionary* retval){
					  id d = [retval objectForKey:@"d"];
					  if(d==nil || d==[NSNull null]){
						  [self scanNewTag];
					  }else{
						  [_searchBtnCell revertLoading];
						  
						  if(((NSDictionary*)d).version1 >= 2){
							  if(!optimizeForV2Tag && !isTagListEmpty){
								  UIAlertView *alert = [[UIAlertView alloc] init];
								  [alert setTitle:NSLocalizedString(@"Compatibility Notice",nil)];
								  [alert setMessage:NSLocalizedString(@"Current wireless setting of your Tag Manager is compatible with old (version 1) tags. Although it still works with this new (version 2) tag, the tag's maximum possible range cannot be achieved. We recommend that you unpair all version 1 tags, before you associate this version 2 tag to take full advantage of it.",nil)];
								  [alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
								  [alert setCancelButtonIndex:0];
								  [alert show];
								  [alert release];
							  }
						  }else if(((NSDictionary*)d).version1 == 1){
							  if(optimizeForV2Tag){
								  UIAlertView *alert = [[UIAlertView alloc] init];
								  [alert setTitle:NSLocalizedString(@"Compatibility Notice",nil)];
								  [alert setMessage:NSLocalizedString(@"Current wireless setting of your Tag Manager is not compatible with old (version 1) tags. Before you can associate this old (version 1) tag, you must migrate to a wireless setting (using the web interface) that is compatible with version 1 tags, such as 20.3kbps/140kHz.",nil)];
								  [alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
								  [alert setCancelButtonIndex:0];
								  [alert show];
								  [alert release];								  
							  }
						  }
						  
						  AssociationEndViewController* ec = [[AssociationEndViewController alloc]init];
						  ec.delegate=self.delegate;
						  ec.tagInfo = d;
						  [self.navigationController pushViewController:ec animated:YES];
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = _searchBtnCell;
					  [_searchBtnCell revertLoading];
					  return YES;
				  } setMac:nil] retain];
}
-(void)nestLogin:(TableLoadingButtonCell*)sender{
	NSString* oldProgressTitle = sender.progressTitle;
	sender.progressTitle = NSLocalizedString(@"Redirecting...",nil);
	[sender showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"NestLink.asmx/GetAuthorizeURL"]
					 jsonString:@"{}"
				  completeBlock:^(NSDictionary* retval){
					  [sender revertLoading];
					  sender.progressTitle = oldProgressTitle;
					  
					  WebViewController* wv = [[[WebViewController alloc]initWithTitle:NSLocalizedString(@"Nest Login",nil)] autorelease];
					  [self.navigationController pushViewController:wv animated:YES];
					  
					  NSURL *url = [NSURL URLWithString:	[retval objectForKey:@"d"]];
					  NSURLRequest *req = [NSURLRequest requestWithURL:url];
					  [[wv webView] loadRequest:req];
					  
					  if([self.navigationController respondsToSelector:@selector(setPreferredContentSize:)])
						  self.navigationController.preferredContentSize= CGSizeMake(750, 1000);
					  self.navigationController.contentSizeForViewInPopover = CGSizeMake(750, 1000);
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [sender revertLoading];
					  sender.progressTitle = oldProgressTitle;
					  return YES;
				  } setMac:nil];
}
-(void)associateVirtualTagBtnPressed:(id)sender{
	__block int associationPending=0;
	
	for(int i=0;i<self.scannedHoneywell.count;i++){
		NSDictionary* tstat = [self.scannedHoneywell objectAtIndex:i];
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:2]];
		
		if(tstat.slaveId==0 && cell.accessoryType==UITableViewCellAccessoryCheckmark){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"HoneywellLink.asmx/Associate"]
								jsonObj:@{@"honeywell":tstat, @"username":_hw_emailCell.textField.text, @"password":_hw_pwdCell.textField.text}
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate associationDone:[retval objectForKey:@"d"]];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:^(NSError* err, id* showFrom){
								 *showFrom = cell;
								 return YES;
							 }setMac:nil];
			
			
		}else if(tstat.slaveId!=0 && cell.accessoryType==UITableViewCellAccessoryNone){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
							 jsonString:[NSString stringWithFormat:@"{id: %d}",tstat.slaveId]
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate deletedTagWithSlaveId:tstat.slaveId];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:nil setMac:nil];
		}
	}

	for(int i=0;i<self.scannedThermostats.count;i++){
		NSDictionary* tstat = [self.scannedThermostats objectAtIndex:i];
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:3]];
		
		if(tstat.slaveId==0 && cell.accessoryType==UITableViewCellAccessoryCheckmark){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"NestLink.asmx/Associate"]
								jsonObj:@{@"nest":tstat}
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate associationDone:[retval objectForKey:@"d"]];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:^(NSError* err, id* showFrom){
								 *showFrom = cell;
								 return YES;
							 }setMac:nil];
			
			
		}else if(tstat.slaveId!=0 && cell.accessoryType==UITableViewCellAccessoryNone){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
							 jsonString:[NSString stringWithFormat:@"{id: %d}",tstat.slaveId]
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate deletedTagWithSlaveId:tstat.slaveId];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:nil setMac:nil];
		}
	}

	for(int i=0;i<self.scannedDropcam.count;i++){
		NSDictionary* tstat = [self.scannedDropcam objectAtIndex:i];
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:4]];
		
		if(tstat.slaveId==0 && cell.accessoryType==UITableViewCellAccessoryCheckmark){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"DropCamLink.asmx/Associate"]
								jsonObj:@{@"cam":tstat}
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate associationDone:[retval objectForKey:@"d"]];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:^(NSError* err, id* showFrom){
								 *showFrom = cell;
								 return YES;
							 }setMac:nil];
			
			
		}else if(tstat.slaveId!=0 && cell.accessoryType==UITableViewCellAccessoryNone){
			associationPending++;
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
							 jsonString:[NSString stringWithFormat:@"{id: %d}",tstat.slaveId]
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate deletedTagWithSlaveId:tstat.slaveId];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:nil setMac:nil];
		}
	}

	for(int i=0;i<self.scannedWeMo.count;i++){
		NSDictionary* tstat = [self.scannedWeMo objectAtIndex:i];
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection: _delegate.showDropcam? 6:5]];
		
		if(tstat.slaveId==0 && cell.accessoryType==UITableViewCellAccessoryCheckmark){
			associationPending++;
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"WeMoLink.asmx/Associate"]
								jsonObj:@{@"WeMo":tstat}
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate associationDone:[retval objectForKey:@"d"]];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:^(NSError* err, id* showFrom){
								 *showFrom = cell;
								 return YES;
							 }setMac:nil];
			
			
		}else if(tstat.slaveId!=0 && cell.accessoryType==UITableViewCellAccessoryNone){
			associationPending++;
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
							 jsonString:[NSString stringWithFormat:@"{id: %d}",tstat.slaveId]
						  completeBlock:^(NSDictionary* retval){
							  associationPending--;
							  [_delegate deletedTagWithSlaveId:tstat.slaveId];
							  if(associationPending==0)
								  [_delegate dismissAssociationScreen];
						  }
							 errorBlock:nil setMac:nil];
		}
	}

	if(associationPending==0)
		[_delegate dismissAssociationScreen];

}
-(void)updateTable{
	[self.tableView reloadData];
	[NSTimer scheduledTimerWithTimeInterval:0.4 block:^()
	 {
		 if([self respondsToSelector:@selector(setPreferredContentSize:)])
			 self.preferredContentSize=self.tableView.contentSize;
		 
		 if(self.contentSizeForViewInPopover.height<self.tableView.contentSize.height)
			 self.contentSizeForViewInPopover = self.tableView.contentSize;
	 } repeats:NO];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if(indexPath.section==0){
		if(indexPath.row==0){
			[_searchBtnCell showLoading];
			[self scanNewTag];
		}else if(indexPath.row==1){
			if(self.tagsToUndelete.count>0){
				self.tagsToUndelete=nil;
				[self updateTable];
			}else{
				[_undeleteBtnCell showLoading];
				[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetDeletedTagList"]
								 jsonString:@"{}"
							  completeBlock:^(NSDictionary* retval){
								  [_undeleteBtnCell revertLoading];
								  self.tagsToUndelete = [retval objectForKey:@"d"];
								  if(_tagsToUndelete.count==0){
									  [[[iToast makeText:NSLocalizedString(@"Nothing to undelete",nil) andDetail:@""] setDuration:iToastDurationNormal] showFrom:_undeleteBtnCell];
								  }else{
									  [self updateTable];
								  }
							  }errorBlock:^(NSError* err, id* showFrom){
								  *showFrom = _undeleteBtnCell;
								  [_undeleteBtnCell revertLoading];
								  return YES;
							  }setMac:nil];
			}
			
		}else{

			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/UndeleteTag2"]
								jsonObj:@{@"uuid": [[self.tagsToUndelete objectAtIndex:indexPath.row-2] objectForKey:@"uuid"] }
						  completeBlock:^(NSDictionary* retval){

							  [_delegate dismissAssociationScreen];
							  [_delegate associationDone:[retval objectForKey:@"d"]];
							  
						  }errorBlock:^(NSError* err, id* showFrom){
							  return YES;
						  }setMac:nil];
			
		}
	}
	else if(indexPath.section==1){

		[_addManagerCell showLoading];
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"add_manager"]){
			[[NSURLCache sharedURLCache] removeAllCachedResponses];
			[[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"add_manager"];
		}
		WebViewController* wv = [[WebViewController alloc]initWithTitle:NSLocalizedString(@"Web Interface",nil)];
		
		NSURL *url = [NSURL URLWithString:	[WSROOT stringByAppendingString:@"eth/index.html?add_manager"]];
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
		NSString* cookie = [AsyncURLConnection getCookie];//[[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
		if(cookie)[req addValue:cookie forHTTPHeaderField:@"Cookie"];

		[wv loadRequest:req WithCompletion:^{
			[_addManagerCell revertLoading];
			[(UINavigationController*)self.navigationController pushViewController:wv animated:YES];
			[wv release];
		} onClose:^(BOOL cancelled) {
			if(!cancelled){
				[_delegate dismissAssociationScreen];
				[_delegate tagManagerAdded];
			}
		}];
		
	}
	else if(indexPath.section==2){
		if(indexPath.row==0)
		{
			[self.tableView beginUpdates];
			honeywellLoginMode=!honeywellLoginMode;
			if(honeywellLoginMode)
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section],[NSIndexPath indexPathForRow:2 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
			else
				[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section],[NSIndexPath indexPathForRow:2 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
			[self.tableView endUpdates];

		}
		else if(!dropcamLoginMode){
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
			if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			else
				cell.accessoryType =UITableViewCellAccessoryCheckmark;
		}
	}
	else if(indexPath.section==3){
		if(indexPath.row==0){
			[_addNestBtnCell showLoading];
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"NestLink.asmx/ScanThermostats"]
							 jsonString:@"{}"
						  completeBlock:^(NSDictionary* retval){
							  [_addNestBtnCell revertLoading];
							  self.scannedThermostats = [retval objectForKey:@"d"];
							  self.navigationItem.rightBarButtonItem =
								[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																			   action:@selector(associateVirtualTagBtnPressed:)] autorelease];
							  [self updateTable];
						  }
							 errorBlock:^(NSError* err, id* showFrom){
								 [_addNestBtnCell revertLoading];
								 [self nestLogin:_addNestBtnCell];
								 return NO;
							 }setMac:nil];
		}else{
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
			if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			else
				cell.accessoryType =UITableViewCellAccessoryCheckmark;
		}
	}
	else{
		NSUInteger section=indexPath.section;
		if(!_delegate.showDropcam)section++;

		
		else if(section==4){
			if(indexPath.row==0){
				/*			NSString* storedEmail = [[NSUserDefaults standardUserDefaults] stringForKey:DropCamEmailPrefKey];
				 if(storedEmail!=nil){
				 [self scanDropcamWithEmail:storedEmail andPassword:[[NSUserDefaults standardUserDefaults] stringForKey:DropCamPwdPrefKey]];
				 }else*/
				{
					[self.tableView beginUpdates];
					dropcamLoginMode=!dropcamLoginMode;
					if(dropcamLoginMode)
						[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section],[NSIndexPath indexPathForRow:2 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
					else
						[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:indexPath.section],[NSIndexPath indexPathForRow:2 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
					[self.tableView endUpdates];
				}
			}else if(!dropcamLoginMode){
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
				UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
				if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
					[cell setAccessoryType:UITableViewCellAccessoryNone];
				else
					cell.accessoryType =UITableViewCellAccessoryCheckmark;
			}
		}
		else if(section==5){
			[_iftttBtnCell showLoading];
			[self.delegate redirectToURL:[NSURL URLWithString:@"https://ifttt.com/wirelesstag"] title:NSLocalizedString(@"Activate IFTTT",nil)];
			[_iftttBtnCell revertLoading];
		}
		else if(section==6 && _delegate.showWeMoButton){
			if(indexPath.row==0){
				
				if(_delegate.wemoPhoneKey.length==0){
					UIAlertView *alert = [[UIAlertView alloc] init];
					[alert setTitle:NSLocalizedString(@"Still working....",nil)];
					[alert setMessage:NSLocalizedString(@"Still working to configure WeMo device(s) found. Please try clicking this button a few seconds later.",nil)];
					[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
					[alert setCancelButtonIndex:0];
					[alert show];
					[alert release];
				}else{
					[_addWeMoBtnCell showLoading];
					[AsyncURLConnection request:[WSROOT stringByAppendingString:@"WeMoLink.asmx/ScanWeMo"]
										jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:_delegate.wemoHomeID,@"homeID",_delegate.wemoPhoneID,@"phoneID",_delegate.wemoPhoneKey,@"phoneKey", nil]
								  completeBlock:^(NSDictionary* retval){
									  [_addWeMoBtnCell revertLoading];
									  self.scannedWeMo = [retval objectForKey:@"d"];
									  self.navigationItem.rightBarButtonItem =
									  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																					 action:@selector(associateVirtualTagBtnPressed:)] autorelease];
									  [self updateTable];
								  }
									 errorBlock:^(NSError* err, id* showFrom){
										 *showFrom = _addWeMoBtnCell;
										 [_addWeMoBtnCell revertLoading];
										 return YES;
									 }setMac:nil];
				}
			}else{
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
				UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
				if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
					[cell setAccessoryType:UITableViewCellAccessoryNone];
				else
					cell.accessoryType =UITableViewCellAccessoryCheckmark;
			}
			
		}
		else{
			//[_storeBtnCell showLoading];
			[self.delegate redirectToURL:[NSURL URLWithString:@"https://store.wirelesstag.net/"] title:NSLocalizedString(@"Store",nil)];
			
		}
	}
}
/*
-(void)viewWillAppear:(BOOL)animated{
	[self.tableView reloadData];
	CGSize reqsz =  self.tableView.contentSize;
	self.contentSizeForViewInPopover = CGSizeMake(480, reqsz.height>600?600:reqsz.height);
}
*/
@end
@implementation AssociationEndViewController
@synthesize associateBtn=_associateBtn, nameCell=_nameCell, commentCell=_commentCell, tagInfo=_tagInfo, lockFlashCell=_lockFlashCell, flashLEDCell=_flashLEDCell;
@synthesize delegate=_delegate;
@synthesize associatedTag=_associatedTag;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    return self;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex==0){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
						 jsonString:[NSString stringWithFormat:@"{id: %d}",_associatedTag.slaveId]
					  completeBlock:nil errorBlock:nil setMac:nil];
		[self.navigationController popViewControllerAnimated:YES];
	}else{
		[_delegate dismissAssociationScreen];
		[_delegate associationDone:_associatedTag];
	}
}
-(void)_associateBtnPressed:(id)sender{
	[super showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/AssociateNewTag5"]
					jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
							 [[_nameCell.textField.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString],@"nameBase64",
							 [[_commentCell.textField.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString], @"commentBase64",
						_tagInfo, @"taginfo", [NSNumber numberWithInt:6000], @"timeout",
							 [NSNumber numberWithBool:_lockFlashCell.accessoryType==UITableViewCellAccessoryCheckmark], @"lockFlash",
							 [NSNumber numberWithBool:_flashLEDCell.accessoryType!=UITableViewCellAccessoryCheckmark], @"noLED",
							 [NSNumber numberWithBool:_cachePostbackCell.accessoryType!=UITableViewCellAccessoryCheckmark], @"cachedPostback",
							 nil]
				  completeBlock:^(NSDictionary* retval){
					  [super revertLoadingBarItem:sender];
					  self.associatedTag = [retval objectForKey:@"d"];
					  if(!_associatedTag.alive){
						  UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Wireless Tag"
																	  message:NSLocalizedString(@"Tag failed to respond to association request. Is the tag still flashing?",nil) delegate:self
															cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Yes (roll back)",nil),NSLocalizedString(@"No (treat as done)",nil), nil];
						  [av show];
						  [av release];
					  }else{
						  [_delegate dismissAssociationScreen];
						  [_delegate associationDone:_associatedTag];
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [super revertLoadingBarItem:sender];
					  return YES;
				  } setMac:nil];
	
}
- (void)_updateCompleteBtn {
	if(_nameCell.textField.text.length>0)
        [_associateBtn setEnabled:YES];
    else
        [_associateBtn setEnabled:NO];
}
-(void)editedTableViewCell:(UITableViewCell *)cell{
	[self _updateCompleteBtn];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	self.contentSizeForViewInPopover = CGSizeMake(480, 400);

	self.title = NSLocalizedString(@"Found Tag",nil);
	_associateBtn = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Associate",nil) style:UIBarButtonItemStyleDone target:self action:@selector(_associateBtnPressed:)];
	_nameCell = [IASKPSTextFieldSpecifierViewCell newEditableWithTitle:NSLocalizedString(@"Name",nil) delegate:self];
	_commentCell = [IASKPSTextFieldSpecifierViewCell newEditableWithTitle:NSLocalizedString(@"Comment",nil) delegate:self];

	_lockFlashCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_lockFlashCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_lockFlashCell.textLabel.numberOfLines = 0;
	_lockFlashCell.textLabel.text = NSLocalizedString(@"Lock flash memory",nil);
	_lockFlashCell.accessoryType = UITableViewCellAccessoryNone;

	_flashLEDCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_flashLEDCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_flashLEDCell.textLabel.numberOfLines = 0;
	_flashLEDCell.textLabel.text = NSLocalizedString(@"Flash LED when updating",nil);
	_flashLEDCell.accessoryType = UITableViewCellAccessoryNone;

	_cachePostbackCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_cachePostbackCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_cachePostbackCell.textLabel.numberOfLines = 0;
	_cachePostbackCell.textLabel.text =  [NSLocalizedString(@"Buffer multiple temperature/humidity data points locally before updating",nil) stringByAppendingString:@" ℹ️"];
	_cachePostbackCell.accessoryType = UITableViewCellAccessoryNone; //UITableViewCellAccessoryCheckmark;
	UITapGestureRecognizer* recog =[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTooltip:)] autorelease];
	recog.cancelsTouchesInView=NO;
	[_cachePostbackCell addGestureRecognizer:recog];

	
	self.navigationItem.rightBarButtonItem = _associateBtn;
	
	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
}


- (void)didTapTooltip:(UITapGestureRecognizer *)recognizer {
	UILabel *textLabel = _cachePostbackCell.textLabel;
	CGPoint tapLocation = [recognizer locationInView:textLabel];
	
	// init text storage
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithAttributedString:textLabel.attributedText] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
	[textStorage addLayoutManager:layoutManager];
	
	// init text container
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithSize:CGSizeMake(textLabel.frame.size.width, textLabel.frame.size.height+100) ] autorelease];
	textContainer.lineFragmentPadding  = 0;
	textContainer.maximumNumberOfLines = textLabel.numberOfLines;
	textContainer.lineBreakMode        = textLabel.lineBreakMode;
	
	[layoutManager addTextContainer:textContainer];
	
	NSUInteger characterIndex = [layoutManager characterIndexForPoint:tapLocation
													  inTextContainer:textContainer
							 fractionOfDistanceBetweenInsertionPoints:NULL];
	//NSLog(@"characterIndex=%uld",characterIndex);
	if(characterIndex> textLabel.text.length-8){
		[[[iToast makeText:@"For example, if you set recording interval to every 10 minutes, temperature is recorded every 10 minutes, but is transmitted every 130 minutes including 13 data points in one transmission. As a result temperature you see on screen can be up to 130 minute old unless you manually update, but you will get approx. 10% longer battery life (because it is more efficient to send in bulk) and can add more tags at a shorter logging interval to a single tag manager. "] setDuration:iToastDurationLong] showFrom:self.cachePostbackCell];
		recognizer.cancelsTouchesInView=YES;
	}else
		recognizer.cancelsTouchesInView=NO;
}

- (IBAction)hideKeyboard{
	[[self view]endEditing:YES];
}


-(void)releaseViews{
	self.associateBtn=nil; self.nameCell=nil; self.commentCell=nil;	self.lockFlashCell=nil; self.flashLEDCell=nil; self.cachePostbackCell=nil;
}
-(void)dealloc{
	[self releaseViews];
	self.associatedTag=nil;
	self.tagInfo=nil;
	[super dealloc];
}
- (void)viewDidUnload
{
	[self releaseViews];
    [super viewDidUnload];
}
-(void)viewWillAppear:(BOOL)animated{
//	[self.tableView reloadData];
//	CGSize reqsz =  self.tableView.contentSize;
//	self.contentSizeForViewInPopover = CGSizeMake(480, reqsz.height>600?600:reqsz.height);

	[self _updateCompleteBtn];
	if(_nameCell.textField.text.length==0){

		_nameCell.textField.text = [_tagInfo objectForKey:@"suggestedName"];
		[_nameCell.textField becomeFirstResponder];
		[self _updateCompleteBtn];
		
		/*[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SuggestNewTagName"]
						 jsonString:@"{}"
					  completeBlock:^(NSDictionary* retval){
						  _nameCell.textField.text = [retval objectForKey:@"d"];
						  [_nameCell.textField becomeFirstResponder];
						  [self _updateCompleteBtn];
					  } errorBlock:^(NSError* e){
						  [_nameCell.textField becomeFirstResponder];
						  return YES;
					  } setMac:nil];	*/
	}
	[super viewWillAppear:animated];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
// (type/version/signal/battery)
// (name/co
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section==1)return 3;
	else if(section==0) return (_tagInfo.version1>=2?(_tagInfo.version2>=15?((_tagInfo.version1>=4||_tagInfo.version2>=0xB0||(_tagInfo.version2>=0x90 && _tagInfo.tagType1!=ALS8k) || (_tagInfo.version2>=0x22 && _tagInfo.tagType1==CapSensor))?5:4):3):2);
	return 0;
}
-(void)setTagInfo:(NSDictionary *)tagInfo{
	[_tagInfo autorelease];
	_tagInfo=[tagInfo retain];
	[self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.section==0)switch(ip.row){
		case 0: return _nameCell;
		case 1:return _commentCell;
		case 2: return _lockFlashCell;
		case 3: return _flashLEDCell;
		case 4: return _cachePostbackCell;
		default: return nil;
	}
	else if(ip.section==1){
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"taginfoCell"];
		if(!cell){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"taginfoCell"] autorelease];
		}
		switch(ip.row){
			case 0: cell.textLabel.text = [_tagInfo objectForKey:@"description"]; break;
//			case 1: cell.textLabel.text = [NSString stringWithFormat:@"Version: %@.%@", [_tagInfo objectForKey:@"version1"], [_tagInfo objectForKey:@"version2"]]; break;
			case 1: cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Signal strength: %@dBm",nil), [_tagInfo objectForKey:@"signaldBm"]]; break;
			case 2: cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Battery: %.0f%% left",nil),
										   roundf(100.0 * [[_tagInfo objectForKey:@"batteryRemaining"] floatValue]) ];
		}
		return cell;
	}
	return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==1)
		return NSLocalizedString(@"New Tag Information:",nil);
	else return NSLocalizedString(@"Assign Name:",nil);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0 && indexPath.row==2){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_lockFlashCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_lockFlashCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_lockFlashCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if(indexPath.section==0 && indexPath.row==3){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_flashLEDCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_flashLEDCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_flashLEDCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if(indexPath.section==0 && indexPath.row==4){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_cachePostbackCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_cachePostbackCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_cachePostbackCell.accessoryType = UITableViewCellAccessoryCheckmark;
			if(![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedMultipleTransmitWarning1"] ){
				
				UIAlertView *alert = [[UIAlertView alloc] init];
				[alert setTitle:@"Please read below to understand what to expect when this option is ON"];
				[alert setMessage:@"For example, if you set recording interval to every 10 minutes, temperature is recorded every 10 minutes, but is transmitted every 130 minutes including 13 data points in one transmission. As a result temperature you see on screen can be up to 130 minute old unless you manually update, but you will get approx. 10% longer battery life (because it is more efficient to send in bulk) and can add more tags at a shorter logging interval to a single tag manager. "];
				[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
				[alert setCancelButtonIndex:0];
				[alert show];
				[alert release];

				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedMultipleTransmitWarning1"];
			}
		}
	}else{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}

}


@end
