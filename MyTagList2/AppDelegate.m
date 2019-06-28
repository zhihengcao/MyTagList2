//
//  AppDelegate.m
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AsyncURLConnection.h"
#import "MasterViewController.h"
#import "SpinnerView.h"
#import "DetailViewController.h"
#import "LoginController.h"
#import "Tag.h"
#import "ActivityIndicatorItem.h"
#import "ActionSheet+Blocks.h"
#import "OptionPicker.h"
#import "iToast.h"
#import "NSTimer+Blocks.h"
#import "ActionSheetStringPicker.h"
#import "WebViewController.h"
#import "NSData+Base64.h"
#import "ImageStore.h"
#import "SnippetListViewController.h"
#import "MapRegionPicker.h"
#import "UncaughtExceptionHandler.h"
#import "EventsViewController.h"
#import "SnippetCategoryCollectionViewController.h"
#import "SpecialOptionsViewController.h"
#import <objc/runtime.h>

static const char kBundleKey = 0;

@interface BundleEx : NSBundle
@end

@implementation BundleEx
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
	NSBundle *bundle = objc_getAssociatedObject(self, &kBundleKey);
	if (bundle) {
		return [bundle localizedStringForKey:key value:value table:tableName];
	}
	else {
		return [super localizedStringForKey:key value:value table:tableName];
	}
}
@end

@implementation NSBundle (Language)
+ (void)setLanguage:(NSString *)language
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		object_setClass([NSBundle mainBundle],[BundleEx class]);
	});
	id value = language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil;
	objc_setAssociatedObject([NSBundle mainBundle], &kBundleKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation  UINavigationController(DoublePushError)

- (void)pushViewController2:(UIViewController *)viewController{
	if(![self.topViewController isKindOfClass:[viewController class]]) {
		 @try {
			 [self pushViewController:viewController animated:YES];
		 } @catch (NSException * ex) {
			 [self popToViewController:viewController animated:NO];
		 } @finally {
		 }
	}
}


@end

@implementation AppDelegate
{
	UIView* tutorialView, *tutorialViewTm, *tutorialViewSwitch;
}
@synthesize window = _window;
@synthesize notificationJS_queue=_notificationJS_queue;
@synthesize splitViewController = _splitViewController;
@synthesize mvc = _mvc;
@synthesize dvc = _dvc;
@synthesize evc=_evc, tvc=_tvc;
@synthesize opv_popov=_opv_popov, associate_popov=_associate_popov;
@synthesize updateOption_popov=_updateOption_popov;
@synthesize loginConn = _loginConn, loginEmail=_loginEmail;
@synthesize spinner=_spinner;
@synthesize freqTols=_freqTols, isLimited=_isLimited;
@synthesize locationManager=_locationManager;
@synthesize geocoder=_geocoder;
@synthesize useDegF=_useDegF;
@synthesize wemoPhoneName, wemoPhoneID, wemoHomeID, wemoPhoneKey, push_token;

-(CLGeocoder*)geocoder{
	if(_geocoder==nil){
		_geocoder = [[CLGeocoder alloc]init];
	}
	return _geocoder;
}
-(CLLocationManager*)locationManager{
	if(_locationManager==nil){
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.distanceFilter = kCLLocationAccuracyBest;
		
		if([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
			[_locationManager requestAlwaysAuthorization];
		}

		NSLog(@"kCLDistanceFilterNone=%f",kCLDistanceFilterNone);
	}
	return _locationManager;
}
-(NSMutableDictionary*)regionDictionary{
	if(_regionDictionary==nil)_regionDictionary = [[NSMutableDictionary alloc]init];
	return _regionDictionary;
}
-(void)thermostatSetTarget:(id)sender thermostatTag:(NSMutableDictionary*)thermostatTag
				tempSensor:(NSMutableDictionary*)tempSensor relinquishOwnership:(BOOL)relinquishOwnership{
	
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetThermostatTarget"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:thermostatTag.slaveId],@"thermostatId",
								 tempSensor.uuid,@"tempSensorUuid",
								 [NSNumber numberWithFloat:_dvc.thermostatCell.slider.setValueHigh], @"th_high",
								 [NSNumber numberWithFloat:_dvc.thermostatCell.slider.setValueLow], @"th_low",
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* newThermostat = [retval objectForKey:@"d"];

					  // erase ownership of this thermostat from all tags
					  for(NSMutableDictionary* tag in [tagDictionary allValues]){
						  if(tag.thermostatRef!=nil){
							  if([tag.thermostatRef isEqual:newThermostat])		// compares UUID
								  tag.thermostatRef=nil;
						  }
					  }
					  if(relinquishOwnership){   // can only be true if currently displayed is temp sensor
						  tempSensor.thermostatRef=nil;
						  newThermostat.targetRef=newThermostat;
					  }
					  else{
						  tempSensor.thermostatRef = newThermostat;
						  newThermostat.targetRef=tempSensor;
					  }
					  
					  [self updateTag:newThermostat]; // this will update master view and detail view if selected is thermostat.
					  
					  if([_dvc.tag.uuid isEqual:tempSensor.uuid])
					  {
						  [_dvc updateTag:_dvc.tag loadThermostatSlider:YES animated:YES];   // if selected is not thermostat update the selected.
					  }
					  
					  if(!tempSensor.isNest){
						  // arming this will take long so show toast.
						  iToast* toast =[[iToast makeText:[NSString stringWithFormat:NSLocalizedString(@"Configuring temperature monitoring at %@...",nil), tempSensor.name]
										   ] setDuration:iToastDurationNormal];
						  [toast showFrom:[_mvc cellForTag:tempSensor]];
					  }
					  [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ArmTempSensor"]
										  jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSNumber numberWithInt:tempSensor.slaveId],@"id",
												   nil]
										completeBlock:^(NSDictionary* retval){
											[_dvc revertLoadingBarItem:sender];
											[self updateTag:[retval objectForKey:@"d"] loadThermostatSlider:NO];
											if(!tempSensor.isNest){
												iToast* toast =[[iToast makeText:NSLocalizedString(@"Temperature monitoring successfully configured",nil)	 ] setDuration:iToastDurationNormal];
												[toast showFrom:[_mvc cellForTag:tempSensor]];
											}
										}
									   errorBlock:^(NSError* err, id* showFrom){
										   *showFrom = [_mvc cellForTag:tempSensor];
										   [_dvc revertLoadingBarItem:sender];
										   return YES;
									   }setMac:tempSensor.mac];
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:thermostatTag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:thermostatTag.mac];  // becasue the server will send command to thermostat as a result, the tag manager specified is that of thermostat, not the temp sensor.

}

+(NSMutableDictionary*) findTagBySlaveID:(int)slaveId fromList:(NSArray*)list{
	for (NSMutableDictionary* tag in list) {
		if(tag.slaveId==slaveId)
			return tag;
	}
	return list.count > 0? [list objectAtIndex:0] : nil;
}

+ (void)initialize
{
    NSDictionary *defaults = [NSDictionary 
							  dictionaryWithObject:[NSNumber numberWithBool:YES]
							  forKey:TagListRememberLoginPrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
}
-(NotificationJSQueue*) notificationJS_queue{
	if(_notificationJS_queue==nil){
		_notificationJS_queue=[[NotificationJSQueue alloc]init];
	}
	return _notificationJS_queue;
}
- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"app_language"];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"scan_wemo"];

	[_opv_ac release];_opv_ac=nil;
	[_opv_ms release];_opv_ms=nil;
	[_opv_oor release]; _opv_oor=nil;
	[_opv_phone release];_opv_phone=nil;
	[_opv_temp release];_opv_temp=nil;
	[_opv_cap release];_opv_cap=nil;
	self.opv_popov = nil;

	self.push_token=nil;
	self.loginEmail=nil; self.wemoHomeID=nil; self.wemoPhoneID=nil; self.wemoPhoneKey=nil; self.wemoPhoneName=nil;
	self.wemoTriedForPhoneID=nil;
	[hostReach release];
	self.notificationJS_queue=nil;
	self.window=nil;
	self.mvc=nil;
	self.dvc=nil;
	self.evc=nil;
	self.tvc=nil;
	self.freqTols=nil;
	[_splitViewController release];
	[_opv_popov release];
	[updateTimer invalidate];
	[updateTimer release]; updateTimer=nil;
	self.associate_popov=nil;
	self.locationManager=nil;
	self.geocoder=nil;
	self.uuid_pending_focus=nil;
	self.loginConn=nil;
	self.pendingRegionList=nil;
	self.spinner=nil;
	self.updateOption_popov=nil;
    [super dealloc];
}

// TODO: remove ArmAll2, DisarmAll2, ... etc. Done with X-Set-Mac
-(void)all_tag_action:(NSString*)action withArgs:(NSString*)args btn:(id)sender{
	if(sender)[_mvc showLoadingBarItem:sender];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]){
		__block int jobCount = 0;
		for(NSString* mac in tagManagerMacList){
			jobCount++;
			[AsyncURLConnection request:[NSString stringWithFormat:@"%@ethClient.asmx/%@", WSROOT, action]
							 jsonString:[NSString stringWithFormat:@"{%@}", args]
						  completeBlock:^(NSMutableDictionary* retval){
							  [self updatePartialTagList:[retval objectForKey:@"d"]];
							  jobCount--;
							  if(jobCount==0){
								  if(sender)[_mvc revertLoadingBarItem:sender];
							  }
						  }errorBlock:^(NSError* err, id* showFrom){
							  jobCount--;
							  if(jobCount==0){
								  if(sender)[_mvc revertLoadingBarItem:sender];
							  }
							  *showFrom=sender;
							  return YES;
						  } setMac:mac timeOut:60+10*_mvc.tagList.count];
		}
	}else{
		[AsyncURLConnection request:[NSString stringWithFormat:@"%@ethClient.asmx/%@", WSROOT, action]
						 jsonString:[NSString stringWithFormat: @"{%@}", args]
				  completeBlock:^(NSMutableDictionary* retval){
					  [self updatePartialTagList:[retval objectForKey:@"d"]];
					  if(sender)[_mvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  if(sender)[_mvc revertLoadingBarItem:sender];
					  *showFrom=sender;
					  return YES;
				  } setMac:nil timeOut:60+10*_mvc.tagList.count];
	}
}
- (void)stopBeepAllBtnPressed:(id)sender
{
	[self all_tag_action:@"StopBeepAll" withArgs:@"autoRetry: true" btn:sender];	
}
-(void)helpBtnPressed:(id)sender
{
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	[sheet addButtonWithTitle:NSLocalizedString(@"Support Portal",nil) block:^(NSInteger index){
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"https://mytaglist.com/eth/tickets.html#getHelpPage" ]];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Tutorial",nil) block:^(NSInteger index){
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"http://mytaglist.com/iosapp.html" ]];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"FAQ",nil) block:^(NSInteger index){
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"http://store.wirelesstag.net/pages/support" ]];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Forum",nil) block:^(NSInteger index){
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"https://groups.google.com/forum/?fromgroups#!forum/wireless-sensor-tags" ]];
	}];
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:_splitViewController.view];
	else [sheet showInView:[self window]];
	[sheet release];

}
- (void)armAllBtnPressed:(id)sender
{
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	[sheet addButtonWithTitle:NSLocalizedString(@"Arm All",nil) block:^(NSInteger index){
		[self all_tag_action:@"ArmAll" withArgs:@"autoRetry: true" btn:sender];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Arm Some",nil) block:^(NSInteger index){
		NSMutableArray* tagNames = [[[NSMutableArray alloc] initWithCapacity:_mvc.tagList.count] autorelease];
		NSMutableDictionary* num2TagMapping = [[[NSMutableDictionary alloc] initWithCapacity:_mvc.tagList.count]autorelease];
		int i=0;
		
		NSArray* uuids_selected = [[NSUserDefaults standardUserDefaults] arrayForKey:TagSelectedToArmPrefKey];
		NSMutableSet* indice_selected = [[NSMutableSet alloc]init];
		for(NSDictionary* tag in _mvc.tagList){
			if(tag.hasMotion){
				[tagNames addObject:tag.name];
				[num2TagMapping setObject:tag forKey:[NSNumber numberWithInt:i]];
				if([uuids_selected containsObject:tag.uuid])
					[indice_selected addObject:[NSNumber numberWithInt:i]];
				i++;
			}
		}
		
		OptionPicker* picker = [[OptionPicker alloc]initWithOptions:tagNames
													  selectedMulti:indice_selected doneMulti:^(NSSet* selected, OptionPicker* picker2){
														  picker2.dismissUI(YES);
														  NSMutableArray* uuids_selected_new = [[[NSMutableArray alloc] initWithCapacity:selected.count] autorelease];
														  NSArray* selectedTags =[num2TagMapping objectsForKeys:[selected allObjects] notFoundMarker:[NSNull null]];
														  for(NSDictionary* tag in selectedTags){
															  [uuids_selected_new addObject:tag.uuid];
														  }
														  [[NSUserDefaults standardUserDefaults] setObject:uuids_selected_new forKey:TagSelectedToArmPrefKey];
														  if(selected.count==0)return;
														  
														  if(sender)
															  [_mvc showLoadingBarItem:sender];
														  
														  if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]){
															  __block int jobCount = 0;
															  for(NSString* mac in tagManagerMacList){
																  NSMutableArray* slaveids = [[[NSMutableArray alloc] init] autorelease];
																  for(NSDictionary* tag in selectedTags){
																	  if([tag.mac isEqualToString:mac])[slaveids addObject:[NSNumber numberWithInt:tag.slaveId]];
																  }
																  if(slaveids.count==0)continue;
																  
																  jobCount++;
																  [AsyncURLConnection request:[NSString stringWithFormat:@"%@ethClient.asmx/ArmSome", WSROOT]
																					  jsonObj:@{@"ids": slaveids}
																				completeBlock:^(NSMutableDictionary* retval){
																					[self updatePartialTagList:[retval objectForKey:@"d"]];
																					jobCount--;
																					if(jobCount==0){
																						if(sender)[_mvc revertLoadingBarItem:sender];
																					}
																				}errorBlock:^(NSError* err, id* showFrom){
																					jobCount--;
																					if(jobCount==0){
																						if(sender)[_mvc revertLoadingBarItem:sender];
																					}
																					*showFrom=sender;
																					return YES;
																				} setMac:mac];
															  }
														  }else{
															  NSMutableArray* slaveids = [[[NSMutableArray alloc] init] autorelease];
															  for(NSDictionary* tag in selectedTags){
																  [slaveids addObject:[NSNumber numberWithInt:tag.slaveId]];
															  }
															  [AsyncURLConnection request:[NSString stringWithFormat:@"%@ethClient.asmx/ArmSome", WSROOT]
																				  jsonObj:@{@"ids": slaveids}
																			completeBlock:^(NSMutableDictionary* retval){
																				[self updatePartialTagList:[retval objectForKey:@"d"]];
																				if(sender)[_mvc revertLoadingBarItem:sender];
																			}errorBlock:^(NSError* err, id* showFrom){
																				if(sender)[_mvc revertLoadingBarItem:sender];
																				*showFrom=sender;
																				return YES;
																			} setMac:nil];
														  }

														  
													  }];
		picker.title=NSLocalizedString(@"Choose tags to arm",nil);
		[self showPicker:picker fromBarItem:sender];

	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Disarm All",nil) block:^(NSInteger index){
		[self all_tag_action:@"DisarmAll" withArgs:@"autoRetry: true" btn:sender];
	}];
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:_splitViewController.view];
	else [sheet showInView:[self window]];
	[sheet release];

}
-(void)showLogin{
	LoginController* lc = [[[LoginController alloc] init] autorelease];
	[lc setDelegate:self];
	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:lc] autorelease];
	//UITableViewController* vc = 	([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)? _evc: _mvc;
	[self.window.rootViewController presentViewController:nav animated:YES completion:nil];
	//[_mvc presentViewController:nav animated:YES completion:nil];
}

-(void)doLogout:(id)sender{
	[_mvc showLoadingBarItem:sender];
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SignOut"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 [_evc removeEvents];
						 [_tvc removeData];
						 [_mvc revertLoadingBarItem:sender];
						 [self stopComet];
						 [updateTimer invalidate];
						 [updateTimer release]; updateTimer=nil;
						 [knownWeMo release]; knownWeMo=nil;
						 [self showLogin];
					 }errorBlock:^(NSError* err, id* showFrom){
						 *showFrom = sender;
						 [_mvc revertLoadingBarItem:sender];
						 return YES;
					 } setMac:nil];
}
-(void) logoutBtnPressed:(id)sender
{
	if(self.push_token!=nil)
	{
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Continue to receive push notifications?",nil)
									 message:NSLocalizedString(@"Answer yes to continue to notifications of events for tags under this account you are logging out.",nil)
							cancelButtonItem:[RIButtonItem itemWithLabel:NSLocalizedString(@"Yes",nil) action:^{
								[self doLogout:sender];
							}]
							otherButtonItems:[RIButtonItem itemWithLabel:NSLocalizedString(@"No",nil) action:^{
			
			[AsyncURLConnection request:[WSROOT stringByAppendingString: @"ethMobileNotifications.asmx/DeleteTokens"]
								jsonObj:@{ @"device_uuids": @[ self.push_token ]}
						  completeBlock:^(NSDictionary* data){
							  [self doLogout:sender];
						  }errorBlock:^(NSError* err, id* showFrom){
							  *showFrom=sender;
							  return YES;
						  }setMac:nil ];
			
		}], nil] autorelease ] show];
	}
	else
		[self doLogout:sender];
}
-(void) enqueueNotificationJSForTag:(NSDictionary*)tag
{
	NSString* notifcationJS = tag.notificationJS;
	if((id)notifcationJS!=[NSNull null] && notifcationJS.length>0){
		
		[self.notificationJS_queue enqueue:	[[[NSDictionary alloc] initWithObjectsAndKeys:notifcationJS, @"notificationJS",
											  tag.mac,@"mac",
											  [NSNumber numberWithInt:tag.slaveId], @"slaveId",
											  tag.uuid, @"uuid", nil] autorelease]];
		
	}
	for(NSDictionary* mirror in tag.mirrors){
		NSString* notifcationJS2 = mirror.notificationJS;
		if((id)notifcationJS2!=[NSNull null] && notifcationJS2.length>0){
			[self.notificationJS_queue enqueue:[[[NSDictionary alloc] initWithObjectsAndKeys:notifcationJS2, @"notificationJS", mirror.mac,
												@"mac",
												 [NSNumber numberWithInt:tag.slaveId], @"slaveId",
												 tag.uuid, @"uuid", nil] autorelease]];
			return;
		}			
	}
}
-(void) updatePartialTagList:(NSMutableArray*)list
{
	for(NSMutableDictionary* tag in list){
		[_mvc updateTag:tag loadImage:YES];
//		if(([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone || _dvc.navigationController.topViewController==_dvc) &&
		if(_dvc.tag!=nil && [_dvc.tag.uuid isEqualToString: tag.uuid] )
			[_dvc updateTag:tag loadThermostatSlider:YES animated:YES];
		
		[self enqueueNotificationJSForTag:tag];
	}
}
-(void)tutorialViewTapped{
	[tutorialView removeFromSuperview];
}
-(void)tutorialViewTmTapped{
	[tutorialViewTm removeFromSuperview];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedTutorialTm0"];
}
-(void)tutorialViewSwitchTapped{
	[tutorialViewSwitch removeFromSuperview];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedTutorialSwitch"];
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)newStatusBarFrame {
	if(tutorialView){
		tutorialView.frame = self.window.frame;
		UIView* iv = [tutorialView.subviews objectAtIndex:0];
		if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
			iv.frame=CGRectMake(tutorialView.frame.size.width-iv.frame.size.width, 20-newStatusBarFrame.size.height, iv.frame.size.width, iv.frame.size.height);
		else
			iv.frame=CGRectMake(_mvc.view.frame.size.width-iv.frame.size.width, 20, iv.frame.size.width, iv.frame.size.height);
	}
	else if(tutorialViewTm){
		tutorialViewTm.frame = self.window.frame;
		UIView* iv = [tutorialViewTm.subviews objectAtIndex:0];
		if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
			iv.frame=CGRectMake(tutorialViewTm.frame.size.width/2-iv.frame.size.width/2, 30-newStatusBarFrame.size.height, iv.frame.size.width, iv.frame.size.height);
		else
			iv.frame=CGRectMake(_mvc.view.frame.size.width/2-iv.frame.size.width/2, 30, iv.frame.size.width, iv.frame.size.height);
	}
	else if(tutorialViewSwitch){
		[self updateTutorialViewSwitchSize];
	}

}
-(void)updateTutorialViewSwitchSize{
	tutorialViewSwitch.frame = self.window.frame;
	BOOL isLandscape = self.window.frame.size.height < self.window.frame.size.width;
	UIView* iv = [tutorialViewSwitch.subviews objectAtIndex:0];
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		iv.frame=CGRectMake(tutorialViewSwitch.frame.size.width-iv.frame.size.width, isLandscape? 80:113, iv.frame.size.width, iv.frame.size.height);
	else
		iv.frame=CGRectMake(_mvc.view.frame.size.width-iv.frame.size.width, 113, iv.frame.size.width, iv.frame.size.height);
}
-(void) updateTagList:(NSMutableArray*)list
{
	isTagListEmpty = (list.count==0);
	
	[self refreshThermostatLink:list];
	
	for(NSDictionary* tag in list)
		[self enqueueNotificationJSForTag:tag];
	
	[_mvc setTagList:list];
	if(list.count==0 && _mvc.topPVC.isMVCVisible){
		if(tutorialView==nil){
			tutorialView = [[UIView alloc]initWithFrame:self.window.bounds];
			UIImageView* iv = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial.png"]] autorelease];
			iv.frame=CGRectMake(_mvc.view.frame.size.width-iv.frame.size.width-25, [UIApplication sharedApplication].statusBarFrame.size.height+THUMB_HEIGHT, iv.frame.size.width, iv.frame.size.height);
			tutorialView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
			[tutorialView addSubview:iv];
			[tutorialView addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialViewTapped)] autorelease]];
			
		}
		[self.window addSubview:tutorialView];
	}else{
		[tutorialView removeFromSuperview];
		
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedTutorialSwitch"] ){
			
			if(tutorialViewSwitch==nil){
				tutorialViewSwitch = [[UIView alloc]initWithFrame:self.window.frame];
				UIImageView* iv = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial_switch.png"]] autorelease];
				tutorialViewSwitch.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
				[tutorialViewSwitch addSubview:iv];
				[tutorialViewSwitch addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialViewSwitchTapped)] autorelease]];
				[self updateTutorialViewSwitchSize];
			}
			[self.window addSubview:tutorialViewSwitch];
		}
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]) {
			if(!_dbidDictonary)_dbidDictonary=[[NSMutableDictionary alloc]init];
			else [_dbidDictonary removeAllObjects];
			for(NSDictionary* tag in list){
				NSNumber* dbid = [tag objectForKey:@"dbid"];
				if(dbid)
					[_dbidDictonary setObject:@1 forKey:dbid];
			}
		}
	}

	if(self.uuid_pending_focus==nil && ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone || _dvc.navigationController.topViewController==_dvc)){
//		[_dvc updateTag:[AppDelegate findTagBySlaveID:_dvc.tag.slaveId fromList:list]];

		_dvc.tag = [AppDelegate findTagBySlaveID:slaveIdToDisplay fromList:list];
		[self loadScriptsInBackgroundIfNeeded];
	}
	
	if(self.uuid_pending_focus!=nil)
	{
		[self focusOnTagUUID:self.uuid_pending_focus];
		self.uuid_pending_focus=nil;
	}
}

-(void) refreshThermostatLink:(NSArray*)list{
	if(tagDictionary==nil){
		tagDictionary = [[NSMutableDictionary alloc] init];
		thermostatDictionary=[[NSMutableDictionary alloc] init];
	}else{
		//[tagDictionary removeAllObjects];
		//[thermostatDictionary removeAllObjects];
	}
	for(NSMutableDictionary* tag in list){
		if((id)tag==[NSNull null] || tag==nil || tag.uuid==nil)break;
		
		if(![tag isKindOfClass:[NSMutableDictionary class]])
			tag = [[tag mutableCopy] autorelease];
		
		if(tag.hasThermostat)
			[thermostatDictionary setObject:tag forKey:tag.uuid];
		
		[tagDictionary setObject:tag forKey:tag.uuid];
		tag.thermostatRef=nil;
	}
	for(NSMutableDictionary* ts in [thermostatDictionary allValues]){
		NSMutableDictionary* tag = [tagDictionary objectForKey:ts.thermostat.targetUuid];
		tag.thermostatRef = ts;
		ts.targetRef = tag;
	}
}
- (void)stopBeepBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/StopBeep"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
- (void)beepBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/Beep"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
								 [NSNumber numberWithInt:_dvc.tag.beepDurationDefault],@"beepDuration", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];	
}
- (void)armBtnPressed:(id)sender withConfig:(NSDictionary*)config{

	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveMotionSensorConfig2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
								 config, @"config",
								 [NSNumber numberWithBool:opv_apply_all],@"applyAll",
								 [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]],@"allMac",
								 nil]
				  completeBlock:^(NSDictionary* retval){

	
					  [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/Arm"]
										  jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
												   [NSNumber numberWithBool:YES],@"door_mode_set_closed", nil]
									completeBlock:^(NSDictionary* retval){
										NSMutableDictionary* tag = [retval objectForKey:@"d"];
										[self updateTag:tag];
										[_dvc revertLoadingBarItem:sender];
									}errorBlock:^(NSError* err, id* showFrom){
										*showFrom = sender;
										[_dvc revertLoadingBarItem:sender];
										return YES;
									}setMac:_dvc.xSetMac];

				  }errorBlock:^(NSError* err, id* showFrom){
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}

