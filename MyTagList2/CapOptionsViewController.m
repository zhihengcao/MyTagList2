//
//  TempOptionsViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CapOptionsViewController.h"
#import "Tag.h"
#import "OptionPicker.h"
#import "AsyncURLConnection.h"


@implementation CapOptionsViewController
@synthesize modified=_modified, capDelegate=_capDelegate, tag=_tag, cap2Config=_cap2Config, rnc_cap2=_rnc_cap2, rnc_toowet=_rnc_toowet, rnc_toodry=_rnc_toodry;
@synthesize loginEmail=_loginEmail;

static int responsiveness_values[] = {4,8,16,32,48};

- (id)initWithDelegate:(id<OptionsViewControllerDelegate, CapOptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		self.capDelegate = delegate;
		_modified=NO;
		responsiveness_choices = [[NSArray
								   arrayWithObjects:NSLocalizedString(@"Fast (worst battery life)",nil), NSLocalizedString(@"Medium fast",nil),
								   NSLocalizedString(@"Medium",nil), NSLocalizedString(@"Medium slow",nil), NSLocalizedString(@"Slow (best battery life)",nil), nil] retain];
		cap_unit_choices=[[NSArray arrayWithObjects:NSLocalizedString(@"Relative Humidity (%)",nil),NSLocalizedString(@"Dew Point (°F/°C)",nil), nil] retain];
		self.rnc_cap2_changed=NO;
    }
    return self;
}
-(void)releaseViews{
	[responsiveness release]; responsiveness=nil; 
	[cap_range release]; cap_range=nil;
	[cap_cal release]; cap_cal=nil;
	[cap_cal_btn release]; cap_cal_btn=nil;
	[cap_uncal_btn release]; cap_uncal_btn=nil;
	[monitor_cap release]; monitor_cap=nil;
	[email release]; email=nil;
	[send_email release]; send_email=nil;
	[beep_pc release]; beep_pc=nil; [use_speech release]; use_speech=nil; [vibrate release]; vibrate=nil;
	[send_tweet release]; send_tweet=nil;
	[tweetLogin release]; tweetLogin=nil;
	
	[email_cap2 release]; email_cap2=nil;
	[send_email_cap2 release]; send_email_cap2=nil;
	[beep_pc_cap2 release]; beep_pc_cap2=nil;
	[use_speech_cap2 release]; use_speech_cap2=nil;
	[vibrate_cap2 release]; vibrate_cap2=nil;
	[send_tweet_cap2 release]; send_tweet_cap2=nil;
	[tweetLogin_cap2 release]; tweetLogin_cap2=nil;
	[notify_open_cap2 release]; notify_open_cap2=nil;
	[apns_sound_cap2 release]; apns_sound_cap2=nil;
	[apns_sound release]; apns_sound=nil;
	[apns_pause release]; apns_pause=nil;
	[rn_toodry release]; rn_toodry=nil;
	[rn_toowet release]; rn_toowet=nil;
	[rn_cap2 release]; rn_cap2=nil;
}
-(void)dealloc{
	[responsiveness_choices release];
	[cap_unit_choices release];
	[_rnc_toodry release]; [_rnc_toowet release];
	self.loginEmail=nil;
	[self releaseViews];
	self.config=nil;
	self.cap2Config=nil;
	[super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSSliderSpecifierViewCell	class]])
		return 86;
	else if([cell isKindOfClass:[IASKPSDualSliderSpecifierViewCell	class]])
		return 120;
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}

-(void)setRnc_toowet:(NSMutableDictionary *)rnc_toowet{
	[_rnc_toowet autorelease];
	_rnc_toowet = [rnc_toowet retain];
	int selected=0;
	if(self.rnc_toowet){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_toowet.intervalSec){
				selected=i; break;
			}
	}
	rn_toowet.textField.text = rnc_timespan_choices[selected];
}
-(void)setRnc_toodry:(NSMutableDictionary *)rnc_toodry{
	[_rnc_toodry autorelease];
	_rnc_toodry = [rnc_toodry retain];
	int selected=0;
	if(self.rnc_toodry){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_toodry.intervalSec){
				selected=i; break;
			}
	}
	rn_toodry.textField.text = rnc_timespan_choices[selected];
}
-(void)setRnc_cap2:(NSMutableDictionary *)rnc_cap2{
	[_rnc_cap2 autorelease];
	_rnc_cap2 = [rnc_cap2 retain];
	int selected=0;
	if(self.rnc_cap2){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_cap2.intervalSec){
				selected=i; break;
			}
	}
	rn_cap2.textField.text = rnc_timespan_choices[selected];
	self.rnc_cap2_changed=NO;
}