- (void)armBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/Arm"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
								 [NSNumber numberWithBool:YES],@"door_mode_set_closed", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
- (void)disarmBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/Disarm"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];	
}
-(void) pingTag:(NSMutableDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/PingTag"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:tag];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void) updateNowBtnPressed:(id)sender{
	[self reqImmediatePostback:sender];
}
-(void) updateBtnPressed:(id)sender{
	[self unifiedUpdateBtnAction:sender applyAll:NO];
}

-(void)optionEarnReferralBtnClicked:(TableLoadingButtonCell *)btncell{
	
	[btncell showLoading];
	WebViewController* wv = [[WebViewController alloc]initWithTitle:NSLocalizedString(@"Affiliate Program",nil)];
	
	NSURL *url = [NSURL URLWithString:	[WSROOT stringByAppendingString:@"eth/affiliate.html?from_app"]];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	
	[wv loadRequest:req WithCompletion:^{
		[btncell revertLoading];
		if(_optnav) {
			[_optnav pushViewController2:wv];
			if([_optnav respondsToSelector:@selector(setPreferredContentSize:)])
				_optnav.preferredContentSize= CGSizeMake(760, 700);

		}else{
			[(UINavigationController*)self.window.rootViewController pushViewController2:wv];
		}
		[wv release];
	} onClose:^(BOOL cancelled) {}];

	
}

-(void)optionViewWebAccountBtnClicked:(TableLoadingButtonCell *)btncell{
	[btncell showLoading];
	WebViewController* wv = [[WebViewController alloc]initWithTitle:NSLocalizedString(@"Web Interface",nil)];
	
	NSURL *url = [NSURL URLWithString:	[WSROOT stringByAppendingString:@"eth/index.html?update_account"]];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	
	[wv loadRequest:req WithCompletion:^{
		[btncell revertLoading];
		if(_optnav) {
			[_optnav pushViewController2:wv];
			if([_optnav respondsToSelector:@selector(setPreferredContentSize:)])
				_optnav.preferredContentSize= CGSizeMake(720, 700);

		}else{
			[(UINavigationController*)self.window.rootViewController pushViewController2:wv];
		}
		[wv release];
	} onClose:^(BOOL cancelled) {
		if(!cancelled){
			[self refreshTagManagerDropDown];
		}
	}];

}
-(void)optionViewTwitterLoginBtnClicked:(TableLoadingButtonCell*)btncell
{
	[btncell showLoading];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/GetTwitterAuthorizeURL"]
					 jsonString:@"{}"
				  completeBlock:^(NSDictionary* retval){
					  [btncell revertLoading];
					
					  WebViewController* wv = [[[WebViewController alloc]initWithTitle:NSLocalizedString(@"Twitter Login",nil)] autorelease];
					  
					  if(_optnav) {
						  [_optnav pushViewController2:wv];
					  }else{
						  //[_dvc.navigationController pushViewController:wv animated:YES];
						  [(UINavigationController*)self.window.rootViewController pushViewController2:wv];
					  }
					  NSURL *url = [NSURL URLWithString:	[retval objectForKey:@"d"]];
					  NSURLRequest *req = [NSURLRequest requestWithURL:url];
					  [[wv webView] loadRequest:req];
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = btncell;
					  [btncell revertLoading];
					  return YES;
				  } setMac:nil];		
}

-(void)saveWaterSensorConfig:(NSMutableDictionary*)config{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveWaterSensorConfig2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
								 config, @"config",
								 [NSNumber numberWithBool:opv_apply_all],@"applyAll",
								 [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]],@"allMac",
								 nil]
				  completeBlock:nil errorBlock:^(NSError* err, id* showFrom){
					  return YES;
				  }setMac:_dvc.xSetMac];
}

-(void)optionViewSaveBtnClicked:(OptionsViewController *)opv {
	UIBarButtonItem* oldbi=opv.navigationItem.rightBarButtonItem;
	[opv showLoadingBarItem:opv.navigationItem.rightBarButtonItem];
	
	
	NSString* saveMethod;  NSNumber* sensorType=nil;
	if(opv.config.isMsConfig){
		saveMethod=@"ethClient.asmx/SaveMotionSensorConfig2"; sensorType=@0;
	}
	else if(opv.config.isOorConfig)
	{
		saveMethod=@"ethClient.asmx/SaveOutOfRangeConfig2"; sensorType=@4;
		int newOorGrace = ((OorOptionsViewController*)opv).oorGrace;
		if(newOorGrace!=_dvc.tag.oorGrace){
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetOutOfRangeGrace"]
								jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
										 [NSNumber numberWithInt:newOorGrace], @"oorGrace",
										 [NSNumber numberWithBool:opv_apply_all],@"applyAll",
										 nil]
						  completeBlock:^(NSDictionary* retval){
							  [self updateTag:[retval objectForKey:@"d"]];
						  }errorBlock:^(NSError* err, id* showFrom){
							  *showFrom = nil;
							  return YES;
						  }setMac:_dvc.xSetMac];
		}
	}
	else if(opv.config.isTempConfig){
		if(self.useDegF != (opv.config.temp_unit==1)){
			self.useDegF =(opv.config.temp_unit==1);
			[self.mvc.tableView reloadData];
		}
		saveMethod=@"ethClient.asmx/SaveTempSensorConfig2"; sensorType=@1;
	}
	else if(opv.config.isLBConfig){
		saveMethod=@"ethClient.asmx/SaveLowBatteryConfig2";
	}
	else if(opv.config.isCapConfig){
		CapOptionsViewController* cap_opv = (CapOptionsViewController*)opv;
		if(cap_opv.rnc_cap2_changed && cap_opv.rnc_cap2){
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveRepeatNotifyConfig"]
								jsonObj:@{@"uuid": opv_apply_all?@"00000000-0000-0000-0000-000000000000":_dvc.tag.uuid, @"sensorType": @3, @"config":@[cap_opv.rnc_cap2]} completeBlock:nil
							 errorBlock:^(NSError* err, id* showFrom){
								 *showFrom = opv.navigationItem.rightBarButtonItem;
								 return YES;
							 } setMac:nil];
		}
		saveMethod=@"ethClient.asmx/SaveCapSensorConfig2"; sensorType=@2;
	}
	else if(opv.config.isLightConfig){
		saveMethod=@"ethClient.asmx/SaveLightSensorConfig";sensorType=@7;
	}
	else if(opv.config.isKumostatConfig){
		saveMethod=@"ethClient.asmx/SaveKumostatConfig2";
	}
	else if(opv.config.isPhonesConfig)
		saveMethod=@"ethClient.asmx/SaveMobileNotificationConfig2";
	else if(opv.config.isAccountConfig){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveAccountConfig"]
							jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:opv.config, @"config",nil]
					  completeBlock:^(NSDictionary* retval){
						  [opv revertLoadingBarItem:oldbi];

						  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                              if(_opv_popov){
                                  [_opv_popov dismissPopoverAnimated:YES]; 				[self unBlur];
                              }else{
                                  [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
                              }
						  }else{
							  [(UINavigationController*)self.window.rootViewController popViewControllerAnimated:YES];
						  }

					  }errorBlock:^(NSError* err, id* showFrom){
						  *showFrom = opv.navigationItem.rightBarButtonItem;
						  [opv revertLoadingBarItem:oldbi];
						  return YES;
					  } setMac:nil];			
		return;
	}else{
		return;
	}
	//[opv.config removeObjectForKey:@"__type"];
	
	if(sensorType && opv.updatedRepeatNotifyConfigs.count>0){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveRepeatNotifyConfig"]
							jsonObj:@{@"uuid": opv_apply_all?@"00000000-0000-0000-0000-000000000000":_dvc.tag.uuid, @"sensorType": sensorType, @"config":opv.updatedRepeatNotifyConfigs} completeBlock:nil
						 errorBlock:^(NSError* err, id* showFrom){
						  *showFrom = opv.navigationItem.rightBarButtonItem;
						  return YES;
					  } setMac:nil];
	}
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:saveMethod]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", 
								 opv.config, @"config",
								 [NSNumber numberWithBool:opv_apply_all],@"applyAll", 
								 [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]],@"allMac", 
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  
					  if(opv.config.isTempConfig){
						  [_opv_temp armDisarmTempsensorAsNeededWithApplyAll:opv_apply_all];
					  }
					  else if(opv.config.isLightConfig){
						  [_opv_light armDisarmLightSensorAsNeededWithApplyAll:opv_apply_all];
					  }
					  else if(opv.config.isCapConfig){
						  [_opv_cap armDisarmCapsensorAsNeededWithApplyAll:opv_apply_all];
					  }
					  else if(opv.config.isLBConfig){
						  if(opv_apply_all){
							  [self reloadTagListWithCompletion:nil];
						  }else{
							  [self reloadTagBySlaveId:_dvc.tag.slaveId];
						  }
					  }

					  [opv revertLoadingBarItem:oldbi];

                      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                          if(_opv_popov){
                              [_opv_popov dismissPopoverAnimated:YES];                 [self unBlur];
                          }else{
                              [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
                          }
                      }
					  else{
						  [(UINavigationController*)self.window.rootViewController popViewControllerAnimated:YES];
					  }

				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = opv.navigationItem.rightBarButtonItem;
					  [opv revertLoadingBarItem:oldbi];
					  return YES;
				  }setMac:_dvc.xSetMac];	
}

-(void)unBlur{
/*	if(isOS8){
		[UIView animateWithDuration:0.2f animations:^{
			bluredEffectView.effect=nil;
		} completion:^(BOOL finished) {
			[bluredEffectView removeFromSuperview];
			bluredEffectView=nil;
		}];
	}*/
}
-(void)blurView:(UIView*)view{
/*	if(isOS8){
		bluredEffectView = [[[UIVisualEffectView alloc]init]autorelease];  //[[[UIVisualEffectView alloc] initWithEffect:blurEffect] autorelease];
		[bluredEffectView setFrame:view.bounds];
		[view addSubview:bluredEffectView];
		[UIView animateWithDuration:0.3f animations:^{
			bluredEffectView.effect=[MyBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		}];
	}*/
}
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
	[self unBlur];
}
-(void) open_opv:(UITableViewController*)opv BarItem:(id)sender{
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		_optnav = [[[UINavigationController alloc] initWithRootViewController:opv] autorelease];
		if(isOS8){
			_optnav.modalPresentationStyle=UIModalPresentationPopover;
			if([sender isKindOfClass:[UITableViewCell class]]){
				_optnav.popoverPresentationController.sourceView=sender;
				_optnav.popoverPresentationController.sourceRect=CGRectMake( ((UITableViewCell*)sender).bounds.size.width/2, ((UITableViewCell*)sender).bounds.size.height-8, 0,0);
			}else
				_optnav.popoverPresentationController.barButtonItem=sender;
            [iToast.topMostController presentViewController:_optnav animated:YES completion:nil];
		}else{
			if(!_opv_popov || isOS8) {
				self.opv_popov = [[[UIPopoverController alloc] initWithContentViewController:_optnav] autorelease];
				_opv_popov.delegate=self;
				//			opv.popoverContainer = _opv_popov;
				//			_opv_popov.popoverContentSize = CGSizeMake(480, 800);
			}else{
				//			opv.popoverContainer = _opv_popov;
				_opv_popov.contentViewController = _optnav;
			}
			_opv_popov.popoverContentSize = CGSizeMake(480, 800); //opv.contentSizeForViewInPopover;
			[self blurView:_splitViewController.view];
			
			if([sender isKindOfClass:[UITableViewCell class]]){
				UITableViewCell* cell = sender;
				[_opv_popov presentPopoverFromRect:cell.bounds inView:cell.contentView
						  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}else{
				//if(isOS8)_opv_popov.popoverContentSize = CGSizeMake(480, 600);
				[_opv_popov presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
		}
	}else
//		[_dvc.navigationController pushViewController:_opv animated:YES];
		[(UINavigationController*)self.window.rootViewController pushViewController2:opv];
}
-(void)specialOptionsBtnPressed:(id)sender{
	SpecialOptionsViewController* sov = [[SpecialOptionsViewController alloc]initForTag:_dvc.tag];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		sov.dismissUI=^(BOOL animated){
            if(_opv_popov){
                [_opv_popov dismissPopoverAnimated:YES];                 [self unBlur];
            }else{
                [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            }
		};
	}else{
		sov.dismissUI=^(BOOL animated){
			[_dvc.navigationController popViewControllerAnimated:animated];
		};
	}

	[self open_opv:sov BarItem:sender];
}

-(void) capOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_cap:_dvc.tag BarItem:sender];	
}
-(void) lightOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_light:_dvc.tag BarItem:sender];
}

-(void) msOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_ms:_dvc.tag BarItem:sender];	
}
-(void) lbOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_lb:_dvc.tag BarItem:sender];
}
-(void) tempOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_temp:_dvc.tag BarItem:sender];	
}
-(void) oorOptionsBtnPressed:(id)sender{
	opv_apply_all=NO;
	[self open_opv_oor:_dvc.tag BarItem:sender];	
}

-(void) optionsBtnPressed:(id)sender{

	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	TagType type = _dvc.tag.tagType;

	if(_dvc.tag.isKumostat){
		[sheet addButtonWithTitle:@"Wiring Options" block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_kumostat:_dvc.tag BarItem:sender];
		}];
	}
	if(type==MotionSensor || type==MotionRH || type==PIR || type==TagPro)
		[sheet addButtonWithTitle:NSLocalizedString(@"Motion Sensor Options",nil) block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_ms:_dvc.tag BarItem:sender];
		}];
	if(type==ReedSensor || type==ReedSensor_noHTU)
		[sheet addButtonWithTitle:NSLocalizedString(@"Reed Sensor Options",nil) block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_ms:_dvc.tag BarItem:sender];
		}];
	
	if(_dvc.tag.hasCap)
		[sheet addButtonWithTitle:NSLocalizedString(@"Humidity/Moisture Sensor",nil) block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_cap:_dvc.tag BarItem:sender];
		}];
	
	[sheet addButtonWithTitle:NSLocalizedString(@"Temperature Sensor",nil) block:^(NSInteger index){
		opv_apply_all=NO;
		[self open_opv_temp:_dvc.tag BarItem:sender];
	}];
	if(!_dvc.tag.isVirtualTag){
		[sheet addButtonWithTitle:NSLocalizedString(@"Out of Range Options",nil) block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_oor:_dvc.tag BarItem:sender];
		}];
		[sheet addButtonWithTitle:NSLocalizedString(@"Low Battery Alerts",nil) block:^(NSInteger index){
			opv_apply_all=NO;
			[self open_opv_lb:_dvc.tag BarItem:sender];
		}];
		if(_dvc.tag.version1>=2 && !(_dvc.tag.rev==0xF && _dvc.tag.tagType==MotionSensor)){
			[sheet addButtonWithTitle:NSLocalizedString(@"Receiver Mode",nil) block:^(NSInteger index){
				[self tagRssiModeOption:_dvc.tag BarItem:sender];
			}];
		}
	}
	[sheet addButtonWithTitle:NSLocalizedString(@"Phone Options",nil) block:^(NSInteger index){
		opv_apply_all=NO;
		[self open_opv_phones:_dvc.tag BarItem:sender];
	}];
	
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:_splitViewController.view];
	else [sheet showInView:[self window]];
	[sheet release];

}
-(void) unassociateBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/UnassociateTag"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  if(tag.alive){
						  [_mvc deleteTagWithUuid:tag.uuid];
						  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
							  [_dvc.navigationController popToRootViewControllerAnimated:YES];
						  }
					  }else{
						  LambdaAlert *alert = [[LambdaAlert alloc] initWithTitle:@"Wireless Tag"
												message:NSLocalizedString(@"Tag failed to respond to unassociation request. Did the tag start flashing?",nil)];
						  [alert addButtonWithTitle:NSLocalizedString(@"Yes, remove",nil) block:^{
							  [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTag"]
											   jsonString:[NSString stringWithFormat:@"{id: %d}",tag.slaveId]
											completeBlock:nil errorBlock:nil setMac:_dvc.xSetMac];
							  [_mvc deleteTagWithUuid:tag.uuid];
							  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
								  [_dvc.navigationController popToRootViewControllerAnimated:YES];
							  }
						  }];
						  [alert addButtonWithTitle:NSLocalizedString(@"No, let's retry",nil) block:nil];
						  [alert show];
						  [alert release];
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];		
}
-(void) resetEventBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ResetTag"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void) calibrateRadioBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/CalibrateFrequencyOffset"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void) resetStatesBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SoftwareResetTag"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}

-(void)dimLED:(id)sender dimTo:(float)dimTo speed:(NSInteger)speed{
	
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"WeMoLink.asmx/DimLED"]
						jsonObj:@{@"id":[_dvc.tag objectForKey:@"slaveId"],@"dimTo": [NSNumber numberWithFloat:dimTo], @"speed": [NSNumber numberWithInteger:speed]}
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:_dvc.xSetMac];
}
-(void) tempStatsBtnPressed:(id)sender withLux:(BOOL)withLux{

//	[_dvc showLoadingBarItem:sender];
	if(_dvc.tag==nil)return;
	
	syncLoadRawData_t loader =^NSArray*(NSString* start, NSString* end){
		NSLog(@"GetStatsRaw(%@ - %@)", start,end);
		NSError* error;
		NSDictionary* ret = [AsyncURLConnection syncRequest:
							 [WSROOT stringByAppendingString:withLux?@"ethLogs.asmx/GetStatsLuxRaw":@"ethLogs.asmx/GetStatsRaw"]
													jsonObj:@{@"id": [_dvc.tag objectForKey:@"slaveId"],
															  @"fromDate":start, @"toDate":end }
													  error:&error setMac:_dvc.xSetMac];
		return [ret objectForKey:@"d"];
	};
	
	shareHandler_t shareHandler = ^(GraphViewController* vc1, UIBarButtonItem* sender_vc, UIImage* snapshot, NSDate* fromDate, NSDate* toDate){
		ShareTextDescription* text = [[[ShareTextDescription alloc]initWithUUID:@[_dvc.tag.uuid==nil?[NSNull null]:_dvc.tag.uuid] andName:_dvc.tag.name
																		andType:@"temperature" fromDate:fromDate toDate:toDate] autorelease];
		
		
		UIPopoverController* popover=nil;
		UIActivityViewController *ac=  [[UIActivityViewController alloc] initWithActivityItems:@[snapshot,text]	applicationActivities:nil];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			popover = [[UIPopoverController alloc] initWithContentViewController:ac];
			popover.delegate = self;
		}
		ac.excludedActivityTypes=@[UIActivityTypeAssignToContact];
		ac.completionHandler=^(NSString* type, BOOL completed){
			//[_dvc.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
			if(popover!=nil){
				[popover dismissPopoverAnimated:YES];
				[popover release]; 				[self unBlur];
            }
			if(completed && ![type isEqualToString:UIActivityTypePostToTwitter]){
				[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethLogs.asmx/EditSharePermissions"]
									jsonObj:@{@"ids": @[[NSNumber numberWithInt:_dvc.tag.slaveId]],
											  @"shareTemperature": @[@YES],
											  @"shareMotion":[NSNull null]}
							  completeBlock:nil errorBlock:^(NSError* err, id* showFrom){
								  return YES;} setMac:_dvc.xSetMac];
			}
		};
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			if(isOS8){
				ac.modalPresentationStyle=UIModalPresentationPopover;
				ac.popoverPresentationController.barButtonItem=sender_vc;
				[vc1 presentViewController:ac animated:YES completion:nil];
			}else{
				//self.popover.delegate = self;
				//if(isOS8)popover.popoverContentSize = CGSizeMake(480, 300);
				[self blurView:_splitViewController.view];
				[popover presentPopoverFromBarButtonItem:sender_vc permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
		}else
			[vc1 presentViewController:ac animated:YES completion:nil];
	};
	
	NSString* title =[_dvc.tag.name stringByAppendingString:NSLocalizedString(@" - Graph",nil)];
	
	GraphViewController* vc = [[[LandscapeGraphViewController alloc] initPrimaryWithTitle:title andFrame:_dvc.view.frame
																			andSpanLoader:^(onDataSpan onData){
																				if(self.spinner==nil)
																					self.spinner = [SpinnerView loadSpinnerIntoView:self.window];

																				[AsyncURLConnection
																				 request:[WSROOT stringByAppendingString:@"ethLogs.asmx/GetMultiTagStatsSpan"]
																				 jsonObj:@{@"ids": @[[_dvc.tag objectForKey:@"slaveId"]],
																						   @"type":@"temperature"}
																				 completeBlock:^(NSDictionary* retval){
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 NSDictionary* d =[retval objectForKey:@"d"];
																					 onData(d);
																				 }
																				 errorBlock:^(NSError* err, id* showFrom){
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 *showFrom = nil;
																					 return YES;
																				 }setMac:_dvc.xSetMac];

																			}andHourlyLoader:^(onHourlyData onData){
																				if(self.spinner==nil)
																					self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																				[AsyncURLConnection
																				 request:[WSROOT stringByAppendingString:withLux?@"ethLogs.asmx/GetTemperatureLuxStats3":@"ethLogs.asmx/GetTemperatureStats3"]
																									jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																											 [_dvc.tag objectForKey:@"slaveId"],@"id",
																											 @NO, @"withMinMax", @NO, @"sinceLastCalibration", nil]
																							  completeBlock:^(NSDictionary* retval){
																								  [self.spinner removeSpinner]; self.spinner=nil;
																								  onData([retval objectForKey:@"d"]);
																							  }
																							 errorBlock:^(NSError* err, id* showFrom){
																								 *showFrom = nil;
																								 [self.spinner removeSpinner]; self.spinner=nil;

																								 return YES;
																							 }setMac:_dvc.xSetMac];
																				
																			}andType:nil andDataLoader:loader ] autorelease];

	SingleTagChart* chart =((LandscapeGraphViewController*)vc).chart;
	chart.dewPointMode = (_dvc.tag.hasThermocouple&&!_dvc.tag.shorted) || withLux || (_dvc.tag.has13bit&&dewPointMode);
	chart.capIsChipTemperatureMode=(_dvc.tag.hasThermocouple && !_dvc.tag.shorted);
	chart.hasALS = withLux;
	
	vc.shareHandler = shareHandler;
	vc.logDownloader = ^(GraphViewController* vc1, UIBarButtonItem* sender_vc, NSString* fromDate, NSString* toDate){
		[vc1 showLoadingBarItem:sender_vc];
		[self genericOpenLog:[WSROOT stringByAppendingFormat:@"ethDownloadTempCSV.aspx?id=%d&fromDate=%@&toDate=%@",_dvc.tag.slaveId,
							  fromDate, toDate] fileName:@"TemperatureLog.csv" barButton:sender_vc completion:^(){
			[vc1 revertLoadingBarItem:sender_vc];
		}];
	};
	[_dvc.navigationController pushViewController2:vc ];
	
	

/*	NSString* cookie = [[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	NSRange start = [cookie rangeOfString:@"="];
	NSURL *url;
	if(start.length){
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@eth/tempStats.html?%d&%@", WSROOT, _dvc.tag.slaveId, 				[cookie substringFromIndex:start.location+1]]];
	}else{
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@eth/tempStats.html?%d", WSROOT, _dvc.tag.slaveId]];
	}
	//		[[UIApplication sharedApplication] openURL:url];
	WebViewController* wv = [[[WebViewController alloc]initWithTitle:@"Temperature Statistics"] autorelease];
	[_dvc.navigationController pushViewController:wv animated:YES];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[[wv webView] loadRequest:req];	
*/
}
-(void)lightOnBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/LightOn"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", 
								 [NSNumber numberWithBool:NO], @"flash", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void)lightOffBtnPressed:(id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/LightOff"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];	
}

-(void)redirectToURL:(NSURL*)url title:(NSString*)title{
	WebViewController* wv = [[[WebViewController alloc]initWithTitle:title] autorelease];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[[wv webView] loadRequest:req];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		[_mvc.navigationController pushViewController2:wv ];
	else{
		[_dvc.navigationController pushViewController2:wv ];
		[_associate_popov dismissPopoverAnimated:YES]; 				[self unBlur];
	}
}

-(void) doorStatsBtnPressed:(id)sender{
	// 	.ASPXAUTH=EC385D2C555A010B96D57DDCA79C7B7586C5EF0DD1B3300E260F21C1E04581852C562A9214EDA33D59EF44364EB1498C159DC24D5F560244D8E8B671A0A400C880E59B63D39F69F6AE7A34C6FA38CBC75DD6C3D6287782CAE955CE7CC41F13BC0425132F638B93824B77B9C1F8DE44B4AE7AA2DDB2F361F7AB90D52AF58FC2C20925277FF790396760BDBA5F93B6C9DA8BB314A1D124E0FCF41898AC754661B2C086FFF2; expires=Mon, 27-Feb-2012 01:00:27 GMT; path=/; HttpOnly

	NSString* cookie =  [AsyncSoapURLConnection getCookie]; //[[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	NSRange start = [cookie rangeOfString:@"="];
	NSURL *url;
	if(start.length){
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@eth/stats.html?%d&%@", WSROOT, _dvc.tag.slaveId, 				[cookie substringFromIndex:start.location+1]]];
	}else{
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@eth/stats.html?%d", WSROOT, _dvc.tag.slaveId]];
	}
	//		[[UIApplication sharedApplication] openURL:url];
	WebViewController* wv = [[[WebViewController alloc]initWithTitle:_dvc.doorCellName] autorelease];
	[_dvc.navigationController pushViewController2:wv ];
	
	
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[[wv webView] loadRequest:req];	

	//NSString *js1 = [NSString stringWithFormat:@"$('#stat_title').text('%@');",_dvc.tag.name];
    //[wv.webView stringByEvaluatingJavaScriptFromString:js1];
}

-(void) tagImageDeleted{
	[_mvc updateTag:_dvc.tag loadImage:NO];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DeleteTagImage"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id", nil]
				  completeBlock:nil 
					 errorBlock:nil setMac:_dvc.xSetMac];
}

-(void) tagUpdated{
	[_mvc updateTag:_dvc.tag loadImage:NO];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveTagInfo"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [_dvc.tag forUpload],@"tag", nil]
				  completeBlock:nil 
				  errorBlock:nil setMac:_dvc.xSetMac];
}


-(void) tagImageUpdated:(UIImage *)image{

	NSData *d = UIImageJPEGRepresentation(image, 0.5);	
	[_mvc updateTag:_dvc.tag loadImage:NO];
	NSString* json = [NSString stringWithFormat:@"{\"id\":%d,\"base64Jpeg\":\"%@\",\"base64MD5\":\"%@\"}",
					 _dvc.tag.slaveId,  [d base64EncodedString], _dvc.tag.image_md5];
//	NSLog(json);
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/UploadTagImage"]
						jsonString:json	  completeBlock:nil errorBlock:nil setMac:_dvc.xSetMac];		
}

static int postback_interval_choices_val[]={30,60,120,300,600,1800,3600,14400};
-(int) postback_interval_index{
	int i=0;
	for(;i<sizeof(postback_interval_choices_val)/sizeof(int);i++)
		if(postback_interval_choices_val[i]== _postbackInterval)
			return i;	
	return 0;
}
static int revive_choices_val[]={1,2,3,4,6,12,24};

-(void) doSelectCurrentTagManager:(NSInteger)index{

	self.spinner = [SpinnerView loadSpinnerIntoView:self.window];

	// TODO:  SelectTagManager must return current post back interval. 
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TagManagerChooseAllPrefKey];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/SelectTagManager"]
					 jsonString:[NSString  stringWithFormat:@"{mac: '%@'}", [tagManagerMacList objectAtIndex:index]]
				  completeBlock:^(NSDictionary* retval){
					  
					  _postbackInterval = [[retval objectForKey:@"d"] intValue];

					  currentTagManagerIndex=index;
					  _tvc.title=_mvc.title = [tagManagerNameList objectAtIndex:currentTagManagerIndex];
					
					  [selectedTags release];
					  selectedTags =  [[NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:
																   [@"mss_" stringByAppendingString:[tagManagerNameList objectAtIndex:currentTagManagerIndex]]]] retain]; //[[NSMutableSet alloc] init];

					  [self stopComet];
					  [self reloadTagListWithCompletion:^(){
						  [self getNextUpdate];			// restart getting comet using the new mac (all).
					  }];
					  [_evc reload]; [_tvc reload];
					  
				  }errorBlock:^(NSError* e, id* showFrom){
					  
					  [self.spinner removeSpinner]; self.spinner=nil;
					  return YES;
				  }setMac:nil];	
}
-(void) tagManagerDropdownPressed:(id)sender{
//	if(_isLimited)return;
	
	NSMutableArray* nameList = [[tagManagerNameList mutableCopy] autorelease];
	[nameList addObject:NSLocalizedString(@"All Tag Managers",nil)];
	NSInteger selected=currentTagManagerIndex;
	if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])
		selected = nameList.count-1;
	
	/*
	ActionSheetStringPicker *managerPicker = [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Select Tag Manager",nil) rows:nameList initialSelection:selected doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue){
		
		if(selectedIndex==nameList.count-1)  // all tag managers
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TagManagerChooseAllPrefKey];
			_mvc.title = selectedValue;
			
			self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
			[self stopComet];
			[self reloadTagListWithCompletion:^(){
				[self getNextUpdate];			// restart getting comet using the new mac (all).
			}];
			[_evc reload];
			
		}
		else if(selectedIndex!=currentTagManagerIndex){
			[self doSelectCurrentTagManager:selectedIndex];
		}
		else{
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TagManagerChooseAllPrefKey];

			_mvc.title = [tagManagerNameList objectAtIndex:currentTagManagerIndex];
			[self stopComet];
			[self reloadTagListWithCompletion:^(){
				[self getNextUpdate];			// restart getting comet using the new mac (all).
			}];
			[_evc reload];
		}
	}cancelBlock:nil origin:sender] autorelease];
	[managerPicker showActionSheetPicker];
*/
	
	
	OptionPicker* picker = [[OptionPicker alloc]initWithOptions:nameList
													   Selected:selected Done:^(NSInteger selectedIndex, BOOL nowPicked) {
														   if(selectedIndex==nameList.count-1)  // all tag managers
														   {
															   [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TagManagerChooseAllPrefKey];
															   _tvc.title=_mvc.title = [nameList objectAtIndex:selectedIndex];
															   
															   self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
															   [self stopComet];
															   [self reloadTagListWithCompletion:^(){
																   [self getNextUpdate];			// restart getting comet using the new mac (all).
															   }];
															   [_evc reload]; [_tvc reload];
															   
														   }
														   else if(selectedIndex!=currentTagManagerIndex){
															   [self doSelectCurrentTagManager:selectedIndex];
														   }
														   else{
															   [[NSUserDefaults standardUserDefaults] setBool:NO forKey:TagManagerChooseAllPrefKey];
															   
															   _tvc.title=_mvc.title = [tagManagerNameList objectAtIndex:currentTagManagerIndex];
															   [self stopComet];
															   [self reloadTagListWithCompletion:^(){
																   [self getNextUpdate];			// restart getting comet using the new mac (all).
															   }];
															   [_evc reload]; [_tvc reload];
														   }
													   }];
	
	picker.title=NSLocalizedString(@"Select Tag Manager",nil);
	[self showUpdateOptionPicker:picker From:sender];

}
-(void) reqImmediatePostback: (id)sender{
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/RequestImmediatePostback"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
					  [_dvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:_dvc.tag];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void) thermostatSet:(id)sender{
	if(_dvc.tag.hasThermostat){
		[self thermostatSetTarget:sender thermostatTag:_dvc.tag tempSensor:_dvc.tag.targetRef relinquishOwnership:NO];
	}else{
		[self thermostatSetTarget:sender thermostatTag:_dvc.tag.thermostatRef tempSensor:_dvc.tag relinquishOwnership:NO];
	}
}

-(void) thermostatDisableLocal:(id)sender disable:(BOOL)on{

	NSString* tstatMac;
	NSMutableDictionary* thermostat;
	if(_dvc.tag.hasThermostat){
		thermostat = _dvc.tag;
		tstatMac = _dvc.xSetMac;
	}else{
		thermostat = _dvc.tag.thermostatRef;
		tstatMac = thermostat.mac;
	}

	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetThermostatOption"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:thermostat.slaveId],@"thermostatId",
								 [NSNumber numberWithBool:on],@"disableLocalControl",
								 [NSNumber numberWithFloat: thermostat.thermostat.th_high-thermostat.thermostat.th_low], @"comfortZoneDegC",
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:thermostat];
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:tstatMac];

}

-(void)thermostatFanOnOff:(id)sender fanOn:(BOOL)on{
	
	NSString* tstatMac;
	int tstatId;
	if(_dvc.tag.hasThermostat){
		tstatId = _dvc.tag.slaveId;
		tstatMac = _dvc.xSetMac;
	}else{
		tstatId = _dvc.tag.thermostatRef.slaveId;
		tstatMac = _dvc.tag.thermostatRef.mac;
	}
	
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ThermostatFanOnOff"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tstatId],@"thermostatId",
								 [NSNumber numberWithBool:on],@"turnOn", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:tstatMac];
}

-(void)thermostatTurnOnOff:(id)sender turnOn:(BOOL)on{

	NSString* tstatMac;
	int tstatId;
	if(_dvc.tag.hasThermostat){
		tstatId = _dvc.tag.slaveId;
		tstatMac = _dvc.xSetMac;
	}else{
		tstatId = _dvc.tag.thermostatRef.slaveId;
		tstatMac = _dvc.tag.thermostatRef.mac;
	}

	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ThermostatOnOff"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tstatId],@"thermostatId",
								 [NSNumber numberWithBool:!on],@"turnOff", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:tstatMac];
}
-(void) deleteScriptBtnPressed:(int)index{

	NSMutableDictionary* script = [_dvc.tag.scripts objectAtIndex:index];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/RemoveScript"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [script objectForKey:@"id" ] ,@"id",
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  
					  for(NSMutableDictionary* tag in _mvc.tagList){
						  if(tag!=_dvc.tag)
							  tag.scripts = nil;
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  return YES;
				  }setMac:nil];

}
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
	if(_dvc.navigationController!=nil)
		return _dvc.navigationController;
	else if(_mvc.navigationController!=nil)
		return _mvc.navigationController;
	else if(_dvc!=nil)
		return _dvc;
	else
		return _mvc;
}
- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller{
	if(_dvc!=nil)
		return _dvc.view.frame;
	else
		return _mvc.view.frame;
}
- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller{
	if(_dvc!=nil)
		return _dvc.view;
	else
		return _mvc.view;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    [controller autorelease];
}
-(void) reconfigureScriptBtnPressed:(int)index{
	NSMutableDictionary* script = [_dvc.tag.scripts objectAtIndex:index];
	ScriptConfigViewController* configer = [[ScriptConfigViewController alloc] initWithName:[script objectForKey:@"name"]
																					andLogs: [script objectForKey:@"logs"]
																			andPlaceHolders:[script objectForKey:@"assignments"]
																			   andSchedules:[script objectForKey:@"schedules"]
																				andRegions:[script objectForKey:@"regions"]
											andLiterals:[script objectForKey:@"literals"] andPhones:[script objectForKey:@"phones"]
																				andDelegate:self
																					   Done:^(NSString* name, NSArray* tagAssignments, NSArray* scheduleAssignments, NSArray* regionAssignments, NSArray* literals, NSArray* phones)
											{
												[_dvc.navigationController popToViewController:_dvc animated:YES];
												
												[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/ReconfigureScript3"]
																	jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [script objectForKey:@"id" ] ,@"id",
																			 name, @"name",
																			 tagAssignments, @"assignments",
																			 scheduleAssignments, @"schedules",
																			 regionAssignments, @"regions",
																			 literals, @"literals",
																			 phones, @"phones",
																			 nil]
															  completeBlock:^(NSDictionary* retval){
																  
																  [self loadScriptsInBackground];
																  for(NSMutableDictionary* tag in _mvc.tagList){
																	  if(tag!=_dvc.tag)
																		  tag.scripts = nil;
																  }
															  }errorBlock:^(NSError* err, id* showFrom){
																  return YES;
															  }setMac:nil];
												
											} DonwloadLog:^(TableLoadingButtonCell* btn){
												[btn showLoading];
												
												dispatch_queue_t downloadQueue = dispatch_queue_create("com.MyTagList.logDownloadQueue", NULL);
												NSString* url = [WSROOT stringByAppendingFormat:@"ethDownloadAppLog.aspx?id=%@",
																				   [script objectForKey:@"id"]];
												dispatch_async(downloadQueue, ^{
													NSError* error=nil;
													NSData * data = [AsyncURLConnection syncGetRequest:url error:&error];
													//[NSData dataWithContentsOfURL:url options:0 error:&error];
													
													dispatch_async(dispatch_get_main_queue(), ^{
														[btn revertLoading];
														
														if(error!=nil){
															[AsyncSoapURLConnection standardShowError:error From:btn];
														}else{
															NSString *filePath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/KumoAppLog.csv"];
															NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath ];
															if(handle == nil) {
																[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
																handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
															}
															[handle truncateFileAtOffset:0];
															[handle writeData:data]; [handle closeFile];
															
															UIDocumentInteractionController* docPreview = [UIDocumentInteractionController
																										   interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
															docPreview.UTI = @"public.comma-separated-values-text";
															docPreview.delegate = self;
															//[docPreview presentPreviewAnimated:YES];
															[docPreview presentOptionsMenuFromRect:btn.bounds inView:btn animated:YES];
															[docPreview retain];
														}
													});
												});
												dispatch_release(downloadQueue);

												/*
												[AsyncSoapURLConnection getRequest:]
																	 completeBlock:^(NSData* data){
																		 [btn revertLoading];
																		 NSString *filePath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/KumoAppLog.csv"];
																		 NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath ];
																		 [handle truncateFileAtOffset:0];
																		 [handle writeData:data]; [handle closeFile];
																		 
																		 UIDocumentInteractionController* docPreview = [UIDocumentInteractionController
																										   interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
																		 docPreview.UTI = @"public.comma-separated-values-text";
																		 docPreview.delegate = self;
																		 [docPreview presentPreviewAnimated:YES];
																		 [docPreview retain];

																	 }errorBlock:^(NSError* err, id* showFrom){
																		 [btn revertLoading];
																		 return YES;
																	 }];*/
											}
											];
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/LogForScriptID"]
						jsonObj:@{@"appid": [script objectForKey:@"id"], @"topN": @10}
				  completeBlock:^(NSDictionary* retval){
					  NSArray* times = [(NSDictionary*)[retval objectForKey:@"d"] objectForKey:@"time"];
					  NSArray* msgs =[(NSDictionary*)[retval objectForKey:@"d"] objectForKey:@"msgs"];
					  NSArray* types =[(NSDictionary*)[retval objectForKey:@"d"] objectForKey:@"types"];
					  NSMutableArray* logs = [[[NSMutableArray alloc]initWithCapacity:msgs.count] autorelease];
					  for(int i=0;i<msgs.count;i++){
						  ScriptLogEntry* entry = [[ScriptLogEntry new] autorelease];
						  NSString* time =[times objectAtIndex:i];
						  NSRange openB = [time rangeOfString:@"("]; NSRange closeB = [time rangeOfString:@")"];
						  
						  entry.time = [NSDate dateWithTimeIntervalSince1970:
										[[time substringWithRange:NSMakeRange(openB.location+1,closeB.location-openB.location-1)] longLongValue]/1000.0];
						  entry.msg=[msgs objectAtIndex:i];
						  entry.type = [[types objectAtIndex:i] intValue];
						  [logs addObject:entry];
					  }
					  [configer setLogs:logs];
					  [script setObject:logs forKey:@"logs"];
				  }errorBlock:^(NSError* err, id* showFrom){
					  return YES;
				  }setMac:nil];

	[_dvc.navigationController pushViewController2:configer ];

}
-(void) addScriptBtnPressed:(id)sender{

	SnippetCategoryCollectionViewController* categoryPicker = [[[SnippetCategoryCollectionViewController alloc]initWithDoneBlock:^(NSInteger category, NSString* categoryName, SnippetCategoryCell *cell) {

		[_dvc showLoadingBarItem:cell];
		NSMutableSet* availableTypes = [[[NSMutableSet alloc] init] autorelease];
		for(NSMutableDictionary* tag in _mvc.tagList){
			[availableTypes addObject:[NSNumber numberWithInt:tag.tagType]];
		}
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/GetSnippets3"]
							jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
									 availableTypes.allObjects,@"availableTypes", [NSNumber numberWithBool:NO], @"includeCode",
									 [NSNumber numberWithBool:YES], @"includeStats", [NSNumber numberWithInteger:category],@"category", nil]
					  completeBlock:^(NSDictionary* retval){
						  [_dvc revertLoadingBarItem:cell];
						  
						  NSArray* snippets =[retval objectForKey:@"d"];
						  SnippetListViewController* picker =
						  [[[SnippetListViewController alloc]
							initWithSnippets:snippets
							Done:^(NSDictionary* snippet){
								
								ScriptConfigViewController* configer = [[ScriptConfigViewController alloc] initWithName:[snippet objectForKey:@"description"]
																												andLogs:nil andPlaceHolders:[snippet objectForKey:@"placeHolders"]
																										   andSchedules:[snippet objectForKey:@"schedules"]
																											 andRegions:[snippet objectForKey:@"regions"]
																											andLiterals:[snippet objectForKey:@"literals"] andPhones:[snippet objectForKey:@"phones"]
																											andDelegate:self
																												   Done:^(NSString* name, NSArray* tagAssignments, NSArray* scheduleAssignments, NSArray* regions, NSArray* literals, NSArray* phones)
																		{
																			[_dvc.navigationController popToViewController:_dvc animated:YES];
																			
																			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethSnippets.asmx/InsertScript3"]
																								jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																										 [snippet objectForKey:@"id" ] ,@"snippet_id",
																										 name, @"name",
																										 tagAssignments, @"assignments",
																										 scheduleAssignments, @"schedules",
																										 regions, @"regions",
																										 literals, @"literals",
																										 phones, @"phones",
																										 nil]
																						  completeBlock:^(NSDictionary* retval){
																							  
																							  [self loadScriptsInBackground];
																							  for(NSMutableDictionary* tag in _mvc.tagList){
																								  if(tag!=_dvc.tag)
																									  tag.scripts = nil;
																							  }
																							  
																						  }errorBlock:^(NSError* err, id* showFrom){
																							  *showFrom = sender;
																							  return YES;
																						  }setMac:nil];
																			
																		} DonwloadLog:nil];
								
								[_dvc.navigationController pushViewController2:configer];
								
							}] autorelease];
						  
						  picker.title = categoryName;
						  [_dvc.navigationController pushViewController2:picker ];
						  
					  }errorBlock:^(NSError* err, id* showFrom){
						  *showFrom = cell;
						  [_dvc revertLoadingBarItem:cell];
						  return YES;
					  }setMac:nil];
		
	}] autorelease];
	[_dvc.navigationController pushViewController2:categoryPicker ];
	
}
- (NSMutableDictionary*)findTagFromUuid:(NSString*)uuid{
	return [tagDictionary objectForKey:uuid];
}

-(NSString*)listOnlyUuidOfTagWithTypes:(NSArray *)types{
	NSString* ret=nil;
	
	for(NSMutableDictionary* tag in [tagDictionary allValues]){
		for(NSNumber* type in types){
			if(tag.tagType==[type intValue]){
				if(ret==nil)ret=tag.uuid;
				else return nil;
			}
		}
	}
	return ret;
}
-(NSMutableArray*)listTagsWithTypes:(NSArray*) types excludingUuids:(NSArray*)uuids{
	NSMutableArray* ret2 = [[[NSMutableArray alloc]initWithCapacity:tagDictionary.count] autorelease];
	NSMutableDictionary* ret = [[tagDictionary mutableCopy] autorelease];
	if(uuids!=nil && uuids!=(id)[NSNull null])
		[ret removeObjectsForKeys:uuids];

	for(NSDictionary* tag in [ret allValues]){
		for(NSNumber* type in types){
			if(tag.tagType==[type intValue]){
				[ret2 addObject:tag]; break;
			}
		}
	}
	return ret2;
}


-(void) thermostatChoiceBtnPressed:(id)sender{
	
	NSMutableArray* choices;
	NSInteger selected_index=NSNotFound;
	NSInteger none_index;
	
	if(_dvc.tag.hasThermostat){
		choices =[[[tagDictionary allValues]mutableCopy] autorelease];
		none_index = NSNotFound;	// for thermostat relinquishOwnership will always be NO.
		
		if(_dvc.tag.targetRef!=nil){
			selected_index = [choices indexOfObject:_dvc.tag.targetRef];
		}
		if(selected_index==NSNotFound){
			selected_index = [choices indexOfObject:_dvc.tag];
			_dvc.tag.targetRef = _dvc.tag;
		}

	}else{
		choices =[[[thermostatDictionary allValues] mutableCopy] autorelease];
		[choices addObject:@"None"];
		none_index = choices.count-1;

		if(_dvc.tag.thermostatRef!=nil){
			selected_index = [choices indexOfObject:_dvc.tag.thermostatRef];
		}else
			selected_index = none_index;
	}
	
	OptionPicker *picker = [[OptionPicker alloc]initWithOptions:choices
													   Selected:selected_index Done:^(NSInteger selected, BOOL now){
														   //if(selected == selected_index)return;
														   
														   if(_dvc.tag.hasThermostat){
															   
															   [self thermostatSetTarget:sender thermostatTag:_dvc.tag tempSensor:[choices objectAtIndex:selected] relinquishOwnership:NO];
															   
														   }else{
															   NSDictionary* thermostatTag;
															   if(selected==none_index)
																   thermostatTag = _dvc.tag.thermostatRef;
															   else
																   thermostatTag = [choices objectAtIndex:selected];
															   
															   [self thermostatSetTarget:sender thermostatTag:thermostatTag tempSensor:_dvc.tag relinquishOwnership:
																(selected==none_index)];
														   }
													   } helpText:NSLocalizedString(@"Choose which sensor to use to control this thermostat.",nil)];
	[self showUpdateOptionPicker:picker From:sender];
	[picker release];
}