-(void)navbarSave{
	NSMutableDictionary* c = self.config;
	old_th_low =c.th_low;
	old_th_high = c.th_high;
	c.th_low = cap_range.slider.selectedMinimumValue;
	c.th_high = cap_range.slider.selectedMaximumValue;
	
	c.send_email = send_email.toggle.on;
	c.email=email.textField.text;
	c.beep_pc = beep_pc.toggle.on;
	c.beep_pc_tts = use_speech.toggle.on;
	c.beep_pc_vibrate = vibrate.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	
	if(_cap2Config!=nil){
		
		_cap2Config.send_email = send_email_cap2.toggle.on;
		_cap2Config.send_tweet = send_tweet_cap2.toggle.on;
		_cap2Config.email = email_cap2.textField.text;
		
		_cap2Config.beep_pc = beep_pc_cap2.toggle.on;
		_cap2Config.beep_pc_tts = use_speech_cap2.toggle.on;
		
		_cap2Config.beep_pc_vibrate = vibrate_cap2.toggle.on;
		_cap2Config.notify_open = notify_open_cap2.toggle.on;
		[self.capDelegate saveWaterSensorConfig:_cap2Config];
	}
	
	[self.delegate optionViewSaveBtnClicked:self];	
}

-(void)armDisarmCapsensorAsNeededWithApplyAll:(BOOL)applyAll{

	if((_tag.capEventState<=CapDisarmed && monitor_cap.toggle.on) ||
	   (monitor_cap.toggle.on && (fabs(old_th_low-self.config.th_low)>0.001 || fabs(old_th_high-self.config.th_high)>0.001)))
		if(applyAll)
			[_capDelegate armCapSensorForAllTags];
		else
			[_capDelegate armCapSensorForTag:_tag];
		else if(_tag.capEventState>CapDisarmed && !monitor_cap.toggle.on){
			if(applyAll)
				[_capDelegate disarmCapSensorForAllTags];
			else
				[_capDelegate disarmCapSensorForTag:_tag];
		}
}

-(int)responsiveness_index_from_interval:(int)interval{
	int i;
	for(i=0;i<sizeof(responsiveness_values);i++){
		if(interval<=responsiveness_values[i]){
			break;
		}
	}
	return i;
}

-(void)updateTag:(NSMutableDictionary*)tag{
	self.tag= tag;
	monitor_cap.toggleOn = (tag.capEventState>CapDisarmed);
	[cap_cal setVal:tag.cap];
}