-(void) tagRssiModeOption: (NSMutableDictionary*)tag BarItem:(id)sender{
	NSArray* choices = [NSArray arrayWithObjects:NSLocalizedString(@"Setup Mode",nil),NSLocalizedString(@"Low Power Mode",nil), nil];
	int selected_index = tag.rssiMode ? 1:0;

	OptionPicker *picker = [[OptionPicker alloc]initWithOptions:choices
													   Selected:selected_index Done:^(NSInteger selected, BOOL now){
														   [_dvc showLoadingBarItem:sender];
														   
														   [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetLowPowerWOR"]
																			   jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																						[NSNumber numberWithInt:tag.slaveId],@"id",
																						[NSNumber numberWithBool:selected?YES:NO], @"enable",nil]
																		 completeBlock:^(NSDictionary* retval){
																			 NSMutableDictionary* tag = [retval objectForKey:@"d"];
																			 [self updateTag:tag];
																			 [_dvc revertLoadingBarItem:sender];
																		 }errorBlock:^(NSError* err, id* showFrom){
																			 *showFrom = [_mvc cellForTag:tag];
																			 [_dvc revertLoadingBarItem:sender];
																			 return YES;
																		 }setMac:_dvc.xSetMac];
														   
													   } helpText:NSLocalizedString(@"Low power mode will improve stand-by mode battery life by typically 3~4 times at the expense of longer delay in tag responding to user command.",nil)];
	[self showUpdateOptionPicker:picker From:sender];
	[picker release];
}
-(void) doSetRXFilter:(int)selected BarItem:(id)sender{
	[_mvc showLoadingBarItem:sender];
	_rxFilter = 64-selected*16;
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetRXFilter"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:_rxFilter],@"filter", nil]
				  completeBlock:^(NSDictionary* retval){
					  //NSLog(@"%d",_freqTols.count);
					  //NSLog(@"%@",[_freqTols objectAtIndex:0]);
					  
					  maxFreqOffset = [[_freqTols objectAtIndex:_rxFilter/16] intValue];
					  [_mvc.tableView reloadData];
					  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
						  if(_dvc.tag!=nil ){
							  [_dvc updateTag:_dvc.tag loadThermostatSlider:YES animated:YES];
						  }
					  }
					  [_mvc revertLoadingBarItem:sender];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_mvc revertLoadingBarItem:sender];
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void) tagManagerModeOption:(id)sender{
	NSArray* choices = [NSArray arrayWithObjects:NSLocalizedString(@"Wideband (most tolerant)",nil),NSLocalizedString(@"Wider band",nil),
						NSLocalizedString(@"Normal",nil),NSLocalizedString(@"Narrower band",nil),
						NSLocalizedString(@"Narrowband (longest range)",nil), nil];
	int selected_index = (64-_rxFilter)/16;
	
	OptionPicker *picker = [[OptionPicker alloc]initWithOptions:choices
													   Selected:selected_index Done:^(NSInteger selected, BOOL now){
														   
														   if([_mvc anyV1Tags] && selected>0){
															   
															   LambdaAlert *alert = [[LambdaAlert alloc] initWithTitle:NSLocalizedString(@"Compatibility Notice",nil)
																											   message:NSLocalizedString(@"There is old (version 1) tag on this Tag Manager, if you choose anything other than Wideband, the Tag Manager may not successfully receive transmission/update from these tags. Go ahead and change?",nil)];
															   [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil) block:^{
																   [self doSetRXFilter:(int)selected BarItem:sender];
															   }];
															   [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil) block:nil];
															   [alert show];
															   [alert release];

														   }else{
															   [self doSetRXFilter:(int)selected BarItem:sender];
														   }
														   
													   } helpText: NSLocalizedString(@"Narrower receiver bandwidth allows tag manager to receive data from tag at further distance. However, frequency calibration for tags will be required more often after the surrounding temperature at a tag changes by a large amount.",nil)];
	[self showUpdateOptionPicker:picker From:sender];
	[picker release];

}
-(void) showUpdateOptionPicker:(OptionPicker*)picker From:(id)sender{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		
		/*if(false){

			_updateOption_popov=nil;
			picker.modalPresentationStyle=UIModalPresentationPopover;
			
			if([sender isKindOfClass:[UITableViewCell class]]){

				picker.popoverPresentationController.sourceView=sender;
				picker.popoverPresentationController.sourceRect=CGRectMake( ((UITableViewCell*)sender).bounds.size.width/2, ((UITableViewCell*)sender).bounds.size.height-8, 0,0);

			}else if([sender isKindOfClass:[UIView class]]){
				UIView* cell = sender;
				picker.popoverPresentationController.sourceView=sender;
				picker.popoverPresentationController.sourceRect=cell.bounds;
			}
			else{
				picker.popoverPresentationController.barButtonItem=sender;
			}
			picker.dismissUI=^(BOOL animated){
				[_mvc.navigationController popViewControllerAnimated:animated];
			};
			[_mvc.navigationController pushViewController2:picker ];

		}else*/{
			if(picker.selectedMulti!=nil){
				UINavigationController* nc = [[[UINavigationController alloc]initWithRootViewController:picker] autorelease];
				if(!_updateOption_popov || isOS8){
					
					self.updateOption_popov = [[[UIPopoverController alloc] initWithContentViewController:nc] autorelease];
					_updateOption_popov.delegate=self;
					
				}else
					_updateOption_popov.contentViewController = nc;
			}else{
				if(!_updateOption_popov || isOS8){
					
					self.updateOption_popov = [[[UIPopoverController alloc] initWithContentViewController:picker] autorelease];
					_updateOption_popov.delegate=self;
				}else
					_updateOption_popov.contentViewController = picker;
			}
			
			//_updateOption_popov.popoverContentSize = picker.contentSizeForViewInPopover; //CGSizeMake(420, 500);
			
			picker.dismissUI=^(BOOL animated){
				[_updateOption_popov dismissPopoverAnimated:animated]; 				[self unBlur];
			};
			
			if(picker.options.count>=3)
				[self blurView:_splitViewController.view];
			
			if([sender isKindOfClass:[UITableViewCell class]]){
				UITableViewCell* cell = sender;
				[_updateOption_popov presentPopoverFromRect:cell.bounds inView:cell.contentView
								   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}else if([sender isKindOfClass:[UIView class]]){
				UIView* cell = sender;
				[_updateOption_popov presentPopoverFromRect:cell.bounds inView:cell
								   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
			else{
				//if(isOS8)_updateOption_popov.popoverContentSize = CGSizeMake(480, 300);
				[_updateOption_popov presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
		}
	}else{
		_updateOption_popov=nil;
		picker.dismissUI=^(BOOL animated){
			[_mvc.navigationController popViewControllerAnimated:animated];
		};
		[_mvc.navigationController pushViewController2:picker ];
	}
}
// TODO: Tag and Tag2 structure must include "postBackInterval" if different from MAC postback interval.
-(void) unifiedUpdateBtnAction:(id)sender applyAll:(BOOL)applyAll{

	NSArray* choices = [NSArray arrayWithObjects:NSLocalizedString(@"Record every 30 seconds",nil),NSLocalizedString(@"Record every 1 minute",nil),
						NSLocalizedString(@"Record every 2 minutes",nil),NSLocalizedString(@"Record every 5 minutes",nil),
						NSLocalizedString(@"Record every 10 minutes",nil) ,NSLocalizedString(@"Record every 30 minutes",nil),
						NSLocalizedString(@"Record every 1 hour",nil),NSLocalizedString(@"Record every 4 hour",nil) , NSLocalizedString(@"If Out Of Range...",nil), NSLocalizedString(@"Notifications...",nil), nil];
	
	int selected_index=[self postback_interval_index];
	if(!applyAll){
		NSNumber *tagPbSec= [_dvc.tag objectForKey:@"postBackInterval"];
		if(tagPbSec){
			int i=0;
			for(;i<sizeof(postback_interval_choices_val)/sizeof(int);i++)
				if(postback_interval_choices_val[i]== [tagPbSec intValue] ){
					selected_index=i;	
					break;
				}
		}
	}
		
	OptionPicker *picker = [[OptionPicker alloc]initWithOptions:choices 
													    Selected:selected_index Now:NSLocalizedString(@"Update Now",nil) nowOptions:@[@8,@9]
														Done:^(NSInteger selected, BOOL now){
															   //[_mvc showLoadingBarItem:sender];
															   if(now){
																   if(applyAll)
																	   [self all_tag_action:@"PingAllTags" withArgs:@"autoRetry: true" btn:sender];	
																   else{
																	   [self reqImmediatePostback:sender];
																   }
																   
															   }else{
																   if(selected < sizeof(postback_interval_choices_val)/sizeof(int)){
																	   if(applyAll)
																		   [self all_tag_action:@"SetPostbackInterval"
																					   withArgs:[NSString stringWithFormat:@"sec: %d, autoRetry: true",
																								 postback_interval_choices_val[selected],nil] btn:sender];
																	   else{
																		   [_dvc showLoadingBarItem:sender];
																		   [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetPostbackIntervalFor"]
																							   jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																										[NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
																										[NSNumber numberWithInt:postback_interval_choices_val[selected]],@"sec", nil]
																						 completeBlock:^(NSDictionary* retval){
																							 NSMutableDictionary* tag = [retval objectForKey:@"d"];
																							 [self updateTag:tag];
																							 [_dvc revertLoadingBarItem:sender];
																						 }errorBlock:^(NSError* err, id* showFrom){
																							 *showFrom = sender;
																							 [_dvc revertLoadingBarItem:sender];
																							 return YES;
																						 }setMac:_dvc.xSetMac];
																		   
																	   }
																   }
																   else if(selected == sizeof(postback_interval_choices_val)/sizeof(int)){
																	   int selected_index2=-1;
																	   if(!applyAll){
																		   NSNumber *reviveEvery= [_dvc.tag objectForKey:@"reviveEvery"];
																		   if(reviveEvery){
																			   int i=0;
																			   for(;i<sizeof(revive_choices_val)/sizeof(int);i++)
																				   if(revive_choices_val[i]== [reviveEvery intValue] ){
																					   selected_index2=i;
																					   break;
																				   }
																		   }
																	   }
																	   OptionPicker* picker2 =[[OptionPicker alloc]initWithOptions:@[NSLocalizedString(@"Search every 5 minutes",nil),
																																	 NSLocalizedString(@"Search every 10 minutes",nil),
																																	 NSLocalizedString(@"Search every 15 minutes",nil),
																																	 NSLocalizedString(@"Search every 20 minutes",nil),
																																	 NSLocalizedString(@"Search every 30 minutes",nil),
																																	 NSLocalizedString(@"Search every hour",nil),NSLocalizedString( @"Search every two hour",nil)]
																														  Selected:selected_index2 Done:^(NSInteger selected, BOOL nowPicked) {
																															  [_dvc showLoadingBarItem:sender];
																															  [AsyncURLConnection request:[WSROOT stringByAppendingString:applyAll?@"ethClient.asmx/SetReviveEveryAll":@"ethClient.asmx/SetReviveEvery"]
																																				  jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
																																						   [NSNumber numberWithInt:_dvc.tag.slaveId],@"id",
																																						   [NSNumber numberWithInt:revive_choices_val[selected]],@"multiple", nil]
																																			completeBlock:^(NSDictionary* retval){
																																				if(!applyAll){
																																					NSMutableDictionary* tag = [retval objectForKey:@"d"];
																																					[self updateTag:tag];
																																				}
																																				[_dvc revertLoadingBarItem:sender];
																																			}errorBlock:^(NSError* err, id* showFrom){
																																				*showFrom = sender;
																																				[_dvc revertLoadingBarItem:sender];
																																				return YES;
																																			}setMac:_dvc.xSetMac];
																														  } helpText:NSLocalizedString(@"Configure the interval tag manager looks for out of range tags. Using a small interval reduces the delay of back-in-range events, but causes other tags to retry more often when sending events/temperature updates (shortens their battery life), since while tag manager is looking for tags, it cannot receive tag updates.",nil)];
																	   [self showUpdateOptionPicker:picker2 From:sender];
																	   [picker2 release];

																   }
																   else{
																	   opv_apply_all=applyAll;
																	   [self open_opv_oor:_dvc.tag BarItem:sender];
																   }
															   }
														} helpText:/*NSLocalizedString(@"Configure auto-update interval to allow tag transmit temperature and other data periodically in order to capture graphs and detect out-of-range/back-in-range events.",nil)*/@"	Configure how often to record temperature and other data for building graphs and out-of-range detection. Tag may send a single data point, 9, 13 or 26 data points (depending on 'transmit multiple data point' option and tag type) in one update (transmission)."];
	[self showUpdateOptionPicker:picker From:sender];
	[picker release];

}
-(void) showMultiStatsForIds:(NSArray*)ids Uuids:(NSArray*)uuids Type:(NSString*)type{
	
	BOOL allTagManager = [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey];
	NSArray* idsOrUuids = allTagManager?uuids: ids;
	
	syncLoadRawData_t loader = ^NSArray*(NSString* start, NSString* end){
		
		NSError* error;
		NSDictionary* ret = [AsyncURLConnection syncRequest:
							 [WSROOT stringByAppendingString:allTagManager ? @"ethLogShared.asmx/GetMultiTagStatsRawByUUIDs": @"ethLogs.asmx/GetMultiTagStatsRaw"]
													jsonObj:@{@"ids": idsOrUuids,
															  @"type": type,
															  @"fromDate":start, @"toDate":end }
													  error:&error setMac:_dvc.xSetMac];
		
		return [[ret objectForKey:@"d"] objectForKey:@"stats"];
	};
	
	shareHandler_t shareHandler = ^(GraphViewController* vc1, UIBarButtonItem* sender_vc, UIImage* snapshot, NSDate* fromDate, NSDate* toDate){
		ShareTextDescription* text = [[[ShareTextDescription alloc]initWithUUID:uuids
																		andName:nil
																		andType:type fromDate:fromDate toDate:toDate] autorelease];
		
		UIActivityViewController *ac=  [[UIActivityViewController alloc] initWithActivityItems:@[snapshot,text]	applicationActivities:nil];
		UIPopoverController* popover=nil;

		ac.excludedActivityTypes=@[UIActivityTypeAssignToContact];
		ac.completionHandler=^(NSString* shareType, BOOL completed){
			if(popover!=nil){
				[popover dismissPopoverAnimated:YES];
				[popover release];
				[self unBlur];
			}
			
			if(completed && ![shareType isEqualToString:UIActivityTypePostToTwitter]){
				
				NSMutableArray* ones = [[[NSMutableArray alloc]initWithCapacity:ids.count] autorelease];
				for(int i=0;i<ids.count;i++)[ones addObject:@YES];
				
				BOOL isMotion = [type isEqualToString:@"motion"];
				[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethLogs.asmx/EditSharePermissions"]
									jsonObj:@{@"ids": ids, @"shareTemperature": isMotion?[NSNull null]:ones,
											  @"shareMotion":isMotion?ones:[NSNull null]}
							  completeBlock:nil errorBlock:^(NSError* err, id* showFrom){return YES;} setMac:_dvc.xSetMac];
			}
		};
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			if(isOS8){
				ac.modalPresentationStyle=UIModalPresentationPopover;
				ac.popoverPresentationController.barButtonItem=sender_vc;
				[vc1 presentViewController:ac animated:YES completion:nil];
			}else{
				[self blurView:_splitViewController.view];
				popover = [[UIPopoverController alloc] initWithContentViewController:ac];
				[popover presentPopoverFromBarButtonItem:sender_vc permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			}
		}else
			[vc1 presentViewController:ac animated:YES completion:nil];
	};
	
	
	GraphViewController* vc = [[[LandscapeGraphViewController alloc] initPrimaryWithTitle:nil
																				 andFrame:_dvc.view.frame
																			andSpanLoader:^(onDataSpan onData){
																				if(self.spinner==nil)
																					self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																				
																				[AsyncURLConnection
																				 request:[WSROOT stringByAppendingString:allTagManager?@"ethLogShared.asmx/GetMultiTagStatsSpanByUUIDs": @"ethLogs.asmx/GetMultiTagStatsSpan"]
																				 jsonObj:@{@"ids": idsOrUuids, @"type":type}
																				 completeBlock:^(NSDictionary* retval){
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 onData([retval objectForKey:@"d"]);
																				 }
																				 errorBlock:^(NSError* err, id* showFrom){
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 *showFrom = nil;
																					 return YES;
																				 }setMac:_dvc.xSetMac];
																				
																			}andHourlyLoader:^(onHourlyData onData){
																				if(self.spinner==nil)
																					self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																				
																				[AsyncURLConnection
																				 request:[WSROOT stringByAppendingString:allTagManager?@"ethLogShared.asmx/GetHourlyStatsByUUIDs": @"ethLogs.asmx/GetHourlyStats"]
																				 jsonObj:@{@"ids": idsOrUuids, @"type":type}
																				 completeBlock:^(NSDictionary* retval){
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 onData([retval objectForKey:@"d"]);
																				 }
																				 errorBlock:^(NSError* err, id* showFrom){
																					 *showFrom = nil;
																					 [self.spinner removeSpinner]; self.spinner=nil;
																					 return YES;
																				 }setMac:_dvc.xSetMac];
																				
																			}andType:type andDataLoader:loader ] autorelease];
	
	vc.shareHandler = shareHandler;
	vc.logDownloader = ^(GraphViewController* vc1, UIBarButtonItem* sender_vc, NSString* fromDate, NSString* toDate){
		[vc1 showLoadingBarItem:sender_vc];
		[self genericOpenLog:[WSROOT
							  stringByAppendingFormat:@"ethDownloadMultiStatsCSV.aspx?ids=%@&type=%@&fromDate=%@&toDate=%@",
							  [ids componentsJoinedByString:@":"],type, fromDate, toDate] fileName:[NSString stringWithFormat:@"Documents/%@_Log.csv",type] barButton:sender_vc completion:^(){
			[vc1 revertLoadingBarItem:sender_vc];
		}];
	};
	
	//[_mvc revertLoadingBarItem:sender];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		[_dvc.navigationController pushViewController2:vc ];
		[_associate_popov dismissPopoverAnimated:YES]; 				[self unBlur];

		// [_associate_popov.contentViewController pushViewController:wv animated:YES];
	}else{
		[_mvc.navigationController pushViewController2:vc ];
	}
	
}
-(void) doMultiStats:(NSString*)type BarItem:(id)sender{

	BOOL onlyCaps = [type isEqualToString:@"cap"];
	BOOL onlyDewPoint =[type isEqualToString:@"dp"];
	BOOL onlyMotions = [type isEqualToString:@"motion"];
	BOOL onlyALS = [type isEqualToString:@"light"];
	
	NSMutableArray* tagNames = [[[NSMutableArray alloc] initWithCapacity:_mvc.tagList.count] autorelease];
	NSMutableDictionary* num2IdMapping = [[[NSMutableDictionary alloc] initWithCapacity:_mvc.tagList.count]autorelease];
	NSMutableDictionary* num2UUIDMapping = [[[NSMutableDictionary alloc] initWithCapacity:_mvc.tagList.count]autorelease];
	int i=0;
	
	for(NSDictionary* tag in _mvc.tagList){
		if(onlyCaps && (tag.cap<=0 || tag.hasThermocouple))continue;
		if(onlyDewPoint && (tag.cap<=0 || tag.tagType==CapSensor || tag.tagType==TCProbe))continue;
		if(onlyMotions && !tag.hasMotion)continue;
		if(onlyALS && !tag.hasALS)continue;
		
		[tagNames addObject:tag.name];
		[num2IdMapping setObject:[NSNumber numberWithInt:tag.slaveId] forKey:[NSNumber numberWithInt:i]];
		[num2UUIDMapping setObject:tag.uuid forKey:[NSNumber numberWithInt:i]];
		i++;
	}
	
	OptionPicker* picker = [[OptionPicker alloc]initWithOptions:tagNames
												  selectedMulti:selectedTags doneMulti:^(NSSet* selected, OptionPicker* sender){
													  
													  [[NSUserDefaults standardUserDefaults] setObject:selectedTags.allObjects forKey:
													   [@"mss_" stringByAppendingString:[tagManagerNameList objectAtIndex:currentTagManagerIndex]]];
													  
													  NSArray* ids =[num2IdMapping objectsForKeys:[selected allObjects] notFoundMarker:[NSNull null]];
													  NSArray* uuids = [num2UUIDMapping objectsForKeys:[selected allObjects] notFoundMarker:[NSNull null]];
													  [self showMultiStatsForIds:ids Uuids:uuids Type:type];
												  }];
	picker.title=NSLocalizedString(@"Choose tags to view",nil);
	[self showPicker:picker fromBarItem:sender];
}

-(void) showPicker:(OptionPicker*)picker fromBarItem:(id)sender{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		UINavigationController* nc = [[[UINavigationController alloc]initWithRootViewController:picker] autorelease];
		if(!_associate_popov || isOS8){
			self.associate_popov=[[[UIPopoverController alloc]initWithContentViewController:nc] autorelease];
			self.associate_popov.delegate=self;
		}else
			_associate_popov.contentViewController = nc;
		
		//_associate_popov.popoverContentSize = picker.contentSizeForViewInPopover;
		
		//if(isOS8)_associate_popov.popoverContentSize = CGSizeMake(480, 600);
		[self blurView:_splitViewController.view];

        picker.dismissUI=^(BOOL animated){
            [ _associate_popov dismissPopoverAnimated:YES];
        };
        [_associate_popov presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
	}else{
		_updateOption_popov=nil;
		picker.dismissUI=^(BOOL animated){
			[_mvc.navigationController popViewControllerAnimated:animated];
		};
		[_mvc.navigationController pushViewController2:picker ];
	}
	[picker release];
}
-(void) multiStatsBtnPressed:(id)sender{

	BOOL hasALS=NO, hasCap=NO, hasMotion=NO, hasDewPoint=NO;
	for(NSMutableDictionary* tag in self.mvc.tagList){
		if(tag.hasALS)hasALS=YES;
		if(tag.hasCap)hasCap=YES;
		if(tag.hasCap && tag.tagType!=CapSensor && tag.tagType!=TCProbe)hasDewPoint=YES;
		if(tag.hasMotion)hasMotion=YES;
	}
	
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	[sheet addButtonWithTitle:NSLocalizedString(@"Temperature",nil) block:^(NSInteger index){
		
		[self doMultiStats:@"temperature" BarItem:sender];
	}];
	if(hasALS)
		[sheet addButtonWithTitle:NSLocalizedString(@"Ambient Light",nil) block:^(NSInteger index){
			[self doMultiStats:@"light" BarItem:sender];
		}];
	
	if(hasCap)
		[sheet addButtonWithTitle:NSLocalizedString(@"Moisture/RH",nil) block:^(NSInteger index){
			[self doMultiStats:@"cap" BarItem:sender];
		}];

	if(hasDewPoint)
		[sheet addButtonWithTitle:NSLocalizedString(@"Dew Point",nil) block:^(NSInteger index){
			[self doMultiStats:@"dp" BarItem:sender];
		}];

	if(hasMotion)
		[sheet addButtonWithTitle:NSLocalizedString(@"Motion Logs",nil) block:^(NSInteger index){
			[self doMultiStats:@"motion" BarItem:sender];
		}];

	[sheet addButtonWithTitle:NSLocalizedString(@"Battery Voltages",nil) block:^(NSInteger index){
		[self doMultiStats:@"batteryVolt" BarItem:sender];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Signal Level",nil) block:^(NSInteger index){
		[self doMultiStats:@"signal" BarItem:sender];
	}];
	
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:_splitViewController.view];
	else [sheet showInView:[self window]];
	[sheet release];
}
-(void) updateAllBtnPressed:(id)sender{

	[self unifiedUpdateBtnAction:sender applyAll:YES];
	
	/*ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	void (^handler)(int index) = ^(int index){
		[_mvc showLoadingBarItem:sender];
		int intervals[]={30,60,120,300,600,1800,3600,7200};
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SetPostbackInterval"]
						 jsonString:[NSString stringWithFormat:@"{sec: %d, autoRetry: true}", intervals[index],nil]
					  completeBlock:^(NSDictionary* retval){
						  [self updatePartialTagList:[retval objectForKey:@"d"]];
						  [_mvc revertLoadingBarItem:sender];
					  }errorBlock:^(NSError* err, id* showFrom){
						  [_mvc revertLoadingBarItem:sender];
						  return YES;
					  }];		
	};
	[sheet addButtonWithTitle:@"Update every 30 seconds" block:handler];
	[sheet addButtonWithTitle:@"Update every 1 minute" block:handler];
	[sheet addButtonWithTitle:@"Update every 2 minutes" block:handler];
	[sheet addButtonWithTitle:@"Update every 5 minutes" block:handler];
	[sheet addButtonWithTitle:@"Update every 10 minutes" block:handler];
	[sheet addButtonWithTitle:@"Update every 30 minutes" block:handler];
	[sheet addButtonWithTitle:@"Update every 1 hour" block:handler];
	[sheet addButtonWithTitle:@"Update every 2 hour" block:handler];

	[sheet addRedButtonWithTitle:@"Update Now" block:^(int index){
		[_mvc showLoadingBarItem:sender];
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/UpdateAll"]
						 jsonString:@"{autoRetry: false}"
					  completeBlock:^(NSDictionary* retval){
						  [self updatePartialTagList:[retval objectForKey:@"d"]];
						  [_mvc revertLoadingBarItem:sender];
					  }errorBlock:^(NSError* err, id* showFrom){
						  [_mvc revertLoadingBarItem:sender];
						  return YES;
					  }];
	}];

	[sheet addCancelButtonWithTitle:@"Cancel"];	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender animated:YES];
	else [sheet showInView:[[_mvc view] window]];
	[sheet release];
	*/
}

-(void) open_opv_lb:(NSDictionary*)tag BarItem:(id)sender
{
	if(!_opv_lb)
		_opv_lb = [[LbOptionsViewController alloc]initWithDelegate:self];
	[opv_apply_all?_mvc:_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethClient.asmx/LoadLowBatteryConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  
					  _opv_lb.title = [NSLocalizedString(@"Low Battery Alerts for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name==nil?@"":tag.name)];
					  _opv_lb.loginEmail = self.loginEmail;
					  [self open_opv:_opv_lb BarItem:sender];
					  _opv_lb.config=config;
					  //[_opv_popov setPopoverContentSize:_opv_lb.contentSizeForViewInPopover animated:YES];
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void) open_opv_kumostat:(NSDictionary*)tag BarItem:(id)sender
{
	if(!_opv_kumostat)
		_opv_kumostat = [[KumostatOptionsViewController alloc]initWithDelegate:self];
	[opv_apply_all?_mvc:_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethClient.asmx/LoadKumostatConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  
					  _opv_kumostat.title = [@"Wiring for " stringByAppendingString:(opv_apply_all?@"All Kumostats" : tag.name)];
					  [self open_opv:_opv_kumostat BarItem:sender];
					  _opv_kumostat.config=config;
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}

-(void) open_opv_ms:(NSDictionary*)tag BarItem:(id)sender
{
	if(!_opv_ms)
		_opv_ms = [[MSOptionsViewController alloc]initWithDelegate:self];
	
	[opv_apply_all?_mvc:_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadMotionSensorConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){

					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];

					  NSMutableDictionary* config = [retval objectForKey:@"d"];


					  TagType type = tag.tagType;
					  _opv_ms.isPir8F =NO;
					  
					  if(tag.has3DCompass){
						  _opv_ms.title = [NSLocalizedString(@"Motion Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
						  _opv_ms.isReedPir=_opv_ms.isPir=NO;
						  _opv_ms.isHmcTimeout = (tag.rev>=0xE) && !(tag.rev==0xF && tag.tagType==MotionSensor);
						  _opv_ms.isAccel = (tag.rev & 0xF)==0xA;
						  _opv_ms.isALS=NO;
					  }
					  else if(type==PIR){
						  _opv_ms.title = [NSLocalizedString(@"Infra-Red Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
						  _opv_ms.isReedPir=_opv_ms.isPir=YES;
						  _opv_ms.isAccel=NO;
						  _opv_ms.isPir8F = tag.rev>=0x8F;
						  _opv_ms.isHmcTimeout =NO;
						  _opv_ms.isALS=NO;
					  }
					  else if(tag.hasALS){
						  _opv_ms.title = [NSLocalizedString(@"Motion Light Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
						  _opv_ms.isReedPir=_opv_ms.isPir=NO;
						  _opv_ms.isHmcTimeout =YES;
						  _opv_ms.isALS=YES;
						  _opv_ms.isAccel=NO;
					  }
					  else{
						  _opv_ms.title = [NSLocalizedString(@"Reed Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
						  _opv_ms.isReedPir=YES;
						  _opv_ms.isPir=NO;
						  _opv_ms.isHmcTimeout =NO;
						  _opv_ms.isALS=NO;
						  _opv_ms.isAccel=NO;
					  }
						  
					  [_opv_ms view];
					  _opv_ms.armDisarmState = opv_apply_all?ArmDisarmSwitchStateHidden:(tag.eventState>Disarmed?ArmDisarmSwitchStateOn:ArmDisarmSwitchStateOff);

					  _opv_ms.loginEmail = self.loginEmail;
					  [self open_opv:_opv_ms BarItem:sender];
					  
					  _opv_ms.config=config;

					  //[_opv_popov setPopoverContentSize:_opv_ms.contentSizeForViewInPopover animated:YES];

				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void) open_opv_oor:(NSDictionary*)tag BarItem:(id)sender
{
	if(!_opv_oor)
		_opv_oor = [[OorOptionsViewController alloc]initWithDelegate:self];
	[opv_apply_all?_mvc:_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadOutOfRangeConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  _opv_oor.title = [NSLocalizedString(@"Out of Range Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
					  _opv_oor.loginEmail = self.loginEmail;
					  [self open_opv:_opv_oor BarItem:sender];
					  _opv_oor.config = config;
					  _opv_oor.oorGrace = tag.oorGrace;
					  
					  //[_opv_popov setPopoverContentSize:_opv_oor.contentSizeForViewInPopover animated:YES];
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void) open_opv_phones:(NSDictionary*)tag BarItem:(id)sender{
	if(!_opv_phone)
		_opv_phone = [[PhoneOptionsViewController alloc]initWithDelegate:self];
	[opv_apply_all?_mvc:_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadMobileNotificationConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  _opv_phone.title = [NSLocalizedString(@"Phone Notification Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
					  [self open_opv:_opv_phone BarItem:sender];
					  _opv_phone.config = config;
					  //[_opv_popov setPopoverContentSize:_opv_phone.contentSizeForViewInPopover animated:YES];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [opv_apply_all?_mvc:_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void)tempCalibrateBtnClickedForTag:(NSMutableDictionary*)tag Temperature:(float)degC  BtnCell:(id)sender ThresholdSlider:(RangeSlider*)thresholdSlider  useDegF:(bool)useDegF
{
	[_opv_temp showLoadingBarItem:sender];
	//float orgTempDegC = tag.temperatureDegC - tag.tempCalOffset;

	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/CalibrateTempSensor"]
						jsonObj:@{@"id":[NSNumber numberWithInt:tag.slaveId], @"degCRaw": [NSNumber numberWithFloat:tag.temperatureDegC - tag.tempCalOffset], @"to":[NSNumber numberWithFloat:degC]}
				  completeBlock:^(NSDictionary* retval){
					  [_opv_temp revertLoadingBarItem:sender];
					  [self updateTag:tag];

					  float minC = useDegF? (thresholdSlider.selectedMinimumValue-32)*5.0/9.0 : thresholdSlider.selectedMinimumValue;
					  float maxC = useDegF? (thresholdSlider.selectedMaximumValue-32)*5.0/9.0 : thresholdSlider.selectedMaximumValue;
					  
					  [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetTemperatureThresholdQuantization"]
										  jsonObj:@{@"id":[NSNumber numberWithInt:tag.slaveId],
													@"sampleC1":[NSNumber numberWithFloat:minC],
													@"sampleC2":[NSNumber numberWithFloat:maxC]}
									completeBlock:^(NSDictionary* retval){
										NSMutableDictionary* q = [retval objectForKey:@"d"];
										if(useDegF) {
											thresholdSlider.maximumValue=q.max*9.0/5.0+32;
											thresholdSlider.minimumValue=q.min*9.0/5.0+32;
											thresholdSlider.stepSize = q.step*9.0/5.0;
											thresholdSlider.selectedMinimumValue=q.sample1*9.0/5.0+32;
											thresholdSlider.selectedMaximumValue=q.sample2*9.0/5.0+32;
										}else{
											thresholdSlider.maximumValue=q.max;
											thresholdSlider.minimumValue=q.min;
											thresholdSlider.stepSize = q.step;
											thresholdSlider.selectedMinimumValue=q.sample1;
											thresholdSlider.selectedMaximumValue=q.sample2;
										}
										[thresholdSlider setNeedsLayout];
									}errorBlock:nil setMac:tag.xSetMac];

				  }
					 errorBlock:^(NSError* err, id* showFrom){
						 *showFrom = sender;
						 [_opv_temp revertLoadingBarItem:sender];
						 return YES;
					 }setMac:tag.xSetMac];
}
-(void)armTempsensorForAllTags{
	[self all_tag_action:@"ArmTempSensorAll" withArgs:@"autoRetry: true" btn:nil];
}
-(void)armTempsensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ArmTempSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];
}
-(void)disarmTempsensorForAllTags{
	[self all_tag_action:@"DisarmTempSensorAll" withArgs:@"autoRetry: true" btn:nil];
}
-(void)disarmTempsensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DisarmTempSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];	
}
-(void)dewPointModeChanged{
	[_mvc.tableView reloadData];
	[[NSUserDefaults standardUserDefaults] setBool:dewPointMode forKey:dewPointModeKey];
//	[_dvc.tableView reloadData];
}
-(void)capCalibrateBtnClickedForTag:(NSMutableDictionary*)tag Cap:(float)RH  BtnCell:(id)sender;
{
	[_opv_cap showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/CalibrateCapSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [tag objectForKey:@"slaveId"],@"id",
								 [tag objectForKey:@"capRaw"],@"capRaw",
								 [NSNumber numberWithFloat:RH], @"to",
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  [_opv_cap revertLoadingBarItem:sender];
					  [self updateTag:[retval objectForKey:@"d"]];
				  }
					 errorBlock:^(NSError* err, id* showFrom){
						 *showFrom = sender;
						 [_opv_cap revertLoadingBarItem:sender];
						 return YES;
					 }setMac:tag.xSetMac];
}
-(void)capResetCalibrateBtnClickedForTag:(NSMutableDictionary*)tag BtnCell:(id)sender;
{
	[_opv_cap showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ResetCapCalibration"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [tag objectForKey:@"slaveId"],@"id",
								 nil]
				  completeBlock:^(NSDictionary* retval){
					  [_opv_cap revertLoadingBarItem:sender];
					  NSMutableDictionary* tag =[retval objectForKey:@"d"];
					  [_opv_cap updateTag:tag];
					  [self updateTag:tag];
				  }
					 errorBlock:^(NSError* err, id* showFrom){
						 *showFrom = sender;
						 [_opv_cap revertLoadingBarItem:sender];
						 return YES;
					 }setMac:tag.xSetMac];
}

-(void)armCapSensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ArmCapSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];
}

-(void)armCapSensorForAllTags{
	[self all_tag_action:@"ArmCapSensorAll" withArgs:@"autoRetry: true" btn:nil];
}
-(void)disarmCapSensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DisarmCapSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];
}
-(void)disarmCapSensorForAllTags{
	[self all_tag_action:@"DisarmCapSensorAll" withArgs:@"autoRetry: true" btn:nil];
}



-(void)armLightSensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ArmLightSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];
}

-(void)armLightSensorForAllTags{
	[self all_tag_action:@"ArmLightSensorAll" withArgs:@"autoRetry: true" btn:nil];
}
-(void)disarmLightSensorForTag:(NSDictionary*)tag{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/DisarmLightSensor"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id",nil]
				  completeBlock:^(NSDictionary* retval){
					  NSMutableDictionary* tag = [retval objectForKey:@"d"];
					  [self updateTag:tag];
				  }errorBlock:nil setMac:tag.xSetMac];
}
-(void)disarmLightSensorForAllTags{
	[self all_tag_action:@"DisarmLightSensorAll" withArgs:@"autoRetry: true" btn:nil];
}


-(void) open_opv_light:(NSMutableDictionary*)tag BarItem:(id)sender
{
	if(!_opv_light)
		_opv_light = [[LightOptionsViewController alloc]initWithDelegate:self];
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethClient.asmx/LoadLightSensorConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  _opv_light.title = [NSLocalizedString(@"Light Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
					  _opv_light.loginEmail = self.loginEmail;
					  [_opv_light setConfig:config andTag:tag];
					  [self open_opv:_opv_light BarItem:sender];
					  //[_opv_popov setPopoverContentSize:_opv_cap.contentSizeForViewInPopover animated:YES];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}


-(void) open_opv_cap:(NSMutableDictionary*)tag BarItem:(id)sender
{
	if(!_opv_cap)
		_opv_cap = [[CapOptionsViewController alloc]initWithDelegate:self];
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadCapSensorConfig2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  _opv_cap.title = [NSLocalizedString(@"Humidity/Moisture Sensor Options for ",nil) stringByAppendingString:(opv_apply_all?@"All Tags" : tag.name)];
					  _opv_cap.loginEmail = self.loginEmail;
					  [_opv_cap setConfig:config andTag:tag];
					  [self open_opv:_opv_cap BarItem:sender];
					  
					  [AsyncURLConnection request:[WSROOT
												   stringByAppendingString:@"ethClient.asmx/LoadRepeatNotifyConfig"]
										  jsonObj:@{@"uuid":tag.uuid, @"sensorType":@2}
									completeBlock:^(NSDictionary* retval){
										for(NSMutableDictionary* rnc in [retval objectForKey:@"d"]){
											int eventType =[[rnc objectForKey:@"eventType"]intValue];
											if( eventType==3)
												_opv_cap.rnc_toodry=rnc;
											else if(eventType==4)
												_opv_cap.rnc_toowet=rnc;
										}
									} errorBlock:^BOOL(NSError *error, id *sender) {
										return NO;
									} setMac:nil];
					  if(_opv_cap.cap2Config!=nil){
						  [AsyncURLConnection request:[WSROOT
													   stringByAppendingString:@"ethClient.asmx/LoadRepeatNotifyConfig"]
											  jsonObj:@{@"uuid":tag.uuid, @"sensorType":@3}
										completeBlock:^(NSDictionary* retval){
											for(NSMutableDictionary* rnc in [retval objectForKey:@"d"]){
												int eventType =[[rnc objectForKey:@"eventType"]intValue];
												if( eventType==1)
													_opv_cap.rnc_cap2=rnc;
											}
										} errorBlock:^BOOL(NSError *error, id *sender) {
											return NO;
										} setMac:nil];
					  }
					  //[_opv_popov setPopoverContentSize:_opv_cap.contentSizeForViewInPopover animated:YES];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void) enableDS18:(id)sender enable:(BOOL)on useSHT20:(BOOL)sht20 {
	[_dvc showLoadingBarItem:sender];
	int slaveId = _dvc.tag.slaveId;
	NSMutableDictionary* tag = _dvc.tag;
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethClient.asmx/DetectExtTempSensor2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:slaveId],@"id", [NSNumber numberWithBool:on], @"detect", [NSNumber numberWithBool:sht20], @"useSHT20",  nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  if(on){
						  NSMutableDictionary* rom = [retval objectForKey:@"d"];
						  NSString* serial;
						  if(rom == nil || rom == (id)[NSNull null])
							  serial = NSLocalizedString(@"Detected external temperature sensor, taking initial readings...",nil);
						  else
							  serial = [NSString stringWithFormat:NSLocalizedString(@"Detected external temperature sensor %02x-%02x-%02x-%02x-%02x-%02x, taking initial readings...",nil), [[rom objectForKey:@"s1"] intValue], [[rom objectForKey:@"s2"] intValue], [[rom objectForKey:@"s3"] intValue],
											  [[rom objectForKey:@"s4"] intValue], [[rom objectForKey:@"s5"] intValue], [[rom objectForKey:@"s6"] intValue],nil];
						  
						  [[[iToast makeText:serial andDetail:@""] setDuration:iToastDurationNormal] showFrom:[_mvc cellForTag:tag]];
					  }
					  else{
						  if(_dvc.tag.hasThermocouple && sht20==NO)
							  [[[iToast makeText:NSLocalizedString(@"Changed to thermocouple, taking temperature readings...",nil) andDetail:@""] setDuration:iToastDurationNormal] showFrom:[_mvc cellForTag:tag]];
						  else
							  [[[iToast makeText:NSLocalizedString(@"Changed to temperature/humidity probe, taking initial readings...",nil) andDetail:@""] setDuration:iToastDurationNormal] showFrom:[_mvc cellForTag:tag]];
					  }
					  [self reqImmediatePostback:sender];
					  if(_dvc.tag.tempEventState != TempDisarmed){
						  [self armTempsensorForTag:_dvc.tag];
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:tag];
					  [_dvc revertLoadingBarItem:sender];
					  [_dvc updateTag:_dvc.tag loadThermostatSlider:YES animated:YES];
					  return YES;
				  } setMac:_dvc.xSetMac];
	
}

-(void) enableKumoApp:(NSMutableDictionary *)script enable:(BOOL)on from:(id)sender{

	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethSnippets.asmx/EnableScript"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [script objectForKey:@"id"],@"id", [NSNumber numberWithBool:on], @"enable", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  script.enabled=on;
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:nil];
	
}
-(void) open_opv_temp:(NSMutableDictionary*)tag BarItem:(id)sender
{
	if(!_opv_temp)
		_opv_temp = [[TempOptionsViewController alloc]initWithDelegate:self];
	[_dvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadTempSensorConfig"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tag.slaveId],@"id", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  _opv_temp.title = [NSLocalizedString(@"Temp Sensor Options for ",nil) stringByAppendingString:(opv_apply_all? @"All Tags" : tag.name)];
					  _opv_temp.loginEmail = self.loginEmail;

					  [self open_opv:_opv_temp BarItem:sender];
					  [_opv_temp setConfig:config andTag:tag];
					  
					  [AsyncURLConnection request:[WSROOT
												   stringByAppendingString:@"ethClient.asmx/LoadRepeatNotifyConfig"]
										  jsonObj:@{@"uuid":tag.uuid, @"sensorType":@1}
									completeBlock:^(NSDictionary* retval){
										
										for(NSMutableDictionary* rnc in [retval objectForKey:@"d"]){
											int eventType =[[rnc objectForKey:@"eventType"]intValue];
											if( eventType==2)
												_opv_temp.rnc_toohot=rnc;
											else if(eventType==3)
												_opv_temp.rnc_toocold =rnc;
										}
									} errorBlock:^BOOL(NSError *error, id *sender) {
										return NO;
									} setMac:nil];
					  
					  //[_opv_popov setPopoverContentSize:_opv_temp.contentSizeForViewInPopover animated:YES];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_dvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:tag.xSetMac];
}
-(void) open_opv_accountFromBarItem:(id)sender
{
	if(!_opv_ac)
		_opv_ac = [[AccountOptionsViewController alloc]initWithDelegate:self];
	[_mvc showLoadingBarItem:sender];
	[AsyncURLConnection request:[WSROOT 
								 stringByAppendingString:@"ethClient.asmx/LoadAccountConfig"]
						jsonString:@""
				  completeBlock:^(NSDictionary* retval){
					  [_mvc revertLoadingBarItem:sender];
					  NSMutableDictionary* config = [retval objectForKey:@"d"];
					  [config removeObjectForKey:@"managers"];	// does not yet support multi manager config.
					  [self open_opv:_opv_ac BarItem:sender];
					  _opv_ac.config=config;
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = sender;
					  [_mvc revertLoadingBarItem:sender];
					  return YES;
				  } setMac:nil];
}


#import "iToast.h"
-(void) wirelessConfigBtnPressed:(id)sender{
	
	if(_mvc.tagList.count==0){
		[[[iToast makeText:NSLocalizedString(@"Please add at least one tag first",nil) andDetail:@""] setDuration:iToastDurationNormal] showFrom:sender];
		return;
	}
	
	NSDictionary* ms=nil, *reed=nil, *pir=nil, *basic=nil;
	for(NSDictionary* tag in _mvc.tagList){
		if(tag.has3DCompass)ms=tag;
		else if(tag.tagType == ReedSensor || tag.tagType==ReedSensor_noHTU)reed=tag;
		else if(tag.tagType==PIR)pir=tag;
		else ms=tag;
	}
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];

	if([_mvc anyV2Tags] && !_isLimited){
		[sheet addButtonWithTitle:NSLocalizedString(@"Tag Manager Mode",nil) block:^(NSInteger index){
			[self tagManagerModeOption:sender];
		}];
	}

	if(ms!=nil)
		[sheet addButtonWithTitle:NSLocalizedString(@"Motion Sensor Options",nil) block:^(NSInteger index){
			opv_apply_all=YES;
			[self open_opv_ms:ms BarItem:sender];
		}];
	if(reed!=nil)
		[sheet addButtonWithTitle:NSLocalizedString(@"Reed Sensor Options",nil) block:^(NSInteger index){
			opv_apply_all=YES;
			[self open_opv_ms:reed BarItem:sender];
		}];
	if(pir!=nil)
		[sheet addButtonWithTitle:NSLocalizedString(@"Infra-Red Sensor Options",nil) block:^(NSInteger index){
			opv_apply_all=YES;
			[self open_opv_ms:pir BarItem:sender];
		}];
		
/*	[sheet addButtonWithTitle:@"Temperature Sensor" block:^(int index){
		opv_apply_all=YES;
		[self open_opv_temp:ms!=nil?ms:basic BarItem:sender];
	}];
*/	[sheet addButtonWithTitle:NSLocalizedString(@"Out of Range Options",nil) block:^(NSInteger index){
		opv_apply_all=YES;
		[self open_opv_oor:ms!=nil?ms:basic BarItem:sender];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Low Battery Alerts",nil) block:^(NSInteger index){
		opv_apply_all=YES;
		[self open_opv_lb:ms!=nil?ms:basic BarItem:sender];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Phone Options",nil) block:^(NSInteger index){
		opv_apply_all=YES;
		[self open_opv_phones:ms!=nil?ms:basic BarItem:sender];
	}];

	[sheet addButtonWithTitle:NSLocalizedString(@"Re-arrange Tag Order",nil) block:^(NSInteger index){
		[_mvc startReordering];
	}];

	[sheet addButtonWithTitle:NSLocalizedString(@"Configure Today Widget",nil) block:^(NSInteger index){
		[self configureWidget:sender];
	}];
	
	[sheet addButtonWithTitle:NSLocalizedString(@"Account Options",nil) block:^(NSInteger index){
		[self open_opv_accountFromBarItem:sender];
	}];
	
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:_splitViewController.view];
	else [sheet showInView:[self window]];
	[sheet release];
}
-(void)configureWidget:(id)sender{

	[AsyncURLConnection request:[WSROOT stringByAppendingString:
								 @"ethClient.asmx/GetWidgetChoices"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 NSMutableArray* list = [retval objectForKey:@"d"];

						 NSMutableArray* tagNames = [[[NSMutableArray alloc]initWithCapacity:list.count] autorelease];
						 NSMutableSet* originallyChosen = [[[NSMutableSet alloc]init] autorelease];
						 for(int i=0;i<list.count;i++){
							 NSDictionary* choice = [list objectAtIndex:i];
							 [tagNames addObject:choice.name];
							 if([[choice objectForKey:@"included"] boolValue])
								 [originallyChosen addObject:[NSNumber numberWithInt:i]];
						 }
						 OptionPicker* picker = [[OptionPicker alloc] initWithOptions:tagNames
																	   selectedMulti:[[originallyChosen mutableCopy]autorelease] doneMulti:^(NSSet* selected, OptionPicker* picker2){
																		   
																		   NSMutableArray* changedList = [[[NSMutableArray alloc]init] autorelease];
																		   NSMutableSet* removedIndexes = [[originallyChosen mutableCopy]autorelease];
																		   [removedIndexes minusSet:selected];
																		   NSMutableSet* addedIndexes = [[selected mutableCopy] autorelease];
																		   [addedIndexes minusSet:originallyChosen];
																		   
																		   for(NSNumber* removedIndex in removedIndexes){
																			   NSMutableDictionary* choice = [list objectAtIndex:[removedIndex intValue]];
																			   [choice setObject:[NSNumber numberWithBool:NO] forKey:@"included"];
																			   [choice removeObjectForKey:@"name"];
																			   [changedList addObject:choice];
																		   }
																		   for(NSNumber* addedIndex in addedIndexes){
																			   NSMutableDictionary* choice = [list objectAtIndex:[addedIndex intValue]];
																			   [choice setObject:[NSNumber numberWithBool:YES] forKey:@"included"];
																			   [choice removeObjectForKey:@"name"];
																			   [changedList addObject:choice];
																		   }
																		   
																		   [AsyncURLConnection request:[WSROOT stringByAppendingString:
																										@"ethClient.asmx/SetWidgetChoices"]
																							   jsonObj:@{@"choices": changedList}
																						 completeBlock:^(id jsonObj) {
																							 picker2.dismissUI(YES);
																							}
																							errorBlock:^BOOL(NSError *error, id *showFrom) {
																								   *showFrom=sender;
																								return YES;
																							  } setMac:nil];

                                                                       } helpText:NSLocalizedString(@"Choose which tags to display on Today area of Notification Center on the lock screen.",nil)];
						 
						 picker.title=NSLocalizedString(@"Which tags to show?",nil);

						 [self showUpdateOptionPicker:picker From:sender];

						 
					 }errorBlock:^(NSError* err, id* showFrom){
						 *showFrom=sender;
						 return YES;
					 } setMac:nil];
	
	
}
-(void)deletedTagWithSlaveId:(int)slaveId{
	
	[_mvc deleteTagWithSlaveId:slaveId];
	
}
-(void)dismissAssociationScreen{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[_mvc.navigationController popToRootViewControllerAnimated:YES];
	}else{
		[_associate_popov dismissPopoverAnimated:YES];
		[self unBlur];
	}
}
-(void)associationDone:(NSMutableDictionary *)newTag{
	[_mvc addNewTag:newTag];
	if(!newTag.isVirtualTag)
		[self pingTag:newTag];
	
	if(newTag.isKumostat){
		[self open_opv_kumostat:newTag BarItem:_mvc.wirelessConfigBtn];
	}
}

#import <ifaddrs.h>
#import <arpa/inet.h>
static char* getWiFiAddress() {

//    NSString *address = @"error";
	char* ret="0.0.0.0";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    ret = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return ret;
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if([elementName compare:@"homeId" options:NSCaseInsensitiveSearch]==NSOrderedSame)
		self.wemoHomeID = _saxTempVal;
	else if([elementName compare:@"smartprivateKey" options:NSCaseInsensitiveSearch]==NSOrderedSame)
		self.wemoPhoneKey = _saxTempVal;
	
	[_saxTempVal release];
	_saxTempVal=nil;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if([string isEqualToString:@"\n"] || [string isEqualToString:@" "])return;
	if(_saxTempVal==nil){
		_saxTempVal=[string mutableCopy];
	}else
		[_saxTempVal appendString:string];
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
	NSString* header = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if(header==nil)return;
	if([header rangeOfString:@"Belkin"].length==0)return;
	
	for(NSString* line in [header componentsSeparatedByString:@"\r\n"]){
		
		if([line rangeOfString:@"LOCATION"].length>0){
			NSArray* kvp = [line componentsSeparatedByString:@" "];
			if(kvp.count<2)continue;
			
			NSURL* url = [NSURL URLWithString:[kvp objectAtIndex:1] ];
			NSString* host =[NSString stringWithFormat:@"%@:%@", url.host, url.port];
			if(![knownWeMo containsObject:host]){
				[knownWeMo addObject:host];
				
				self.showWeMoButton=YES;
				
				[self.wemoTriedForPhoneID setObject:self.wemoPhoneName forKey:self.wemoPhoneID];
				
				iToast *toast = [[iToast makeText:[NSLocalizedString(@"WeMo found at ",nil) stringByAppendingString:host] andDetail:NSLocalizedString(@"Getting details...",nil)] setDuration:2000];
				[toast show];

				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/upnp/control/remoteaccess1", host]];
				//NSLog(url.description);
				
				// it can take 3 minute 30 seconds. so give it 5 minutes here.
				NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:300];
				request.HTTPMethod=@"POST";
				[request setValue:@"text/xml; charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
				[request setValue:@"\"urn:Belkin:service:remoteaccess:1#RemoteAccess\"" forHTTPHeaderField:@"SOAPACTION"];
				
				NSString* body = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body><u:RemoteAccess xmlns:u=\"urn:Belkin:service:remoteaccess:1\"><DeviceId>%@</DeviceId><dst>1</dst><HomeId></HomeId><DeviceName>%@</DeviceName><MacAddr></MacAddr><pluginprivateKey></pluginprivateKey><smartprivateKey></smartprivateKey><smartUniqueId></smartUniqueId><numSmartDev></numSmartDev></u:RemoteAccess></s:Body></s:Envelope>", self.wemoPhoneID, self.wemoPhoneName];
				request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];  //[NSData dataWithBytes:[body UTF8String] length:[body length]];
				[request setValue:[NSString stringWithFormat:@"%d", (int)[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];
				
				[[[AsyncURLConnection alloc] initWithRequest:request
											   completeBlockRaw:^(NSData* retval){
												   
												   
												   NSXMLParser* parser = [[NSXMLParser alloc] initWithData:retval];
												   [parser setDelegate:self];
												   [parser setShouldResolveExternalEntities:NO];
												   [parser parse];
											   
											   } errorBlock:^(NSError* err, id* showFrom){
												   
												   /*iToast *toast2 = [[iToast makeText:[@"Error getting detail for WeMo at " stringByAppendingString:host] andDetail:[err description]] setDuration:iToastDurationLong];
												   [toast2 show];*/

												   self.showWeMoButton=NO;
												   return NO;
											   }] autorelease];
			}
			break;
		}
	}
}
-(void)standardShowError:(NSError*) error Title:(NSString*)title{
	UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:title];
	[alert setMessage:error.localizedDescription];
	[alert addButtonWithTitle:@"Continue"];
	[alert setCancelButtonIndex:0];
	[alert show];
	[alert release];
}
-(void)discoverWeMoWithPhoneID:(NSString*) phoneID andPhoneName:(NSString*)phoneName{
	if([self.wemoTriedForPhoneID objectForKey:phoneID]!=nil)return;
	
	self.wemoPhoneID = phoneID;
	self.wemoPhoneName = phoneName;
	
	if(knownWeMo==nil)
		knownWeMo = [[NSMutableSet alloc]initWithCapacity:16];
	
//	GCDAsyncUdpSocket* sender = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

	[_receiverUdp close];
	[_receiverUdp release];
	_receiverUdp = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	struct sockaddr_in sa;
	sa.sin_port= htons(1901);
	inet_pton(AF_INET, getWiFiAddress(), &sa.sin_addr);
	NSError* error=nil;
	//if([sender bindToAddress:[NSData dataWithBytes:&sa length:sa.sin_len] error:&error] == NO){
	//if([_receiverUdp bindToPort:1901 error:&error]==NO){
	/*	[self standardShowError:error Title:@"Cannot scan WeMo (bind)"];
		return; */
	//}
	[_receiverUdp joinMulticastGroup:@"239.255.255.250" error:&error];
	
	NSString* data = @"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 1\r\nST: urn:Belkin:device:\r\n\r\n";
	[_receiverUdp sendData:[data dataUsingEncoding:NSUTF8StringEncoding] toHost:@"239.255.255.250" port:1900 withTimeout:-1 tag:0];

	if(	[_receiverUdp beginReceiving:&error] == NO){
		//[self standardShowError:error Title:@"Cannot scan WeMo (receive)"];
		return;
	}

//	if(	[_receiverUdp bindToAddress:[NSData dataWithBytes:&sa length:sa.sin_len] error:&error] == NO){

}

-(void) associateTagBtnPressed:(id)sender{
	AssociationBeginViewController* avc = [[[AssociationBeginViewController alloc] initWithDelegate:self] autorelease];
	//avc.delegate=self;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[_mvc.navigationController pushViewController2:avc ];
	}else{
		UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:avc] autorelease];
		
		if(!_associate_popov || isOS8){
			self.associate_popov=[[[UIPopoverController alloc]initWithContentViewController:nav] autorelease];
			self.associate_popov.delegate=self;
		}else
			_associate_popov.contentViewController = nav;
		
		[self blurView:_splitViewController.view];
		_associate_popov.popoverContentSize = CGSizeMake(480, 600);
		//[_associate_popov presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[_associate_popov presentPopoverFromAnything:sender];
	}
}