-(void)setConfig:(NSMutableDictionary *)c2 andTag:(NSMutableDictionary*)tag
{
	self.tag= tag;
	[super view];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];	

	NSMutableDictionary* c = [c2 objectForKey:@"rhEvent"];
	self.cap2Config =[c2 objectForKey:@"shortedEvent"];
	if((id)_cap2Config==[NSNull null])_cap2Config=nil;
	if(_cap2Config){
		monitor_cap.title = NSLocalizedString(@"Monitor Water-Level/Moisture",nil);
		send_email_cap2.toggleOn=_cap2Config.send_email;
		send_tweet_cap2.toggleOn=_cap2Config.send_tweet;
		if(_cap2Config.email.isEmpty)
			email_cap2.textField.text=c.loginEmail;
		else
			email_cap2.textField.text = _cap2Config.email;
		beep_pc_cap2.toggleOn=_cap2Config.beep_pc;
		use_speech_cap2.toggleOn=_cap2Config.beep_pc_tts;
		vibrate_cap2.toggleOn=_cap2Config.beep_pc_vibrate;
		apns_sound_cap2.textField.text=_cap2Config.apnsSound.isEmpty?apns_sound_choices[0]:_cap2Config.apnsSound;
		notify_open_cap2.toggleOn = _cap2Config.notify_open;
	}else{
		monitor_cap.title=NSLocalizedString(@"Monitor Humidity",nil);
	}

	responsiveness.textField.text = [responsiveness_choices objectAtIndex:[self responsiveness_index_from_interval:c.interval]];
	cap_range.slider.currentValue = tag.cap;
	cap_range.slider.selectedMaximumValue = c.th_high;
	cap_range.slider.selectedMinimumValue=c.th_low;
	[cap_range sliderValueChanged:nil];
		
	send_email.toggleOn = c.send_email;
	send_tweet.toggleOn = c.send_tweet;
	if(!c.email.isEmpty)
		email.textField.text = c.email;
	else
		email.textField.text = c.loginEmail;
	
	beep_pc.toggleOn= c.beep_pc;
	use_speech.toggleOn=c.beep_pc_tts; vibrate.toggleOn=c.beep_pc_vibrate;
	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	apns_pause.textField.text = apns_pause_choices[ c.apns_pause_index ];

	monitor_cap.toggleOn = (tag.capEventState>CapDisarmed);
	[cap_cal setVal:tag.cap];
	[super setConfig:c];
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	cap_units = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Display:",nil)];
	cap_units.textField.text = [cap_unit_choices objectAtIndex:dewPointMode];

	monitor_cap = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Monitor Humidity/Moisture",nil) helpText:NSLocalizedString(@"Periodically check humidity sensor/capacitive moisture sensor reading and notify when reading becomes too high/too low or returns to normal.",nil) delegate:self];
	responsiveness = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Response:",nil)];
	
	cap_range = [IASKPSDualSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"< Normal Range <",nil) Min:0 Max:100 Unit:@"%" numberFormat:@"%.1f" delegate:self];
	cap_cal = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Calibrate To:",nil) Min:0 Max:100 Step: 1 Unit:@"%" delegate:self];

	cap_cal_btn = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Calibrate",nil) Progress:NSLocalizedString(@"Saving...",nil)];
	cap_uncal_btn = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Remove Calibration",nil) Progress:NSLocalizedString(@"Saving...",nil)];

	email =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self];
	email_cap2 =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self];
	
	send_email = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"Send emails when humidity/moisture/water-level becomes too high, too low or back to normal range.",nil) delegate:self];
	send_email_cap2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"Send emails when water is detected at the tip",nil) delegate:self];
	notify_open_cap2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Notify Also When Dry",nil) helpText:NSLocalizedString(@"check to notify also when water is no longer detected / tip is electrically open",nil) delegate:self];
	
	send_tweet = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"The tag will tweet on behalf of you when humidity/moisture/water-level becomes too high, too low or back to normal range.",nil) delegate:self];
	send_tweet_cap2= [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"The tag will tweet on behalf of you when water is detected at the tip",nil) delegate:self];
	
	tweetLogin = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting",nil)];
	tweetLogin_cap2 = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting",nil)];
	
	beep_pc = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' when humidity/moisture/water-level becomes too high, too low or returns within the normal range.",nil) delegate:self];
	beep_pc_cap2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' when water is detected at sensor tip.",nil) delegate:self];
	
	use_speech = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	use_speech_cap2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	
	vibrate = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil) delegate:self];
	vibrate_cap2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil) delegate:self];
	
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	apns_pause =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPause Action Effective For: ",nil)];

	apns_sound_cap2 = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];

	rn_toowet =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too wet:",nil)];  rn_toowet.textField.text = rnc_timespan_choices[0];
	rn_toodry =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too dry:",nil)]; rn_toodry.textField.text = rnc_timespan_choices[0];
	rn_cap2 =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify water detect:",nil)]; rn_cap2.textField.text = rnc_timespan_choices[0];
	
	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
}
- (IBAction)hideKeyboard{
	[[self view]endEditing:YES];
}

- (void)viewDidUnload
{
    [self releaseViews];
    [super viewDidUnload];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

// [when out of range (email, addr, ringpc, usespeech, vib)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==0){
		if(_cap2Config)return NSLocalizedString(@"When Detected Water",nil);
		else return nil;
	}
	else if(section==1)
		return NSLocalizedString(@"Monitor Moisture:",nil);
	else if(_tag.needCapCal)
		return [NSLocalizedString(@"Water-Level/Moisture Calibration",nil) stringByAppendingFormat:@" (Raw Reading: %.1f%%)", ((1.0/_tag.capRaw - 1.0/240.0) * (-100) / (1.0 / 240.0 - 1.0 / 8.0))];
	else
		return [NSLocalizedString(@"Humidity Calibration",nil) stringByAppendingFormat:@" (Raw Reading: %.1f%%)", _tag.cap-_tag.capCalOffset];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0){
		if(_cap2Config)
			return 2+(send_email_cap2.toggleOn?2:1)+(beep_pc_cap2.toggleOn?4:1)+(send_tweet_cap2.toggleOn?2:1);
		return 1;
	}
	else if(section==2){
		return 3;
	}else
		return monitor_cap.toggleOn? (5+(send_email.toggleOn?2:1)+(beep_pc.toggleOn?5:1)+(send_tweet.toggleOn?2:1)) : 1;
}

-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;

	if(cell == send_email){
		[self.tableView beginUpdates];
		[send_email updateToggleOn];
		if(send_email.toggle.on){
			if(email.textField.text.length==0)email.textField.text = self.loginEmail;
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:4 inSection:1], nil] withRowAnimation:UITableViewRowAnimationTop];
		}else
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:4 inSection:1], nil] withRowAnimation:UITableViewRowAnimationTop];
		
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
	else if(cell==send_tweet){
		int base = send_email.toggle.on?6:5;
		[self.tableView beginUpdates];
		[send_tweet updateToggleOn];
		if(send_tweet.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
	else if(cell==beep_pc){
		int base = (send_email.toggle.on?6:5) + (send_tweet.toggle.on?2:1);
		[self.tableView beginUpdates];
		if(beep_pc.toggle.on){
			[beep_pc updateToggleOn];
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],
			  [NSIndexPath indexPathForRow:base+1 inSection:1],[NSIndexPath indexPathForRow:base+2 inSection:1],[NSIndexPath indexPathForRow:base+3 inSection:1],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[beep_pc updateToggleOn];
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],
			  [NSIndexPath indexPathForRow:base+1 inSection:1],[NSIndexPath indexPathForRow:base+2 inSection:1],[NSIndexPath indexPathForRow:base+3 inSection:1],nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];

	}
	else if(cell == send_email_cap2){
		[self.tableView beginUpdates];
		[send_email_cap2 updateToggleOn];
		if(send_email_cap2.toggle.on){
			if(email_cap2.textField.text.length==0)email_cap2.textField.text = self.loginEmail;
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationTop];
		}else
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationTop];
		
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
	else if(cell==send_tweet_cap2){
		int base = send_email_cap2.toggle.on?3:2;
		[self.tableView beginUpdates];
		[send_tweet_cap2 updateToggleOn];
		if(send_tweet_cap2.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
	else if(cell==beep_pc_cap2){
		int base = (send_email_cap2.toggle.on?3:2) + (send_tweet_cap2.toggle.on?2:1);
		[self.tableView beginUpdates];
		if(beep_pc_cap2.toggle.on){
			[beep_pc_cap2 updateToggleOn];
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],
			  [NSIndexPath indexPathForRow:base+1 inSection:0],[NSIndexPath indexPathForRow:base+2 inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[beep_pc_cap2 updateToggleOn];
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],
			  [NSIndexPath indexPathForRow:base+1 inSection:0],[NSIndexPath indexPathForRow:base+2 inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
		
	}
	else if(cell==monitor_cap){
		[self.tableView beginUpdates];
		NSMutableArray* ips = [NSMutableArray arrayWithCapacity:10];
		int num = (5+(send_email.toggle.on?2:1)+(beep_pc.toggle.on?5:1)+(send_tweet.toggle.on?2:1));
		for(int i=1;i<num;i++){
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:1]];
		}
		if(monitor_cap.toggle.on){
			[monitor_cap updateToggleOn];
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[monitor_cap updateToggleOn];
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.section==0){
		if(_cap2Config){
			NSMutableArray* cells = [NSMutableArray arrayWithCapacity:8];
			[cells addObject:send_email_cap2];
			if(send_email_cap2.toggleOn){
				[cells addObject:email_cap2];
			}
			[cells addObject:send_tweet_cap2];
			if(send_tweet_cap2.toggleOn)
				[cells addObject:tweetLogin_cap2];
			[cells addObject:beep_pc_cap2];
			if(beep_pc_cap2.toggleOn){
				[cells addObject:use_speech_cap2];
				[cells addObject:apns_sound_cap2];
				[cells addObject:vibrate_cap2];
			}
			[cells addObject:rn_cap2];
			[cells addObject:notify_open_cap2];
			return [cells objectAtIndex:ip.row];
		}
		else return cap_units;
	}
	else if(ip.section==2 ){
		if(ip.row==0)
			return cap_cal;
		else if(ip.row==1)
			return cap_cal_btn;
		else
			return cap_uncal_btn;
	}else{
		NSMutableArray* cells = [NSMutableArray arrayWithCapacity:5];
		[cells addObject:monitor_cap];
		if(monitor_cap.toggleOn){
			[cells addObject:cap_range];
			[cells addObject:responsiveness];
			[cells addObject:send_email];
			if(send_email.toggleOn){
				[cells addObject:email]; 
			}
			[cells addObject:send_tweet];
			if(send_tweet.toggleOn)
				[cells addObject:tweetLogin];
			[cells addObject:beep_pc];
			if(beep_pc.toggleOn){
				[cells addObject:use_speech];
				[cells addObject:apns_pause];
				[cells addObject:apns_sound];
				[cells addObject:vibrate];
			}
			[cells addObject:rn_toowet];
			[cells addObject:rn_toodry];
		}
		return [cells objectAtIndex:ip.row];
	}
}

- (void)showLoadingBarItem:(id) item
{
	if(item==cap_cal_btn)[cap_cal_btn showLoading];
	else if(item==cap_uncal_btn)[cap_uncal_btn showLoading];
	else [super showLoadingBarItem:item];
}
- (void)revertLoadingBarItem:(id) item{
	if(item==cap_cal_btn)[cap_cal_btn revertLoading];
	else if(item==cap_uncal_btn)[cap_uncal_btn revertLoading];
	else [super revertLoadingBarItem:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	[tableView deselectRowAtIndexPath:ip animated:YES];

	OptionPicker *picker=nil;
	if(ip.section==0){
		if(_cap2Config){
			
			UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
			if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
				[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
				[tableView beginUpdates];
				[tableView endUpdates];
				[self scheduleRecalculatePopoverSize];
			}
			else if(cell==rn_cap2){
				int selected=0;
				if(self.rnc_cap2){
					for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
						if(rnc_timespan_values[i]== self.rnc_cap2.intervalSec){
							selected=i; break;
						}
				}
				picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
													  Selected:selected
														  Done:^(NSInteger selected_new, BOOL now){
															  rn_cap2.textField.text = rnc_timespan_choices[selected_new];
															  
															  if(_rnc_cap2==nil && selected_new>0){
																  _rnc_cap2=[@{@"eventType":@3} mutableCopy];
															  }
															  self.rnc_cap2.intervalSec = rnc_timespan_values[selected_new];
															  
															  if(selected_new!=selected)self.rnc_cap2_changed=YES;
															  
															  /*if(self.rnc_cap2 && selected_new!=selected){
																  [AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveRepeatNotifyConfig"]
																					  jsonObj:@{@"uuid": _tag.uuid, @"sensorType": @3, @"config":@[self.rnc_cap2]} completeBlock:nil
																				   errorBlock:^(NSError* err, id* showFrom){
																					   *showFrom = rn_cap2;
																					   return YES;
																				   } setMac:nil];

															  }*/
														  } helpText:NSLocalizedString(@"Choose get notified just once or repeatedly when water is detected/tip is shorted until tip is wiped dry/electrically open. ",nil) ] autorelease];

			}
			else if(cell == apns_sound_cap2){
				picker = [[[OptionPicker alloc]initWithOptions:
						   [NSArray arrayWithObjects:apns_sound_choices count:sizeof(apns_sound_choices)/sizeof(NSString*)]
													  Selected:_cap2Config.apns_sound_index
														  Done:^(NSInteger selected, BOOL now){
															  apns_sound_cap2.textField.text = apns_sound_choices[selected];
															  _cap2Config.apnsSound =apns_sound_choices[selected];
															  [super playAiff:selected];
														  } ] autorelease];
			}
			else if(cell==tweetLogin_cap2){
				[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
			}

		}else{
			picker = [[[OptionPicker alloc]initWithOptions:cap_unit_choices Selected:dewPointMode
													  Done:^(NSInteger selected, BOOL now){
														  cap_units.textField.text = [cap_unit_choices objectAtIndex:selected];
														  if(dewPointMode!=selected){
															  dewPointMode=(int)selected;
															  [self.capDelegate dewPointModeChanged];
														  }
													  } helpText:NSLocalizedString(@"This choice will affect how humidity is displayed/plotted for all tags with humidity sensor.",nil) ] autorelease];
		}
	}
	else if(ip.section==2 ){
		if(ip.row==1){
			float RH = cap_cal.slider.value; 
			[self.capDelegate capCalibrateBtnClickedForTag:_tag Cap:RH BtnCell:cap_cal_btn];
		}else if(ip.row==2){
			[self.capDelegate capResetCalibrateBtnClickedForTag:_tag BtnCell:cap_uncal_btn];
		}
	}else{
		UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
		if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
			[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
			[tableView beginUpdates];
			[tableView endUpdates];
			[self scheduleRecalculatePopoverSize];
		}
		else if(cell == apns_sound){
			picker = [[[OptionPicker alloc]initWithOptions:
					   [NSArray arrayWithObjects:apns_sound_choices count:sizeof(apns_sound_choices)/sizeof(NSString*)]
												  Selected:self.config.apns_sound_index
													  Done:^(NSInteger selected, BOOL now){
														  apns_sound.textField.text = apns_sound_choices[selected];
														  self.config.apnsSound =apns_sound_choices[selected];
														  [super playAiff:selected];
													  } ] autorelease];
		}
		else if(cell == apns_pause){
			
			picker = [[[OptionPicker alloc]initWithOptions:
					   [NSArray arrayWithObjects:apns_pause_choices count:sizeof(apns_pause_choices)/sizeof(NSString*)]
												  Selected:self.config.apns_pause_index
													  Done:^(NSInteger selected, BOOL now){
														  apns_pause.textField.text = apns_pause_choices[selected];
														  self.config.apns_pause =apns_pause_values[selected];
													  } helpText:NSLocalizedString(@"Swipe left on a notification of 'Too Wet' or 'Too Dry' events to see 'Pause' and 'Stop Monitoring' button. 'Pause' to temporarily stop receiving the notification but still keep populating Event History. 'Stop monitoring' will temporarily disable humidity monitoring. Here you can choose the time after which to automatically resume receiving events or re-enable monitoring.",nil)] autorelease];
		}
		
		else if(cell==rn_toodry){
			int selected=0;
			if(self.rnc_toodry){
				for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
					if(rnc_timespan_values[i]== self.rnc_toodry.intervalSec){
						selected=i; break;
					}
			}
			picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  rn_toodry.textField.text = rnc_timespan_choices[selected_new];
														  
														  if(_rnc_toodry==nil && selected_new>0){
															  _rnc_toodry=[@{@"eventType":@3} mutableCopy];
														  }
														  self.rnc_toodry.intervalSec = rnc_timespan_values[selected_new];
														  if(self.rnc_toodry && selected_new!=selected){
															  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																  if(obj==self.rnc_toodry)return;
															  
															  [self.updatedRepeatNotifyConfigs addObject:self.rnc_toodry];
														  }
													  } helpText:NSLocalizedString(@"Choose get notified just once or repeatedly when humidity/moisture falls below lower limit until returning to normal. ",nil)] autorelease];
		}
		else if(cell==rn_toowet){
			int selected=0;
			if(self.rnc_toowet){
				for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
					if(rnc_timespan_values[i]== self.rnc_toowet.intervalSec){
						selected=i; break;
					}
			}
			picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  rn_toowet.textField.text = rnc_timespan_choices[selected_new];
														  
														  if(_rnc_toowet==nil && selected_new>0){
															  _rnc_toowet=[@{@"eventType":@4} mutableCopy];
														 }
														  self.rnc_toowet.intervalSec = rnc_timespan_values[selected_new];
														  if(self.rnc_toowet && selected_new!=selected){
															  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																  if(obj==self.rnc_toowet)return;
															  
															  [self.updatedRepeatNotifyConfigs addObject:self.rnc_toowet];
														  }
														  
													  } helpText:NSLocalizedString(@"Choose get notified just once or repeatedly when humidity/moisture exceeds upper limit until returning to normal. ",nil)] autorelease];
		}
		else if(cell==tweetLogin){
			[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
		}
		else if(cell==responsiveness){
			picker = [[[OptionPicker alloc]initWithOptions:responsiveness_choices Selected:[self responsiveness_index_from_interval:self.config.interval]
													  Done:^(NSInteger selected, BOOL now){
														  responsiveness.textField.text = [responsiveness_choices objectAtIndex:selected];
														  self.config.interval=responsiveness_values[selected];
													  } helpText:NSLocalizedString(@"Slower response time allows longer battery life at the expense of longer delay in notification, by sampling sensor data less often.",nil) ] autorelease];
		}
	}
	[super presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:ip]];

/*	if(!picker)return;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		popoverController = [[UIPopoverController alloc] 
							 initWithContentViewController:picker];
		picker.dismissUI=^(){
			[popoverController dismissPopoverAnimated:YES]; [popoverController autorelease];			
		};
		//popoverController.popoverContentSize = CGSizeMake(420, 500);
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
		[popoverController presentPopoverFromRect:cell.bounds inView:cell.contentView 
						 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}else{
		popoverController=nil;
		picker.dismissUI=^(){
			[self.navigationController popViewControllerAnimated:YES];			
		};
		[self.navigationController pushViewController:picker animated:YES];
	}*/
}


@end