-(NSString*) managerString: (NSDictionary*) tag{

	if(tag.signaldBm>-110 && !tag.OutOfRange)
		return [NSString stringWithFormat:@"%@: \ue213%@ ago \ue20b%.0fdBm",
									   tag.managerName, [tag UserFriendlyTimeSpanString:YES], tag.signaldBm];
	else
		return [NSString stringWithFormat:@"%@: \ue213%@ ago \ue20bNo signal", 
									   tag.managerName, [tag UserFriendlyTimeSpanString:YES]];

}

-(void)loadScriptsInBackground{
	NSMutableDictionary* tag = _dvc.tag;
	[AsyncURLConnection request:[WSROOT
								 stringByAppendingString:@"ethSnippets.asmx/ListScriptForTag"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:tag.uuid,@"uuid", nil]
				  completeBlock:^(NSDictionary* retval){
					  [_dvc updateScripts: [retval objectForKey:@"d"]];
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = [_mvc cellForTag:tag];
					  return YES;
				  } setMac:_dvc.tag.xSetMac];
}
-(void) loadScriptsInBackgroundIfNeeded{
	if(_dvc.tag!=nil){
		if(_dvc.tag.scripts==nil)
			[self loadScriptsInBackground];
		else{
			for(NSMutableDictionary* script in _dvc.tag.scripts){
				if(script.enabled!=script.running){
					[self loadScriptsInBackground];
					break;
				}
			}
		}
	}
}
-(void) tagPictureRequest:(NSString *)uuid fromCell:(UITableViewCell *)cell{

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		if (!_dvc) {
			self.dvc = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil delegate:self] autorelease];
		}
		[_dvc view];
		[((UINavigationController*)self.window.rootViewController) pushViewController2:_dvc ];
		[_dvc setTag:[self findTagFromUuid:uuid]];
	}else{
		[_dvc setTag:[self findTagFromUuid:uuid]];
		[[_dvc.navigationController topViewController]dismissViewControllerAnimated:NO completion:nil];
		[_dvc.navigationController popToRootViewControllerAnimated:NO];
	}
	[_dvc pictureBtnPressed:cell];
	
//	[self loadScriptsInBackgroundIfNeeded];
}

-(void) tagSelected: (NSString*) uuid fromCell:(UITableViewCell*) cell{

	NSMutableDictionary* tag = [self findTagFromUuid:uuid];
	slaveIdToDisplay  = tag.slaveId;
	//NSString* uuid = tag.uuid;
	
	OptionPicker *picker=nil;
	if(tag.mirrors!=nil && [tag.mirrors count]>0){
		
		picker = [[[OptionPicker alloc] initWithOptionGen:^(){

			NSDictionary* newTag = [_mvc findTagByUuid:uuid];
			NSMutableArray* choices = [NSMutableArray arrayWithObject:[self managerString:newTag]];
			for (NSDictionary* mirror in newTag.mirrors) {
				[choices addObject:[self managerString:mirror]];
			}
			return choices;
			
		} Selected:0
													 Done:^(NSInteger selected, BOOL now){
														 if(selected>0){
															 NSDictionary* newMirror = [[NSDictionary alloc]
																						initWithObjectsAndKeys:tag.managerName,@"managerName",tag.mac,@"mac",
																						[NSNumber numberWithBool:tag.alive], @"alive",
																						[NSNumber numberWithBool:tag.OutOfRange], @"OutOfRange",
																						tag.notificationJS,@"notificationJS",
																						[NSNumber numberWithFloat:tag.signaldBm], @"signaldBm",
																						[NSNumber numberWithLongLong:tag.lastComm], @"lastComm", nil ];
															 
															 NSDictionary* mirror = [tag.mirrors objectAtIndex:selected-1];
															 tag.managerName = mirror.managerName;
															 tag.mac = mirror.mac;
															 tag.alive = mirror.alive;
															 tag.OutOfRange = mirror.OutOfRange;
															 tag.notificationJS = mirror.notificationJS;
															 tag.signaldBm = mirror.signaldBm;
															 tag.lastComm = mirror.lastComm;
															 [tag.mirrors  replaceObjectAtIndex:selected-1 withObject:newMirror];
															 [newMirror release];
														 }
														 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
															 if (!_dvc) {
																 self.dvc = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil delegate:self] autorelease];
															 }
															 [[_mvc navigationController] pushViewController2:_dvc ];
														 }else{
															 [[_dvc.navigationController topViewController]dismissViewControllerAnimated:NO completion:nil];
															 [_dvc.navigationController popToRootViewControllerAnimated:NO];
														 }
														 [_dvc setTag:tag];
														 [self loadScriptsInBackgroundIfNeeded];
													 } ] autorelease];
	}
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if(picker!=nil){
			picker.title = NSLocalizedString(@"Pick a Tag Manager",nil);
			picker.dismissUI=^(BOOL animated){
			};
			[((UINavigationController*)self.window.rootViewController) pushViewController2:picker ];
		}else{
			if (!_dvc) {
				self.dvc = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil delegate:self] autorelease];
			}
			[_dvc view];
			[((UINavigationController*)self.window.rootViewController) pushViewController2:_dvc ];
			[_dvc setTag:tag];
			[self loadScriptsInBackgroundIfNeeded];
		}
    }else{
        if(picker!=nil){
			UIPopoverController* popover = [[UIPopoverController alloc] 
								 initWithContentViewController:picker];
			popover.delegate=self;
			CGSize sz = picker.contentSizeForViewInPopover;
			sz.width = 420;
			[popover setPopoverContentSize:sz animated:YES];
			picker.dismissUI=^(BOOL animated){
				[popover dismissPopoverAnimated:animated]; 				//[self unBlur];
				[popover autorelease];
			};
			
			if(cell==nil)cell=[_mvc tableView:_mvc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

			//[self blurView:_splitViewController.view];
			[popover presentPopoverFromRect:cell.bounds inView:cell.contentView
							 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

		}else{
			[_dvc setTag:tag];
			[[_dvc.navigationController topViewController]dismissViewControllerAnimated:NO completion:nil];
			[_dvc.navigationController popToRootViewControllerAnimated:NO];
			[self loadScriptsInBackgroundIfNeeded];
		}
	}
}
-(void)swapOrderOf:(NSString *)tag1 between:(NSString *)tag_prev and:(NSString*)tag_next{
//	NSLog(@"%@, %@", tag1.name, tag2.name);
	[AsyncURLConnection request:[WSROOT stringByAppendingString:
								 @"ethClient.asmx/ReorderTag2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 tag1,@"uuid1",
								 tag_prev==nil?[NSNull null] : tag_prev,@"uuid_prev",
								 tag_next==nil?[NSNull null]: tag_next,@"uuid_next", nil]
				  completeBlock:^(NSDictionary* retval){
				  }errorBlock:^(NSError* err, id* showFrom){
					  return YES;
				  }setMac:nil];
}
-(void)reloadTagListWithCompletion:(void (^)())completion{
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:
								 [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]?
								 @"ethClient.asmx/GetTagList2":@"ethClient.asmx/GetTagList"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 NSMutableArray* list = [retval objectForKey:@"d"];
						 
						 [self updateTagList:list];
						 
						 [self.spinner removeSpinner]; self.spinner=nil;
						 
						 if(completion!=nil)completion();
						 
					 }errorBlock:^(NSError* err, id* showFrom){

						 [self.spinner removeSpinner]; self.spinner=nil;
						 return YES;
					 } setMac:nil];
}
-(void)updateTag:(NSMutableDictionary*)tag{
	[self updateTag:tag loadThermostatSlider:YES];
}
-(void)updateTag:(NSMutableDictionary*)tag loadThermostatSlider:(BOOL)loadThermSlider{

	if(_dvc.xSetMac!=nil){
		tag.mac = _dvc.xSetMac;
		tag.managerName = _dvc.tag.managerName;
	}
	
	[_mvc updateTag:tag loadImage:YES];

	[self refreshThermostatLink:_mvc.tagList];

//	if(_dvc.tag!=nil && ([_dvc.tag.uuid isEqualToString: tag.uuid] || [_dvc.tag.uuid isEqualToString:tag.thermostat.targetUuid])){
	if([_dvc.tag.uuid isEqualToString:tag.uuid]){
		[_dvc updateTag:tag loadThermostatSlider:loadThermSlider animated:YES];
	}
	[self enqueueNotificationJSForTag:tag];
}
-(void)reloadTagBySlaveId:(int)slaveid{
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetTagForSlaveId"]
					 jsonString:[NSString stringWithFormat:@"{\"slaveid\":%d}", slaveid]
				  completeBlock:^(NSDictionary* retval){
					  
					  [self updateTag:[retval objectForKey:@"d"]];
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  return YES;
				  }setMac:_dvc.xSetMac];
}
-(void)stopComet{
	should_run_comet=NO;
	if(comets!=nil){
		for(AsyncSoapURLConnection* conn in comets)[conn cancel];
	}
	[comets release]; comets=nil;
}
-(void)getNextUpdate{
	should_run_comet=YES;
	if(comets!=nil)return;
	comets=[[NSMutableArray alloc]initWithCapacity:2];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]) {
		for(NSNumber* dbid in _dbidDictonary.allKeys){
			[comets addObject:[self getNextUpdateForDBID:dbid.intValue]];
		}
	}else{
		[comets addObject:[self getNextUpdateForDBID:0]];
	}
}
-(AsyncSoapURLConnection*)getNextUpdateForDBID:(int)dbid{
	
	NSString* url, *soapAction, *xml;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]) {
		url=@"ethComet.asmx?op=GetNextUpdateForAllManagersOnDB";
		soapAction = @"http://mytaglist.com/ethComet/GetNextUpdateForAllManagersOnDB" ;
		xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetNextUpdateForAllManagersOnDB xmlns=\"http://mytaglist.com/ethComet\"><dbid>%d</dbid></GetNextUpdateForAllManagersOnDB></soap:Body></soap:Envelope>", dbid];
	}else{
		url=@"ethComet.asmx?op=GetNextUpdate";
		soapAction = @"http://mytaglist.com/ethComet/GetNextUpdate" ;
		xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetNextUpdate xmlns=\"http://mytaglist.com/ethComet\" /></soap:Body></soap:Envelope>";
	}
	
	AsyncSoapURLConnection* __weak __block weakSelf = [[AsyncSoapURLConnection soapRequest: [WSROOT stringByAppendingString: url]
														  soapAction: soapAction
																	 xml: xml
						completeBlock:^(id retval){							
							for(NSMutableDictionary* tag in (NSArray*)retval){
								[self updateTag:tag];
							}
							if(should_run_comet && comets!=nil)		// not aborted
							{
								NSUInteger index = [comets indexOfObject:weakSelf];
								if(index!=NSNotFound)
									[comets replaceObjectAtIndex:index withObject:[self getNextUpdateForDBID:dbid]];
							}
						}errorBlock:^(NSError* e, id* showFrom){
							[comets release]; comets=nil;
							if(should_run_comet)
								[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
									[self getNextUpdate];
								} repeats:NO];
							return NO;
						}] retain];
	return weakSelf;
}
-(void)refreshTagManagerDropDown{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/GetTagManagers3"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 NSMutableArray* list = [[retval objectForKey:@"d"] objectForKey:@"managers"];
						 
						 if([[[retval objectForKey:@"d"] objectForKey:@"links"] length]>1)self.showDropcam=YES;
						 else self.showDropcam=NO;
						 
						 [tagManagerNameList release];
						 [tagManagerMacList release];
						 if(list.count>0){
							 tagManagerNameList = [[NSMutableArray alloc]initWithCapacity:[list count]];
							 tagManagerMacList = [[NSMutableArray alloc]initWithCapacity:[list count]];
							 for(int i=0;i<list.count;i++){
								 NSDictionary* entry = [list objectAtIndex:i];
								 [tagManagerMacList addObject:entry.mac];
								 [tagManagerNameList addObject: [entry.name stringByAppendingString:entry.online?@"":NSLocalizedString(@" (Offline)",nil)]];
								 if([[entry objectForKey:@"selected"] boolValue])currentTagManagerIndex=i;
							 }
							 if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])
								 _tvc.title=_mvc.title =  NSLocalizedString(@"All Tag Managers",nil);
							 else{
								 _tvc.title=_mvc.title = [tagManagerNameList objectAtIndex:currentTagManagerIndex];
								 
								 if(list.count>1 && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedTutorialTm0"] ){
									 
									 if(tutorialViewTm==nil){
										 tutorialViewTm = [[UIView alloc]initWithFrame:self.window.bounds];
										 UIImageView* iv = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial_tm.png"]] autorelease];
										 iv.frame=CGRectMake(_mvc.view.frame.size.width/2-iv.frame.size.width/2, [UIApplication sharedApplication].statusBarFrame.size.height*1.8f,
															 iv.frame.size.width, iv.frame.size.height);
										 tutorialViewTm.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
										 [tutorialViewTm addSubview:iv];
										 [tutorialViewTm addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialViewTmTapped)] autorelease]];
										 
									 }
									 [self.window addSubview:tutorialViewTm];
								 }

							 }
						 }else{
							 tagManagerNameList = [[NSMutableArray alloc] initWithObjects:self.loginEmail, nil];
							 currentTagManagerIndex=0;
						 }
						 
						 [_mvc.topPVC restorePreviousPage];

						 [selectedTags release];
						 selectedTags =  [[NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:
																	  [@"mss_" stringByAppendingString:[tagManagerNameList objectAtIndex:currentTagManagerIndex]]]] retain]; //[[NSMutableSet alloc] init];

					 }
					 errorBlock:nil setMac:nil];
}

NSString * const NotificationCategoryMotion  = @"MOTION";
NSString * const NotificationCategoryTemp  = @"TEMP";
NSString * const NotificationCategoryCap  = @"CAP";
NSString * const NotificationCategoryLight  = @"LIGHT";
NSString * const NotificationActionPause = @"PAUSE";
NSString * const NotificationActionDisarm = @"DISARM";

-(void)justLoggedInShowRemoteNotification:(NSDictionary*) userInfo {

	//userInfo=@{@"startRegionId":@"f7003c05-ebe9-45d5-bb1b-4624aabaf109"};
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:
								 [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]?
								 @"ethClient.asmx/GetTagList2":@"ethClient.asmx/GetTagList"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 NSMutableArray* list = [retval objectForKey:@"d"];

						 
						 [self.spinner removeSpinner]; self.spinner=nil;
						 
						 if(updateTimer==nil)
							 updateTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0 block:^()
											 {
												 if([_mvc isViewLoaded] && ![_mvc.tableView isEditing]){
													 [[_mvc tableView] reloadData];
												 }
												 if([_dvc isViewLoaded]){
													 [_dvc updateAgo];
												 }
											 } repeats:YES] retain];
						 
						 slaveIdToDisplay =0;
						 if (userInfo!=nil){
/*							 [toast show];
							 
							 for(NSMutableDictionary* tag in list){
								 if(tag.slaveId==toast.slaveid && [tag.mac isEqualToString:toast.mac]){ 
									 slaveIdToDisplay = toast.slaveid;
									 [self tagSelected:tag fromCell:[_mvc cellForTag:tag]];
									 //_dvc.tag=tag;
									 //[self loadScriptsInBackgroundIfNeeded];
									 break;
								 }
							 }*/
							 [self application:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo];  // this may set slaveIdToDisplay
						 }
						 [_launchOptions release]; _launchOptions=nil;

						[self updateTagList:list]; // this will load slaveIdToDisplay
						 //[_mvc setTagList:list];
						 
						 
						 [self getNextUpdate];
						 
						 
						 //[_evc reload]; [_tvc reload];

					 }errorBlock:^(NSError* err, id* showFrom){
						 [self.spinner removeSpinner]; self.spinner=nil;
						 return YES;
					 } setMac:nil];

	/*[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetPostbackInterval"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 _postbackInterval = [[retval objectForKey:@"d"] intValue];
					 }errorBlock:nil setMac:nil];
	*/
	if( serverTime2LocalTime==0.0){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/GetServerTime2"]
						 jsonString:[NSString stringWithFormat:@"{tzo:%d}", (int)-[[NSTimeZone localTimeZone] secondsFromGMT]/60 ,nil]
					  completeBlock:^(NSDictionary* retval){
						  NSDate* serverNow = 
						  [NSDate dateWithTimeIntervalSince1970:((
																  [[retval objectForKey:@"d"] longLongValue] / 10000000) - 11644473600)];
						  
						  NSDate* now = [[NSDate alloc] init];
						  serverTime2LocalTime = [serverNow timeIntervalSinceDate:now];
						  [now release];
						  
					  }errorBlock:nil setMac:nil];
		
	}
	
	if (isOS8){
		UIMutableUserNotificationAction *pause = [[[UIMutableUserNotificationAction alloc] init] autorelease];
		[pause setActivationMode:UIUserNotificationActivationModeBackground];
		[pause setTitle:NSLocalizedString(@"Pause",nil)];
		[pause setIdentifier:NotificationActionPause];
		[pause setDestructive:NO];
		[pause setAuthenticationRequired:NO];
		
		UIMutableUserNotificationAction *disarm = [[[UIMutableUserNotificationAction alloc] init] autorelease];
		[disarm setActivationMode:UIUserNotificationActivationModeBackground];
		[disarm setTitle:NSLocalizedString(@"Disarm",nil)];
		[disarm setIdentifier:NotificationActionDisarm];
		[disarm setDestructive:YES];
		[disarm setAuthenticationRequired:YES];

		UIMutableUserNotificationAction *disable = [[[UIMutableUserNotificationAction alloc] init] autorelease];
		[disable setActivationMode:UIUserNotificationActivationModeBackground];
		[disable setTitle:NSLocalizedString(@"Stop Monitoring",nil)];
		[disable setIdentifier:NotificationActionDisarm];
		[disable setDestructive:NO];
		[disable setAuthenticationRequired:YES];
		
		UIMutableUserNotificationCategory *motionCategory = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
		[motionCategory setIdentifier:NotificationCategoryMotion];
		[motionCategory setActions:@[pause, disarm]
						forContext:UIUserNotificationActionContextDefault];
		[motionCategory setActions:@[pause, disarm]
						forContext:UIUserNotificationActionContextMinimal];
		
		
		UIMutableUserNotificationCategory *tempCategory = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
		[tempCategory setIdentifier:NotificationCategoryTemp];
		[tempCategory setActions:@[pause, disable]
					  forContext:UIUserNotificationActionContextDefault];
		[tempCategory setActions:@[pause, disable]
					  forContext:UIUserNotificationActionContextMinimal];
		
		UIMutableUserNotificationCategory *capCategory = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
		[capCategory setIdentifier:NotificationCategoryCap];
		[capCategory setActions:@[pause, disable]
						forContext:UIUserNotificationActionContextDefault];
		[capCategory setActions:@[pause, disable]
						forContext:UIUserNotificationActionContextMinimal];

		UIMutableUserNotificationCategory *lightCategory = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
		[lightCategory setIdentifier:NotificationCategoryLight];
		[lightCategory setActions:@[pause, disable]
						forContext:UIUserNotificationActionContextDefault];
		[lightCategory setActions:@[pause, disable]
						forContext:UIUserNotificationActionContextMinimal];

		
		[[UIApplication sharedApplication] registerUserNotificationSettings:
		 [UIUserNotificationSettings settingsForTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound categories:
		  [NSSet setWithObjects:motionCategory,tempCategory,capCategory, lightCategory, nil]
		  ]];
	}else
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		 UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];

}
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
	NSString* category = [[userInfo objectForKey:@"aps"] objectForKey:@"category"];
	if([identifier isEqualToString:NotificationActionPause]){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/PauseNotificationFor"]
						 jsonObj:@{@"category":category, @"mac":[userInfo objectForKey:@"mac"], @"slaveid":[userInfo objectForKey:@"slaveid"]} completeBlock:^(NSDictionary* data){
							
							 if(completionHandler)completionHandler();
							 
						 }errorBlock:^(NSError* e, id* showFrom){
							 
							 if(completionHandler)completionHandler();
							  return NO;		// do not proceed with displaying the error.
						 } setMac:nil];
	}else if([identifier isEqualToString:NotificationActionDisarm]){
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/DisarmNotificationFor"]
						 jsonObj:@{@"category":category, @"mac":[userInfo objectForKey:@"mac"], @"slaveid":[userInfo objectForKey:@"slaveid"]} completeBlock:^(NSDictionary* data){
							 
							 if(completionHandler)completionHandler();
							 
						 }errorBlock:^(NSError* e, id* showFrom){
							 
							 if(completionHandler)completionHandler();
							 return NO;		// do not proceed with displaying the error.
						 } setMac:nil];
	}
}
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
	[application registerForRemoteNotifications];
}
/*-(void)testToast{
	iToast *toast = [[iToast makeText:@"aaaaaaa" andDetail:@""] setDuration:iToastDurationLong];
	[toast show];
}*/
-(void)justLoggedIn{
	
	//[self testToast];
	
	logged_in=YES;
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

	
//	"{"type":"apns","phoneName":"cao’s iPhone","uuid":"da18e615eb1a31fa1b38725d1e0b4ad38629a453","newToken":"DA6519F997DFD1C4D4FFE4C1230B40E650DEFEFE7687691A991639456878E618","oldToken":""}"

	[self refreshTagManagerDropDown];

	/*_launchOptions= [@{	UIApplicationLaunchOptionsRemoteNotificationKey:
  @{ @"aps":   @{
											  @"alert" :@"Temperature at Tag \"Tag 231 rev7f\" returned to normal",
											  @"badge": @4,
											  @"sound" :@"Logjam.aiff"
											  },
									  @"detail" : @"Currentu    y         yyyyyyyyyyyy yyyyyyyyy yyyyyyyyy yyyyyy yyyyyyyyyyy yyyyyyyyyy big text big t",
									  @"mac" : @"843F0E511496",
									  @"slaveid" :@231
	 }} retain];*/

	[self justLoggedInShowRemoteNotification:[_launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
}

- (void)loginController:(LoginController*)controller  
	   doLoginWithEmail:(NSString*)email Password:(NSString*)password{

	self.loginEmail = email;
	self.loginConn = [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/SignInEx"]
					 jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:email,@"email",password,@"password", nil]
					completeBlock:^(NSDictionary* retval){
						[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
						NSDictionary* serverOpt = (NSDictionary*)[retval objectForKey:@"d"];
						[self justLoggedIn];
						[self updateServerOpt:serverOpt];
					}errorBlock:^(NSError* err, id* showFrom){
						[controller notifyLoginFailed];
						return NO;
					} setMac:nil];
	
}
-(void)registerViewDone:(RegisterViewController *)regvc withNewWsRoot:(NSString *)wsRoot{
	[WSROOT release]; WSROOT = [wsRoot retain];
	[[NSUserDefaults standardUserDefaults] setValue:wsRoot forKey:WsRootPrefKey];
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:TagListRememberLoginPrefKey];
	[[NSUserDefaults standardUserDefaults] setValue:regvc.emailCell.textField.text forKey:TagListLoginEmailPrefKey];
	[[NSUserDefaults standardUserDefaults] setValue:regvc.pwd1Cell.textField.text forKey:TagListLoginPwdPrefKey];
	[regvc.navigationController popViewControllerAnimated:YES];
	[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];

	self.loginEmail = regvc.emailCell.textField.text;
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/SignInEx"]
										 jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:self.loginEmail,@"email",regvc.pwd1Cell.textField.text,@"password", nil]
								   completeBlock:^(NSDictionary* retval){
									   NSDictionary* serverOpt = (NSDictionary*)[retval objectForKey:@"d"];
									   [self justLoggedIn];
									   [self updateServerOpt:serverOpt];
								   }errorBlock:^(NSError* err, id* showFrom){
									   return NO;
								   } setMac:nil];

}
-(void)registerViewDone:(RegisterViewController*)regvc{
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:TagListRememberLoginPrefKey];
	[[NSUserDefaults standardUserDefaults] setValue:regvc.emailCell.textField.text forKey:TagListLoginEmailPrefKey];
	[[NSUserDefaults standardUserDefaults] setValue:regvc.pwd1Cell.textField.text forKey:TagListLoginPwdPrefKey];
	[regvc.navigationController popViewControllerAnimated:YES];
	[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
	[self justLoggedIn];
}
-(void)loginControllerRegisterRequest:(LoginController *)controller{
	RegisterViewController* regvc = [[[RegisterViewController alloc] initWithDelegate:self] autorelease];
	[controller.navigationController pushViewController2:regvc ];
}
- (void)loginControllerDidCancel:(LoginController *)controller{
	if(_loginConn){
		[_loginConn cancel];
		self.loginConn=nil;
	}else{
		[controller clearUserInputs];
	}

}

- (NSString*)stringWithDeviceToken:(NSData*)deviceToken {
	const char* data = [deviceToken bytes];
	NSMutableString* token = [NSMutableString string];
	
	for (int i = 0; i < [deviceToken length]; i++) {
		[token appendFormat:@"%02.2hhX", data[i]];
	}
	
	return token; //[[token copy] autorelease];
}

- (NSString *)createNewUUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)string autorelease];
}

-(NSString*)getDeviceUUID{
	NSString *uuid = [SSKeychain passwordForService:@"your app identifier" account:@"user"];
	if (uuid == nil) { // if this is the first time app lunching , create key for device
        uuid  = [self createNewUUID];
		// save newly created key to Keychain
	}
	[SSKeychain setAccessibilityType:kSecAttrAccessibleAlways];
	[SSKeychain setPassword:uuid forService:@"your app identifier" account:@"user"];
	return uuid;
}

-(void)processRequestedRegions{
	if(self.pendingRegionList==nil)return;
	
	for(CLRegion* region in self.locationManager.monitoredRegions){
		if([self.pendingRegionList objectForKey:region.identifier]==nil){
			
			[self.locationManager stopMonitoringForRegion:region];
		}
	}
	for(CLRegion* region in [self.pendingRegionList allValues]){
		[self.locationManager startMonitoringForRegion:region];
	}
	self.pendingRegionList=nil;
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
/*	for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
	{
		NSLog(@"name: '%@'\n",   [cookie name]);
		NSLog(@"value: '%@'\n",  [cookie value]);
		NSLog(@"domain: '%@'\n", [cookie domain]);
		NSLog(@"path: '%@'\n",   [cookie path]);
	}
*/
	self.push_token =[self stringWithDeviceToken:deviceToken];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/UpdateToken2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 self.push_token,@"newToken",
								 @"apns",@"type",
								 [[[[UIDevice currentDevice]name] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString]  ,@"phoneNameBase64", [self getDeviceUUID],@"uuid",nil]
				  completeBlock:^(NSDictionary* data){
					  NSLog(@"UpdateToken successful");
					  
					  self.pendingRegionList= [[[NSMutableDictionary alloc]init]autorelease];
					  for(NSMutableDictionary* reg in (NSArray*)[data objectForKey:@"d"]){
						  NSString* region_id =[reg objectForKey:@"id"];
						  [self.pendingRegionList setObject:[reg circularRegion] forKey:region_id];
						  [self.regionDictionary setObject:reg forKey:region_id];
						  [[NSUserDefaults standardUserDefaults] setObject:[reg objectForKey:@"title"] forKey:region_id];
					  }
					  
					  if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined && self.pendingRegionList.count>0){

						  if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
							  [self.locationManager requestAlwaysAuthorization];
						  }

					  }
					  else if([CLLocationManager authorizationStatus]>=kCLAuthorizationStatusAuthorized)
					  {
						  [self processRequestedRegions];
					  }
					  
				  }errorBlock:^(NSError* err, id* showFrom){
					  NSLog(@"UpdateToken error: %@", err);
					  return YES;
				  }setMac:nil ];
}

/*- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler{

	if(![CLLocationManager regionMonitoringAvailable]){
		completionHandler(UIBackgroundFetchResultNoData);
		return;
	}
	
	self.fetchCompletionHandler=completionHandler;
	num_pending_regions=0; num_regions_updated=0;
	for(CLRegion* region in self.locationManager.monitoredRegions){
		[self.locationManager requestStateForRegion:region];
		num_pending_regions++;
	}
}*/
-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
	[self updatePosition:region state:state];

/*	[self.geocoder reverseGeocodeLocation:[[[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude] autorelease]
						completionHandler:^(NSArray* placemarks, NSError* error){
							if (placemarks && placemarks.count > 0) {
								CLPlacemark *topResult = [placemarks objectAtIndex:0];
								
								//[[NSUserDefaults standardUserDefaults] setObject:topResult.name forKey:region.identifier];

								if(CLRegionStateUnknown!=state)
									[[iToast makeText:
									  [NSString stringWithFormat:@"%@ location around %@; notified KumoApp", state==CLRegionStateInside?@"Entered":@"Left", topResult.name]] show];
								else
									[[iToast makeText:
									  [NSString stringWithFormat:@"Unable to determine if current location is near %@ or not. KumoApp not run.", topResult.name]] show];
								
							}else{
								if(CLRegionStateUnknown!=state)
									[[iToast makeText:[NSString stringWithFormat:@"%@ unnamed location; notified KumoApp",state==CLRegionStateInside?@"Entered":@"Left"]] show];
							}
						}
	 ];
*/
}
-(void)showLocalNotification:(NSString*)body withSound:(NSString*)sound{
	if([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive){

		[[[iToast makeText:body]setDuration:iToastDurationLong]show];

	}else{
		UILocalNotification *reminder1 = [[[UILocalNotification alloc] init] autorelease];
		[reminder1 setFireDate:[NSDate date]];
		[reminder1 setTimeZone:[NSTimeZone localTimeZone]];
		[reminder1 setHasAction:YES];
		[reminder1 setAlertAction:@"Show"];
		[reminder1 setSoundName:sound];
		[reminder1 setAlertBody:body];
		[[UIApplication sharedApplication] scheduleLocalNotification:reminder1];
	}
}
-(void)updatePosition:(CLRegion*)region state:(CLRegionState)regionState{

	
	NSDictionary* startRegion = [self.regionDictionary objectForKey:region.identifier];
	NSString* regionTitle = nil;
	if([startRegion isKindOfClass:[NSMutableDictionary class]])regionTitle = [startRegion objectForKey:@"title"];
	
	if(regionTitle==nil)regionTitle=	[[NSUserDefaults standardUserDefaults] stringForKey:region.identifier];
	
	if(regionState==CLRegionStateUnknown){
		[self showLocalNotification:[NSString stringWithFormat:NSLocalizedString(@"Unable to determine if current location is near %@ or not. KumoApp not triggered.",nil), regionTitle]
						  withSound:@"Uh oh"];
		return;
	}
	
	BOOL isEntry=(regionState==CLRegionStateInside);
	
	[self showLocalNotification:(regionTitle!=nil?
	 [NSString stringWithFormat:NSLocalizedString(@"%@ the region around %@, attempting to trigger KumoApp...",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",@"Leave"), regionTitle]:
	 [NSString stringWithFormat:NSLocalizedString(@"%@ a region, attempting to trigger KumoApp...",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",@"Leave")]) withSound:isEntry?@"Metal_Latch":@"Door_Close"];

	__block BOOL completed=NO;
	
	__block UIBackgroundTaskIdentifier taskid = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"updatePosition" expirationHandler:^{
		taskid=UIBackgroundTaskInvalid;
		if(!completed){
			[self showLocalNotification:regionTitle!=nil?
			 [NSString stringWithFormat:NSLocalizedString(@"%@ the region around %@, but KumoApp could not be triggered because of slow Internet connection. Will automatically retry.",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",@"Leave"), regionTitle]:
			 [NSString stringWithFormat:NSLocalizedString(@"%@ a region, but KumoApp could not be triggered because of slow Internet connection. Will automatically retry",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",nil)]
							  withSound:@"Uh oh"];
		}
	}];
	
	/*
	NSURLSessionConfiguration* config =  [NSURLSessionConfiguration defaultSessionConfiguration]; //[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"KumoAppUpdateRegion"];
	//config.sessionSendsLaunchEvents=YES;
	config.discretionary=NO;
	config.allowsCellularAccess=YES;
	NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
	
	__block NSError* jsonError=nil;
	NSString* jsonS = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:
																							   region.identifier,@"regionID",
																							   [NSNumber numberWithBool:isEntry],@"isEntry",
																							   [self getDeviceUUID],@"device_uuid",nil]  options:0 error:&jsonError]  encoding:NSUTF8StringEncoding] autorelease];
	
	NSURL *url = [NSURL URLWithString:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/UpdateRegion"]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
	request.HTTPMethod=@"POST";
	[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSString* cookie = [AsyncURLConnection getCookie];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];
	NSData* body = [NSData dataWithBytes:[jsonS UTF8String] length:[jsonS length]];
	[request setValue:[NSString stringWithFormat:@"%d", (int)[body length]] forHTTPHeaderField:@"Content-Length"];

	[[session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
		NSString* json_msg=nil;
		
		int lastStatusCode = (int)[(NSHTTPURLResponse*)response statusCode];
		NSString *json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
		if(lastStatusCode>=400){
			if(jsonError!=nil)json_msg = [jsonError.userInfo objectForKey:@"Message"];
			if(json_msg==nil) json_msg=[NSString stringWithFormat:@"Network connection issues: HTTP code %d ", lastStatusCode];
		}
		if(error!=nil){
			json_msg = [json_msg stringByAppendingString:error.localizedDescription];
		}
		
		completed=YES;
		
		UILocalNotification *reminder = [[[UILocalNotification alloc] init] autorelease];
		[reminder setFireDate:[NSDate date]];
		[reminder setTimeZone:[NSTimeZone localTimeZone]];
		[reminder setHasAction:YES];
		[reminder setAlertAction:@"Show"];
		if(json_msg){
			[reminder setSoundName:@"Uh oh"];
			[reminder setAlertBody:
			 regionTitle!=nil?
			 [NSString stringWithFormat:@"%@ the region around %@, but KumoApp cannot be triggered because: %@", isEntry?@"Entered":@"Left", regionTitle, json_msg]:
			 [NSString stringWithFormat:@"%@ a region, but KumoApp cannot be triggered because: %@", isEntry?@"Entered":@"Left", json_msg]];
			
		}else{
			[reminder setSoundName:isEntry?@"Metal_Latch":@"Door_Close"];
			[reminder setAlertBody:
			 regionTitle!=nil?
			 [NSString stringWithFormat:@"%@ the region around %@, KumoApp has been triggered.", isEntry?@"Entered":@"Left", regionTitle]:
			 [NSString stringWithFormat:@"%@ a region, KumoApp has been triggered.", isEntry?@"Entered":@"Left"]];
		}
		[[UIApplication sharedApplication] scheduleLocalNotification:reminder];
		
		[[UIApplication sharedApplication] endBackgroundTask:taskid];
	 
	}] resume]; */
	
	
	NSError* error=nil;
	[AsyncURLConnection syncRequest:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/UpdateRegion"]
							jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
									 region.identifier,@"regionID",
									 [NSNumber numberWithBool:isEntry],@"isEntry",
									 [self getDeviceUUID],@"device_uuid",nil] error:&error setMac:nil];

	completed=YES;
	if(error==nil){
		[self showLocalNotification:			 regionTitle!=nil?
		 [NSString stringWithFormat:NSLocalizedString(@"%@ the region around %@, KumoApp has been triggered.",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",nil), regionTitle]:
		 [NSString stringWithFormat:NSLocalizedString(@"%@ a region, KumoApp has been triggered.",nil), isEntry?NSLocalizedString(@"Entered",nil):NSLocalizedString(@"Left",nil)] withSound:isEntry?@"Metal_Latch":@"Door_Close"];
	}
	[[UIApplication sharedApplication] endBackgroundTask:taskid];
	
}
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if(status>=kCLAuthorizationStatusAuthorized){
		[self processRequestedRegions];
	}
}
#if DOUBLE_REGION_NOTIFY
- (void)locationManager:(CLLocationManager *)manager
		 didEnterRegion:(CLRegion *)region{

	[self locationManager];
	[self updatePosition:region state:CLRegionStateInside];
/*	[self.geocoder reverseGeocodeLocation:[[[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude] autorelease]
						completionHandler:^(NSArray* placemarks, NSError* error){
							if (placemarks && placemarks.count > 0) {
								CLPlacemark *topResult = [placemarks objectAtIndex:0];
								[[iToast makeText:
								  [NSString stringWithFormat:@"Entered location around %@; notified KumoApps", topResult.name]] show];
							}else{
								[[iToast makeText:@"Entered unnamed location; notified KumoApps"] show];
							}
						}
	 ];
*/}

- (void)locationManager:(CLLocationManager *)manager
		  didExitRegion:(CLRegion *)region{

	[self locationManager];
	[self updatePosition:region state:CLRegionStateOutside];
/*	[self.geocoder reverseGeocodeLocation:[[[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude] autorelease]
						completionHandler:^(NSArray* placemarks, NSError* error){
							if (placemarks && placemarks.count > 0) {
								CLPlacemark *topResult = [placemarks objectAtIndex:0];
								[[iToast makeText:
								  [NSString stringWithFormat:@"Left location around %@; notified KumoApps", topResult.name]] show];
							}else{
								[[iToast makeText:@"Left unnamed location; notified KumoApps"] show];
							}
						}
	 ];
*/
}
#endif

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region
			  withError:(NSError *)error{

	NSLog(@"monitoringDidFailForRegion %@ %@",
		  region, error.localizedDescription);
    for (CLRegion *monitoredRegion in manager.monitoredRegions) {
        NSLog(@"monitoredRegion: %@", monitoredRegion);
    }

	if(error.domain == kCLErrorDomain && error.code == 4){
		UIAlertView *alert = [[UIAlertView alloc] init];
		[alert setTitle:NSLocalizedString(@"Please disable and re-enable 'Background App Refresh' from the 'Settings' app.",nil)];
		[alert setMessage:NSLocalizedString(@"Please go to home screen, open the 'Settings' app and then 'General' then 'Background app refresh' and disable and re-enable the toggle switch next to this 'WirelessTag' app. For iOS 8, please completely quit the app and re-launch it. (kCLErrorDomain error 4)",nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
		[alert setCancelButtonIndex:0];
		[alert show];
		[alert release];
		
	}
	else
    if ((error.domain != kCLErrorDomain || error.code != 5) &&
        [manager.monitoredRegions containsObject:region]) {
	
		NSDictionary* startRegion = [self.regionDictionary objectForKey:region.identifier];
		
		UIAlertView *alert = [[UIAlertView alloc] init];
		if(startRegion)
			[alert setTitle:NSLocalizedString(@"Error starting to monitor location",nil)];
		else
			[alert setTitle:[NSString stringWithFormat:NSLocalizedString(@"Error starting monitoring the region around %@",nil),
							 [startRegion objectForKey:@"title"]]];
		
		[alert setMessage:error.localizedDescription];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
		[alert setCancelButtonIndex:0];
		[alert show];
		[alert release];
	}
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {

	NSDictionary* startRegion = [self.regionDictionary objectForKey:region.identifier];
	if(startRegion)
		[[iToast makeText:[NSString stringWithFormat:NSLocalizedString(@"Successfully started monitoring the region around %@",nil),
						   [startRegion objectForKey:@"title"]
					   ]] show];

	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7)
		[manager performSelector:@selector(requestStateForRegion:) withObject:region afterDelay:1];
//		[manager requestStateForRegion:region];
	
/*	[self.geocoder reverseGeocodeLocation:[[[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude] autorelease]
				   completionHandler:^(NSArray* placemarks, NSError* error){
					   if (placemarks && placemarks.count > 0) {
						   CLPlacemark *topResult = [placemarks objectAtIndex:0];
						   [[iToast makeText:
							 [NSString stringWithFormat:@"Started monitoring for location around %@", topResult.name]] show];
					   }else{
						   [[iToast makeText:@"Started monitoring an unnamed location"] show];
					   }
				   }
	 ];
*/
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	NSLog(@"didReceiveRemoteNotification: %@", userInfo);

	NSString* alert = nil;
	
	NSString* startRegionId = [userInfo objectForKey:@"startRegionId"];
	if(startRegionId!=nil){

		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/GetRegionDetail"]
							jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
									 startRegionId,@"id",nil]
					  completeBlock:^(NSDictionary* data){
						  NSMutableDictionary* startRegion = [data objectForKey:@"d"];
						  [[iToast makeText:[NSString stringWithFormat:NSLocalizedString(@"Starting monitoring a region around %@",nil), [startRegion objectForKey:@"title"]
											 ]] show];
						  [self.locationManager startMonitoringForRegion:startRegion.circularRegion ];
						  [self.regionDictionary setObject:startRegion forKey:[startRegion objectForKey:@"id"]];
					  }errorBlock:^(NSError* err, id* showFrom){
						  return YES;
					  }setMac:nil ];

		return;
	}
	NSString* stopRegionId =[userInfo objectForKey:@"stopRegionId"];
	if(stopRegionId!=nil){

		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethMobileNotifications.asmx/GetRegionDetail"]
							jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
									 stopRegionId,@"id",nil]
					  completeBlock:^(NSDictionary* data){
						  NSMutableDictionary* stopRegion = [data objectForKey:@"d"];
						  
						  [[iToast makeText:[NSString stringWithFormat:NSLocalizedString(@"Stopped monitoring a region around %@",nil), [stopRegion objectForKey:@"title"]
											 ]] show];

						  [self.locationManager stopMonitoringForRegion:stopRegion.circularRegion ];
						  [self.regionDictionary removeObjectForKey:[stopRegion objectForKey:@"id"]];
					  }errorBlock:^(NSError* err, id* showFrom){
						  return YES;
					  }setMac:nil ];
		return;
	}

	if(alert!=nil){
		[[iToast makeText:alert] show];
	}
	else{
		NSString* detail = [userInfo objectForKey:@"detail"];
		alert=[[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
		NSString* mac = [userInfo objectForKey:@"mac"];
		if(mac==nil){

			[[iToast makeText:alert andDetail:detail] show];

		}else{
			int slaveid =  [[userInfo objectForKey:@"slaveid"] intValue];
			int index=-1;
			if(slaveid==255){
				[self.notificationJS_queue enqueue:	[[[NSDictionary alloc]
												  initWithObjectsAndKeys:[NSString stringWithFormat:@"play_tagname(%@)", [userInfo objectForKey:@"suffix"]], @"notificationJS",
												  mac,@"mac",
												  [NSNumber numberWithInteger:255],@"slaveId",
												  [userInfo objectForKey:@"prefix"], @"uuid", nil] autorelease]];
			}else{
				for(int i=0;i<[tagManagerMacList count];i++){
					if([[tagManagerMacList objectAtIndex:i] isEqualToString:mac]){
						if(i == currentTagManagerIndex)
						{
							if(_launchOptions!=nil){
								// this is initial launch, gettaglist just been called
								slaveIdToDisplay=slaveid;
								self.uuid_pending_focus=[NSString stringWithFormat:@"@%d",slaveid];
							}else{
								[self reloadTagBySlaveId:slaveid];
								[_evc reload];
								[self focusOnTagUUID:[NSString stringWithFormat:@"@%d",slaveid]];
							}
						}
						else{
							alert = [alert stringByAppendingString:NSLocalizedString(@" (Tap to view...)",nil)];
							index=i;
						}
						break;
					}
				}
			}
			iToast* toast = [iToast makeText:alert andDetail:detail] ;
			if(index<[tagManagerMacList count]){
				[toast setOpenAction:^(){
					slaveIdToDisplay = slaveid;
					self.uuid_pending_focus=[NSString stringWithFormat:@"@%d",slaveid];
					[self doSelectCurrentTagManager:index];
				}];
				[toast setDuration:iToastDurationLong];
			}
			
			[toast show];
		}
	}
	if(comets==nil){
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		[self getNextUpdate];
	}
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
//    NSLog(@"APNS register failed: %@", error);
	UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:NSLocalizedString(@"Failed to register for Push Notification",nil)];
	[alert setMessage:error.localizedDescription];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
	[alert setCancelButtonIndex:0];
	[alert show];
	[alert release];
	
//	self.push_token=@"5421109C-1B93-491B-B094-4F139F9367DC";
}

- (void) reachabilityChanged: (NSNotification* )note
{
	if([hostReach currentReachabilityStatus]==NotReachable){
		
	}else{
		if(logged_in && !comets){
			if(_mvc.tagList.count==0){
				[self reloadFromNetwork];
			}else{
				[self getNextUpdate];
			}
			[_tvc reload];
		}
	}
}

/*void exceptionHandler(NSException* e){
	NSLog(@"CRASH: %@", e);
	NSLog(@"Stack: %@", [e callStackSymbols]);
}*/

-(void)updateServerOpt:(NSDictionary*)serverOpt{
	if(![[serverOpt objectForKey:@"noWemoSearch"] boolValue]){
		[self discoverWeMoWithPhoneID:[serverOpt objectForKey:@"phoneID"]
					 andPhoneName:[@"WirelessTagAccount_" stringByAppendingString:[serverOpt objectForKey:@"loginEmail"]]];
	}
	
	optimizeForV2Tag = [[serverOpt objectForKey:@"optimizeForV2Tag"] boolValue];
	chosen_temp_unit= [[serverOpt objectForKey:@"temp_unit"] intValue];
	_dvc.thermostatCell.useDegF = self.useDegF = temp_unit = (chosen_temp_unit!=0);
	
	[[[[NSUserDefaults alloc]initWithSuiteName:TagListGroupName]autorelease]setValue:[NSNumber numberWithBool:_useDegF]	forKey:UseDegFPrefKey];
	
	
	_postbackInterval = [[serverOpt objectForKey:@"postbackInterval"] intValue];
	_rxFilter = [[serverOpt objectForKey:@"rxFilter"] intValue];
	self.freqTols = [serverOpt objectForKey:@"freqTols"];
	maxFreqOffset = [[_freqTols objectAtIndex:_rxFilter/16] intValue];
	
	NSDate* serverNow =
	[NSDate dateWithTimeIntervalSince1970:((
											[[serverOpt objectForKey:@"serverTime"] longLongValue] / 10000000) - 11644473600)];
	serverTime2LocalTime = [serverNow timeIntervalSinceDate:[[[NSDate alloc] init] autorelease]];
	
	NSString* wsroot = [serverOpt objectForKey:@"wsRoot"];
	if(wsroot!=nil && wsroot.length>1 && ![wsroot isEqualToString:WSROOT]){
#ifndef DEBUG_WS
		[WSROOT release];
		WSROOT = [wsroot retain];
		[[NSUserDefaults standardUserDefaults] setValue:wsroot forKey:WsRootPrefKey];
		[self reloadFromNetwork];
#endif
	}
	
	_isLimited= [[serverOpt objectForKey:@"limited"] boolValue];
	/*if(_isLimited){
		_mvc.title = self.loginEmail;
	}*/
}

//#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
	if([keyPath isEqual:@"app_language"])
	{
		NSString* language =[[NSUserDefaults standardUserDefaults] stringForKey:@"app_language"];
		[[NSUserDefaults standardUserDefaults]setObject:@[language] forKey:@"AppleLanguages"];
		[NSBundle setLanguage:language];
		[self reloadRootViewController];
	}
	else	if([keyPath isEqual:@"scan_wemo"])
	{
		[AsyncURLConnection request:[WSROOT stringByAppendingString:
									 @"WeMoLink.asmx/SetAutoSearchWeMo"]
							jsonObj:@{@"enable":[[NSUserDefaults standardUserDefaults] objectForKey:@"scan_wemo"]}
					  completeBlock:^(NSDictionary* data){
					  }errorBlock:^(NSError* err, id* showFrom){
						  return YES;
					  }setMac:nil ];
	}
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	
#ifdef DEBUG_WS
	if(WSROOT==nil)WSROOT=@"https://my.wirelesstag.net/";
#else
	WSROOT= [[NSUserDefaults standardUserDefaults] stringForKey:WsRootPrefKey];
	if(WSROOT==nil)WSROOT=@"https://www.mytaglist.com/";
#endif
	[SSKeychain setAccessibilityType:kSecAttrAccessibleAlways];

	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"app_language" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"scan_wemo" options:NSKeyValueObservingOptionNew context:nil];

	dewPointMode=[[NSUserDefaults standardUserDefaults] boolForKey:dewPointModeKey];
	self.wemoPhoneKey = @"";
	self.wemoPhoneID = @"";
	self.wemoHomeID = @"";
	isOS8 = ([[UIDevice currentDevice].systemVersion floatValue] >= 8);
	self.wemoTriedForPhoneID = [[[NSMutableDictionary alloc]init] autorelease];
	
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
				
		UIColor* tint =
		//[UIColor colorWithRed:69.0/255.0 green:162.0/255.0 blue:1.0 alpha:1.0];
		//30a7fc
		[UIColor colorWithRed:(float)0x30/255.0 green:(float)0xa7/255.0 blue:(float)0xfc/255.0 alpha:1.0];
		//[UIColor colorWithRed:69.0/255.0 green:208.0/255.0 blue:1.0 alpha:1.0]; //[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
		
		[UISwitch appearance].onTintColor = tint;
		[UINavigationBar appearance].tintColor = tint;
		[UIToolbar appearance].tintColor = tint;
		[UIActionSheet appearance].tintColor = tint;
		[UISlider appearance].tintColor = tint;
		//[UITextField appearance].textColor = tint;
		[[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:tint];
	}
	//[UIPageControl appearance].backgroundColor = [UIColor redColor];
	
	/*	UIColor* tint =[UIColor colorWithRed:210.0/255.0 green:0.95 blue:210.0/255.0 alpha:1];
	UIColor* tint2 =[UIColor colorWithRed:0.95 green:1 blue:0.95 alpha:1];
	UIColor* gray =[UIColor colorWithRed:0.4 green:0.5 blue:0.4 alpha:1];
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
		[UINavigationBar appearance].barTintColor = tint;
		[UINavigationBar appearance].TintColor = gray;
		[UIActionSheet appearance].backgroundColor = tint2;
//		[UITableView appearance].backgroundColor = tint2;
		[UIToolbar appearance].barTintColor = tint;
		[UIToolbar appearance].tintColor = gray;
		[[UINavigationBar appearance] setShadowImage:[[[UIImage alloc] init] autorelease]];
		//nav.navigationBar.translucent = NO;
	}
*/
	alreadyLaunched=NO;
//	NSSetUncaughtExceptionHandler(&exceptionHandler);
	InstallUncaughtExceptionHandler();

	//[self locationManager];
	
	
	serverTime2LocalTime=0.0;
	selectedTags = [[NSMutableSet alloc] init];

	logged_in=NO; updateTimer=nil; comets=nil;
	_launchOptions = [launchOptions retain];

	if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
		//	if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsLocationKey"]){
		NSLog(@"UIApplicationLaunchOptionsLocationKey - fired");
		[self locationManager];
		return YES;
	}

	
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
		
	_evc = [[EventsViewController alloc]initWithLoader:^(EventsViewController* ui, int64_t olderThan, int topN){

		[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString:
									 [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]?
									 @"ethLogs.asmx/GetGeneralEvents2":@"ethLogs.asmx/GetGeneralEvents"]
							jsonObj:@{@"topN": [NSNumber numberWithInt:topN], @"olderThan": [NSNumber numberWithLongLong:olderThan]}
					  completeBlock:^(NSDictionary* data){
						  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
						  [ui appendEvents:[data objectForKey:@"d"]];
						  _tvc.uuid2events = _evc.uuid2events;
						  
					  }errorBlock:^(NSError* err, id* showFrom){
						  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
						  return YES;
					  }setMac:nil ];
		
		
	} andNewLoader:^(EventsViewController* ui, int64_t newerThan){

		[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString:
									 [[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey]?
									 @"ethLogs.asmx/GetNewGeneralEvents2":@"ethLogs.asmx/GetNewGeneralEvents"]
							jsonObj:@{ @"newerThan": [NSNumber numberWithLongLong:newerThan]}
					  completeBlock:^(NSDictionary* data){
						  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
						  [ui prependEvents:[data objectForKey:@"d"]];
						  _tvc.uuid2events = _evc.uuid2events;

					  }errorBlock:^(NSError* err, id* showFrom){
						  [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
						  return YES;
					  }setMac:nil ];

	}];
	[self reloadRootViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
	hostReach = [[Reachability reachabilityWithHostName:@"www.mytaglist.com"] retain];
	[hostReach startNotifier];
	[hostReach currentReachabilityStatus];
	//[hostReach connectionRequired];

	[self.window makeKeyAndVisible];
	self.spinner = [SpinnerView loadSpinnerIntoView:self.window];	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/IsSignedInEx"]
					 jsonString:nil completeBlock:^(NSDictionary* data){
						 NSDictionary* serverOpt = (NSDictionary*)[data objectForKey:@"d"];
						 self.loginEmail = [[NSUserDefaults standardUserDefaults] stringForKey:TagListLoginEmailPrefKey];
						 [self justLoggedIn];
						 [self updateServerOpt:serverOpt];
						 alreadyLaunched=YES;

					 }errorBlock:^(NSError* e, id* showFrom){
						 [self.spinner removeSpinner]; self.spinner=nil;
						 alreadyLaunched=YES;

						 if(e.userInfo!=nil){
							 NSString* message = (NSString*)[e.userInfo objectForKey:@"Message"];
							 if([message rangeOfString:@"unauthorized" options:NSCaseInsensitiveSearch].length>0 || [message rangeOfString:@"authentication" options:NSCaseInsensitiveSearch].length>0){
								 [self showLogin];
								 return NO;		// do not proceed with displaying the error.
							 }
						 }
						 return YES;
					 } setMac:nil];

	
/*	if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")){
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		[center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
			if( error ){
				[self standardShowError:error Title:@"Please open Settings app to allow this app to generate notifications."];
			}
		}];
	}
 */
	return YES;
}
-(void)reloadRootViewController{
	NSLog(@"reloadRootViewController");
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		_mvc = [[MasterViewController alloc] initWithNibName:@"MasterViewController_iPhone" bundle:nil delegate:self];
		_tvc =[[TrendTableViewController alloc] initWithNibName:@"SearchTableView_iPhone" bundle:nil delegate:self];
		TopPagingViewController* pvc = [[[TopPagingViewController alloc] initWithMvc:_mvc andEvc:_evc andTvc:_tvc] autorelease];
		UINavigationController *main_nc = [[[UINavigationController alloc] initWithRootViewController:pvc] autorelease];
		main_nc.navigationBar.translucent = NO;
		main_nc.toolbar.translucent=NO;
		//main_nc.navigationBar.tintColor = [UIColor whiteColor];
		main_nc.toolbarHidden=NO;
		self.window.rootViewController = main_nc;
	}
	else {
		_mvc = [[MasterViewController alloc] initWithNibName:@"MasterViewController_iPad" bundle:nil delegate:self];
		_tvc =[[TrendTableViewController alloc] initWithNibName:@"SearchTableView_iPhone" bundle:nil delegate:self];
		
		TopPagingViewController* pvc = [[[TopPagingViewController alloc] initWithMvc:_mvc andEvc:_evc andTvc:_tvc] autorelease];
		UINavigationController *left_nc = [[[UINavigationController alloc] initWithRootViewController:pvc] autorelease];
		left_nc.navigationBar.translucent = NO;
		left_nc.toolbar.translucent=NO;
		//left_nc.navigationBar.tintColor = [UIColor whiteColor];
		left_nc.toolbarHidden=NO;
		
		self.dvc = [[[DetailViewController alloc] initWithNibName:@"DetailViewController_iPad" bundle:nil delegate:self] autorelease];
		UINavigationController *right_nc = [[[UINavigationController alloc] initWithRootViewController:_dvc] autorelease];
		//right_nc.navigationBar.tintColor = [UIColor whiteColor];
		
		self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
		_splitViewController.presentsWithGesture = NO;
		if (isOS8){
			_splitViewController.preferredPrimaryColumnWidthFraction = 0.4;
			_splitViewController.maximumPrimaryColumnWidth = MIN( _splitViewController.view.bounds.size.width, _splitViewController.view.bounds.size.height);
			_splitViewController.minimumPrimaryColumnWidth = 180;
		}
		
		_splitViewController.delegate = _dvc;
		_splitViewController.viewControllers = [NSArray arrayWithObjects:left_nc, right_nc, nil];
		
		self.window.rootViewController = self.splitViewController;
	}

}
- (void)applicationWillResignActive:(UIApplication *)application
{
	[self stopComet];
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}
-(void)tagManagerAdded
{
	[self reloadFromNetwork];
}
-(void)reloadFromNetwork{
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/IsSignedInEx"]
					 jsonString:nil completeBlock:^(NSDictionary* data){
						 NSDictionary* serverOpt = (NSDictionary*)[data objectForKey:@"d"];
						 [self refreshTagManagerDropDown];
						 [self stopComet];
						 [self reloadTagListWithCompletion:^(){
							 [self getNextUpdate];			// restart getting comet using the new mac (all).
						 }];

						 [_tvc reload]; [_evc reload];
						 
						 [self updateServerOpt:serverOpt];
						 [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
						 
					 }errorBlock:^(NSError* e, id* showFrom){
						 if(e.userInfo!=nil){
							 NSString* message = (NSString*)[e.userInfo objectForKey:@"Message"];
							 if([message rangeOfString:@"unauthorized" options:NSCaseInsensitiveSearch].length>0 || [message rangeOfString:@"authentication" options:NSCaseInsensitiveSearch].length>0){
								 [self showLogin];
								 return NO;		// do not proceed with displaying the error.
							 }
						 }
						 return YES;
					 } setMac:nil ];
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
	if(alreadyLaunched)[self reloadFromNetwork];
}

-(void)genericOpenLog:(NSString*)url fileName:(NSString*)fileName barButton:(id)sender completion:(void (^)(void))completion {
	
	dispatch_queue_t downloadQueue = dispatch_queue_create("com.MyTagList.logDownloadQueue", NULL);
	dispatch_async(downloadQueue, ^{
		NSError* error=nil;
		NSData * data =[AsyncURLConnection syncGetRequest:url error:&error];
		//[NSData dataWithContentsOfURL:url options:0 error:&error];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			completion();
			
			if(error!=nil){
				[AsyncSoapURLConnection standardShowError:error From:nil];
			}else{
				NSString *filePath=[NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
				NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath ];
				if(handle == nil) {
					[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
					handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
				}
				[handle truncateFileAtOffset:0];
				[handle writeData:data]; [handle closeFile];
                NSURL* url =[NSURL fileURLWithPath:filePath];
				UIDocumentInteractionController* docPreview = [UIDocumentInteractionController
															   interactionControllerWithURL:url];
                //docPreview.name =url.lastPathComponent;
				docPreview.UTI = @"public.comma-separated-values-text";
				docPreview.delegate = self;
                if([[UIDevice currentDevice].systemVersion floatValue] >= 11)
                    [docPreview presentPreviewAnimated:YES];
                else
                    [docPreview presentOptionsMenuFromBarButtonItem:sender animated:YES];
                //
                //[docPreview presentOpenInMenuFromRect:<#(CGRect)#> inView:<#(nonnull UIView *)#> animated:<#(BOOL)#>]
				[docPreview retain];
			}
		});
	});
	dispatch_release(downloadQueue);

}
-(void)dismissGraphOpenedFromURL{
	if(_mvc.presentedViewController.presentedViewController!=nil)
		[_mvc.presentedViewController dismissViewControllerAnimated:YES completion:nil];
	else
		[_mvc dismissViewControllerAnimated:YES completion:nil];
}
-(BOOL)focusOnTagUUID:(NSString*)uuid{
	
	for(NSMutableDictionary* tag in _mvc.tagList){
		if([uuid hasPrefix:@"@"]){
			if(tag.slaveId == [[uuid substringFromIndex:1] intValue]){
				[self tagSelected:tag fromCell:[_mvc cellForTag:tag]];
				return YES;
			}
		}
		else if([tag.uuid isEqualToString:uuid]){
			
			[self tagSelected:tag fromCell:[_mvc cellForTag:tag]];
			return YES;
		}
	}
	// did not find the tag; switch tag manager and try again.
	if(![uuid hasPrefix:@"@"] && ![[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey] ){
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/SelectTagManagerForTag"]
						 jsonString:[NSString  stringWithFormat:@"{uuid: '%@'}", uuid]
					  completeBlock:^(NSDictionary* retval){
						  
						  [self refreshTagManagerDropDown];
						  [self reloadTagListWithCompletion:^(){
							  
							  for(NSMutableDictionary* tag in _mvc.tagList){
								  if([tag.uuid isEqualToString:uuid]){
									  [self tagSelected:tag fromCell:[_mvc cellForTag:tag]];
									  break;
								  }
							  }
							  
						  }];
						  
					  }errorBlock:^(NSError* err, id* showFrom){
						  return YES;
					  } setMac:nil];
		return YES;
	}
	
	return NO;

}
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (url == nil)
        return NO;

	
    // The URL should contain something like:
    // "wtg://[type]@[tag name]/uuids/startdate/stopdate
	// type can be "detail" to open detailviewcontroller, or "widgetConfig" (uuids will be empty string).
    NSString* type, *name;
	NSArray* uuids;
	NSDate* fromDate=nil, *toDate=nil;
    NSArray *strURLParse = [[url absoluteString] componentsSeparatedByString:@"//"];
	if ([strURLParse count] == 2) {
		
        NSArray *params = [[strURLParse objectAtIndex:1] componentsSeparatedByString:@"/"];
		if(params.count<2)return NO;
		
        NSArray* type_and_name= [[params objectAtIndex:0] componentsSeparatedByString:@"@"];
		type=[type_and_name objectAtIndex:0];
		if(type_and_name.count>1)
			name = [[type_and_name objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		else
			name=NSLocalizedString(@"Unnamed",nil);
		
		uuids = [[params objectAtIndex:1]componentsSeparatedByString:@":"];
		if(params.count>2)
			fromDate = [NSDate dateWithTimeIntervalSince1970:[[params objectAtIndex:2] doubleValue]];
		if(params.count>3)
			toDate = [NSDate dateWithTimeIntervalSince1970:[[params objectAtIndex:3] doubleValue]];
    }else{
		return NO;
	}
	if([type isEqualToString:@"detail"] && uuids.count==1){
		NSString* uuid = [uuids objectAtIndex:0];
		
		if(alreadyLaunched){
			return [self focusOnTagUUID:uuid];
		}else{
			self.uuid_pending_focus=uuid;
		}
		return YES;
	}
	if([type isEqualToString:@"widgetConfig"]){

		[self configureWidget:_mvc.wirelessConfigBtn];
		return YES;
	}
	if(uuids.count==1 && ![type isEqualToString:@"motion"]){
		NSString* uuid = [uuids objectAtIndex:0];
		syncLoadRawData_t loader =^NSArray*(NSString* start, NSString* end){

			NSError* error;
			NSDictionary* ret = [AsyncURLConnection syncRequest:
								 [WSROOT stringByAppendingString:@"ethLogShared.asmx/GetStatsRawByUUID"]
														jsonObj:@{@"uuid": uuid, @"fromDate":start, @"toDate":end }
														  error:&error setMac:nil];
			return [ret objectForKey:@"d"];
		};
		NSString* title =[name stringByAppendingString:@" - Graph"];

		GraphViewController* vc = [[[LandscapeGraphViewController alloc] initPrimaryWithTitle:title andFrame:_dvc.view.frame
																				andSpanLoader:^(onDataSpan onData){
																					if(self.spinner==nil)
																						self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																					
																					[AsyncURLConnection
																					 request:[WSROOT stringByAppendingString:@"ethLogShared.asmx/GetMultiTagStatsSpanByUUIDs"]
																					 jsonObj:@{@"ids": @[uuid],	@"type":@"temperature"}
																					 completeBlock:^(NSDictionary* retval)
																					{
																						[self.spinner removeSpinner]; self.spinner=nil;
																						onData([retval objectForKey:@"d"]);
																					 }
																					 errorBlock:^(NSError* err, id* showFrom)
																					{
																						[self.spinner removeSpinner]; self.spinner=nil;
																						*showFrom = nil;
																						 return YES;
																					 }setMac:_dvc.xSetMac];
																					
																				}andHourlyLoader:^(onHourlyData onData){
																					if(self.spinner==nil)
																						self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																					[AsyncURLConnection
																					 request:[WSROOT stringByAppendingString:@"ethLogShared.asmx/GetTemperatureStatsByUUID"]
																					 jsonObj:@{@"id":uuid}
																					 completeBlock:^(NSDictionary* retval)
																					{
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 onData([retval objectForKey:@"d"]);
																					 }
																					 errorBlock:^(NSError* err, id* showFrom)
																					{
																						 *showFrom = nil;
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 return YES;
																					 }setMac:_dvc.xSetMac];
																					
																				}andType:nil andDataLoader:loader ] autorelease];
		
		vc.logDownloader = ^(GraphViewController* vc1, UIBarButtonItem* sender_vc, NSString* fromDate, NSString* toDate){
			[vc1 showLoadingBarItem:sender_vc];
			[self genericOpenLog:[WSROOT stringByAppendingFormat:@"ethDownloadTempCSV.aspx?uuid=%@&name=%@&fromDate=%@&toDate=%@",
								  uuid,name, fromDate, toDate] fileName:@"TemperatureLog.csv" barButton:sender_vc completion:^(){
				[vc1 revertLoadingBarItem:sender_vc];
			}];
		};
		
		vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(dismissGraphOpenedFromURL)];
		
		UIViewController* topVC = _mvc.presentedViewController==nil?_mvc:_mvc.presentedViewController;
		[topVC presentViewController:[[[UINavigationController alloc] initWithRootViewController:vc] autorelease] animated:YES completion:^(){
			if(fromDate!=nil)
				[vc setRangeWithMinimum:fromDate andMaximum:toDate];
			
		}];
		
		
	}else{
/*		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethLogShared.asmx/GetHourlyStatsByUUIDs"]
							jsonObj:@{@"ids": uuids,	@"type": type}
					  completeBlock:^(NSDictionary* retval){  */
		
		syncLoadRawData_t loader = ^NSArray*(NSString* start, NSString* end){
			NSError* error;
			NSDictionary* ret = [AsyncURLConnection syncRequest:
								 [WSROOT stringByAppendingString:@"ethLogShared.asmx/GetMultiTagStatsRawByUUIDs"]
														jsonObj:@{@"ids": uuids,
																  @"type": type,
																  @"fromDate":start, @"toDate":end }
														  error:&error setMac:_dvc.xSetMac];
			return [[ret objectForKey:@"d"] objectForKey:@"stats"];
		};
		
		GraphViewController* vc = [[[LandscapeGraphViewController alloc] initPrimaryWithTitle:nil andFrame:_dvc.view.frame
																				andSpanLoader:^(onDataSpan onData){
																					if(self.spinner==nil)
																						self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																					
																					[AsyncURLConnection
																					 request:[WSROOT stringByAppendingString:@"ethLogShared.asmx/GetMultiTagStatsSpanByUUIDs"]
																					 jsonObj:@{@"ids": uuids,	@"type":type}
																					 completeBlock:^(NSDictionary* retval)
																					 {
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 onData([retval objectForKey:@"d"]);
																					 }
																					 errorBlock:^(NSError* err, id* showFrom)
																					 {
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 *showFrom = nil;
																						 return YES;
																					 }setMac:_dvc.xSetMac];
																					
																				}andHourlyLoader:^(onHourlyData onData){
																					if(self.spinner==nil)
																						self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
																					
																					[AsyncURLConnection
																					 request:[WSROOT stringByAppendingString:@"ethLogShared.asmx/GetHourlyStatsByUUIDs"]
																					 jsonObj:@{@"ids":uuids, @"type":type}
																					 completeBlock:^(NSDictionary* retval)
																					 {
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 onData([retval objectForKey:@"d"]);
																					 }
																					 errorBlock:^(NSError* err, id* showFrom)
																					 {
																						 *showFrom = nil;
																						 [self.spinner removeSpinner]; self.spinner=nil;
																						 return YES;
																					 }setMac:_dvc.xSetMac];
																					
																				}andType:nil andDataLoader:loader ] autorelease];
		
		
		vc.logDownloader =^(GraphViewController* vc1, UIBarButtonItem* sender_vc, NSString* fromDate, NSString* toDate){
			[vc1 showLoadingBarItem:sender_vc];
			[self genericOpenLog:[WSROOT stringByAppendingFormat:@"ethDownloadMultiStatsCSV.aspx?uuids=%@&name=%@&fromDate=%@&toDate=%@",
								  [uuids componentsJoinedByString:@":" ] ,name, fromDate, toDate] fileName:[NSString stringWithFormat:@"%@_Log.csv", vc.type.name]
					   barButton:sender_vc completion:^(){
						   [vc1 revertLoadingBarItem:sender_vc];
					   }];
		};
		
		vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(dismissGraphOpenedFromURL)];
		
		
		UIViewController* topVC = _mvc.presentedViewController==nil?_mvc:_mvc.presentedViewController;
		[topVC presentViewController:[[[UINavigationController alloc] initWithRootViewController:vc] autorelease] animated:YES completion:^(){
			if(fromDate!=nil)
				[vc setRangeWithMinimum:fromDate andMaximum:toDate];
		}];
		
	}
	
    return YES;
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults]synchronize];
	[self stopComet];
	//self.locationManager=nil;
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
	
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self stopComet];
	[_launchOptions release];
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end
/*@implementation AVCaptureDevice (iPhone7BugOverride)
-(AVCaptureColorSpace)activeColorSpace{
	return AVCaptureColorSpace_sRGB;
}
-(void)setActiveColorSpace:(AVCaptureColorSpace)activeColorSpace{
	NSLog(@"%ld", activeColorSpace);
}
@end*/
@implementation AVCaptureSession (iPhone7BugOverride)
-(BOOL) automaticallyConfiguresCaptureDeviceForWideColor{
	return NO;
}
@end
@implementation UIFont (SystemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
	return [UIFont fontWithName:@"Avenir-Medium" size:fontSize];
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
	return [UIFont fontWithName:@"Avenir-Light" size:fontSize];
}
+ (UIFont *)italicSystemFontOfSize:(CGFloat)fontSize{
	return [UIFont fontWithName:@"Avenir-LightOblique" size:fontSize];
}
#pragma clang diagnostic pop

@end
@implementation NSNull (JSON)
- (NSUInteger)length { return 0; }
- (NSInteger)integerValue { return 0; };
- (float)floatValue { return 0; };
- (NSString *)description { return @"0(NSNull)"; }
- (NSArray *)componentsSeparatedByString:(NSString *)separator { return @[]; }
- (id)objectForKey:(id)key { return nil; }
- (BOOL)boolValue { return NO; }
@end


