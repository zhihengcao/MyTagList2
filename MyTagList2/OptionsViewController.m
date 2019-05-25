//
//  OptionsViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"
#import "OptionPicker.h"
#import "Tag.h"

float dewPoint(float RH, float T){
	float b = 17.67f, c = 243.5f;
	float u = logf(RH / 100.0f) + b * T / (c + T);
	return c * u / (b - u);
}

@implementation OptionsViewController
@synthesize config=_config, delegate=_delegate, updatedRepeatNotifyConfigs=_updatedRepeatNotifyConfigs;//, popoverContainer=_popoverContainer;

-(void)scheduleRecalculatePopoverSize{
	[NSTimer scheduledTimerWithTimeInterval:0.4 block:^()
	 {
		 if([self respondsToSelector:@selector(setPreferredContentSize:)])
			 self.preferredContentSize=self.tableView.contentSize;
		 
		 if(self.contentSizeForViewInPopover.height<self.tableView.contentSize.height)
			 self.contentSizeForViewInPopover = self.tableView.contentSize;
	 } repeats:NO];
	
}

- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
	self= [super initWithStyle:UITableViewStyleGrouped];
	if(self)
		self.delegate=delegate;
	return self;
}
-(void)playAiff:(NSInteger)index{

	[apnsSoundPlayer release];
	apnsSoundPlayer=nil;
	
	if(index==0){
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}else{
		NSString *soundPath =[[NSBundle mainBundle] pathForResource:apns_sound_choices[index] ofType:@"aiff"];
		if(soundPath!=nil){
			NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
			if(soundURL==nil)return;
			NSError *error = nil;
			apnsSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
			[apnsSoundPlayer play];
		}
	}
}
-(void)dealloc{
	[apnsSoundPlayer release]; apnsSoundPlayer=nil;
	self.updatedRepeatNotifyConfigs=nil;
	self.config=nil;
	[super dealloc];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}

-(void)setConfig:(NSMutableDictionary *)config{
	[_config autorelease];
	_config = [config retain];
	//self.config=config;
	self.updatedRepeatNotifyConfigs=[[[NSMutableArray alloc]initWithCapacity:3] autorelease];
	
	[self.tableView reloadData];
	//[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	//[self.tableView setNeedsDisplay];
	
	//CGSize reqsz =  self.tableView.contentSize;
	//self.contentSizeForViewInPopover = CGSizeMake(480, reqsz.height>600?620:reqsz.height+20);
	self.contentSizeForViewInPopover = self.tableView.contentSize;
}
-(void)presentPicker:(OptionPicker*)picker fromCell:(UITableViewCell*)cell{
	if(!picker)return;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		popoverController = [[UIPopoverController alloc]
							 initWithContentViewController:picker];
		picker.dismissUI = ^(BOOL animated){
			if([popoverController respondsToSelector:@selector(dismissPopoverAnimated:)])
				[popoverController dismissPopoverAnimated:animated];
			[popoverController autorelease];
		};
		//popoverController.popoverContentSize = picker.contentSizeForViewInPopover; //CGSizeMake(420, 500);
		[popoverController presentPopoverFromRect:cell.bounds inView:cell.contentView
						 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}else{
		popoverController=nil;
		picker.dismissUI=^(BOOL animated){
			[self.navigationController popViewControllerAnimated:animated];
		};
		[self.navigationController pushViewController:picker animated:YES];
	}
}
/*
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.contentSizeForViewInPopover = self.tableView.contentSize;
//    [self.popoverContainer setPopoverContentSize:self.contentSizeForViewInPopover animated:YES];
}
*/

@end


@implementation MSOptionsViewController
@synthesize modified=_modified, isReedPir=_isReedPir, isPir=_isPir, isALS=_isALS, isHmcTimeout=_isHmcTimeout, armDisarmState=_armDisarmState, rnc_open=_rnc_open, rnc_detected=_rnc_detected;
@synthesize loginEmail=_loginEmail;

static int trigger_delay_choices_val[]={0 ,30,60,120,300,600,900,1800,3600,7200};
static int auto_reset_choices_val[]={-1,10,20,30,45,60,120,300,600,1800};
static int pir_reset_choices_val[]={20,30,45,60,120,180, 300,600,900,1800};
static int notify_every_choices_val[] = {7200, 21600,86400, 259200, 604800};

- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
	self = [super initWithDelegate:delegate];
    if (self) {
		tod_f = [[NSDateFormatter alloc] init] ; 	[tod_f setDateFormat:@"h:mm a"];

		_modified=NO;
		responsiveness_choices = [[NSArray 
								   arrayWithObjects:NSLocalizedString(@"Highest (worst battery life)",nil), NSLocalizedString(@"Medium high",nil),
								   NSLocalizedString(@"Medium",nil),NSLocalizedString(@"Medium low",nil), NSLocalizedString(@"Lowest (best battery life)",nil), nil] retain];
		responsiveness_choices_accel = [[NSArray
								   arrayWithObjects:NSLocalizedString(@"3 seconds",nil), NSLocalizedString(@"2.8 seconds",nil), NSLocalizedString(@"2.6 seconds",nil),
										 NSLocalizedString(@"2.4 seconds",nil), NSLocalizedString(@"2.2 seconds",nil),
										 NSLocalizedString(@"2.0 seconds",nil), NSLocalizedString(@"1.8 seconds",nil),
										 NSLocalizedString(@"1.6 seconds",nil), NSLocalizedString(@"1.4 seconds",nil),
										 NSLocalizedString(@"1.2 seconds",nil), NSLocalizedString(@"1.0 seconds",nil), NSLocalizedString(@"0.8 seconds",nil), nil] retain];
		day_of_week = [[NSArray
								   arrayWithObjects:NSLocalizedString(@"Sunday",nil), NSLocalizedString(@"Monday",nil), NSLocalizedString(@"Tuesday",nil),
						NSLocalizedString(@"Wednesday",nil), NSLocalizedString(@"Thursday",nil),NSLocalizedString(@"Friday",nil), NSLocalizedString(@"Saturday",nil), nil] retain];
		trigger_delay_choices = [[NSArray arrayWithObjects:NSLocalizedString(@"Immediately",nil),
								  NSLocalizedString(@"for 30 seconds",nil),
								  NSLocalizedString(@"for 1 minute",nil),
								  NSLocalizedString(@"for 2 minutes",nil),
								  NSLocalizedString(@"for 5 minutes",nil),
								  NSLocalizedString(@"for 10 minutes",nil),
								  NSLocalizedString(@"for 15 minutes",nil),
								  NSLocalizedString(@"for 30 minutes",nil),
								  NSLocalizedString(@"for One Hour",nil),
								  NSLocalizedString(@"for Two Hours",nil),nil] retain];
		auto_reset_choices = [[NSArray arrayWithObjects:NSLocalizedString(@"Manually reset to armed state",nil),
							   NSLocalizedString(@"Auto reset after 10 seconds",nil),
							   NSLocalizedString(@"Auto reset after 20 seconds",nil),
							   NSLocalizedString(@"Auto reset after 30 seconds",nil),
							   NSLocalizedString(@"Auto reset after 45 seconds",nil),
							   NSLocalizedString(@"Auto reset after 1 minute",nil),
							   NSLocalizedString(@"Auto reset after 2 minutes",nil),
							   NSLocalizedString(@"Auto reset after 5 minutes",nil),
							   NSLocalizedString(@"Auto reset after 10 minutes",nil),
							   NSLocalizedString(@"Auto reset after half hour",nil), nil] retain];

		pir_reset_choices = [[NSArray arrayWithObjects:
							   NSLocalizedString(@"Timeout after 20 seconds",nil),
							   NSLocalizedString(@"Timeout after 30 seconds",nil),
							   NSLocalizedString(@"Timeout after 45 seconds",nil),
							   NSLocalizedString(@"Timeout after 1 minute",nil),
							   NSLocalizedString(@"Timeout after 2 minutes",nil),
							   NSLocalizedString(@"Timeout after 3 minutes",nil),
							  NSLocalizedString(@"Timeout after 5 minutes",nil),
							   NSLocalizedString(@"Timeout after 10 minutes",nil),
							  NSLocalizedString(@"Timeout after 15 minutes",nil),
							   NSLocalizedString(@"Timeout after half hour",nil), nil] retain];

		/*tod_choices = [[NSMutableArray alloc] initWithCapacity:24*4];
		tod_min_utc =[[NSMutableArray alloc] initWithCapacity:24*4]; 
		int tzo = -[[NSTimeZone localTimeZone] secondsFromGMT]/60;
		for(int h=0;h<24;h++){
			for(int q=0;q<4;q++){
				NSString* lit = [NSString stringWithFormat:@"%d:%.2d%@", (h>12?h-12:h),q*15,(h>12?@"PM":@"AM")];
				int min_utc = h*60+q*15 + tzo;
				[tod_choices addObject:lit];
				[tod_min_utc addObject:[NSNumber numberWithInt:min_utc]];
			}
		}*/
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																							   target:self action:@selector(navbarSave)] autorelease];

	}
    return self;
}
+(NSDate*)tod2NSDate:(int)tod{
	int tzo = 0; //-[[NSTimeZone localTimeZone] secondsFromGMT]/60;
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* comp = [[[NSDateComponents alloc]init] autorelease];
	comp.hour = floorf((tod-tzo)/60.0);
	comp.minute = roundf((tod-tzo)%60);
	return [cal dateFromComponents:comp];
}
+(int)NSDate2tod:(NSDate*)date{
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* comp = [cal components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:date];
	//int tzo = -[[NSTimeZone localTimeZone] secondsFromGMT]/60;
	return (int)(comp.hour * 60+comp.minute); // + tzo;
}
-(void)releaseViews{
	[sensitivity release]; sensitivity=nil; [threshold_angle release]; threshold_angle=nil;
	[responsiveness release]; responsiveness=nil; [trigger_delay release]; trigger_delay=nil; 
	[email release]; email=nil; 
	[door_mode release]; door_mode=nil;
	[hmc_timeout_mode release]; hmc_timeout_mode=nil;
	[send_email release]; send_email=nil;
	[send_email_close release]; send_email_close=nil; [beep_pc release]; beep_pc=nil; [use_speech release]; use_speech=nil;
	[beep_pc_loop release]; beep_pc_loop=nil; [vibrate release]; vibrate=nil; //[beep_tag release]; beep_tag=nil;
	[rn_detected release]; rn_detected=nil;
	[rn_open release]; rn_open=nil;
	
	[apns_sound release]; apns_sound=nil;
	[apns_pause release]; apns_pause=nil;
	[trigger_delay release]; trigger_delay=nil;
	[auto_reset_delay release]; auto_reset_delay=nil;
	[aa1_tod release]; aa1_tod=nil; [aa2_tod release];aa2_tod=nil;
	[ada1_tod release]; ada1_tod=nil; [ada2_tod release];ada2_tod=nil;
	[en_aa1 release];en_aa1=nil; [en_aa2 release]; en_aa2=nil;
	[send_tweet release]; send_tweet=nil; [open_account_btn release]; open_account_btn=nil;
	[arm_disarm release]; arm_disarm=nil;
	[sensitivity2 release]; sensitivity2=nil;
}
-(void)dealloc{
	self.loginEmail=nil;
	self.navigationItem.rightBarButtonItem=nil;
	[day_of_week release];
	[responsiveness_choices release];
	[trigger_delay_choices release];
	[auto_reset_choices release];
	[pir_reset_choices release];
	[self releaseViews];
	self.config=nil;
	[tod_f release];
	self.rnc_open=nil; self.rnc_detected=nil;
	[super dealloc];
}
-(void)saveToConfig{
	NSMutableDictionary* c = self.config;
	
	c.sensitivity = sensitivity.slider.value;
	
	c.silent_arming = silent_arm.toggle.on;
	
	if(_isAccel)c.sensitivity2 = sensitivity2.slider.value;
	
	c.door_mode_angle=threshold_angle.slider.value;
	c.email = email.textField.text;
	
	c.door_mode=door_mode.toggle.on;
	c.hmc_timeout_mode = hmc_timeout_mode.toggle.on;
	c.send_email=send_email.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	
	c.send_email_on_close=send_email_close.toggle.on;
	c.beep_pc=beep_pc.toggle.on;
	c.beep_pc_tts= use_speech.toggle.on;
	c.beep_pc_loop = beep_pc_loop.toggle.on;
	c.beep_pc_vibrate = vibrate.toggle.on;
//	c.beep_tag = beep_tag.toggle.on;
	c.aa1_en = en_aa1.toggle.on;
	c.aa2_en=en_aa2.toggle.on;
	c.tzo = (int)-[[NSTimeZone localTimeZone] secondsFromGMT]/60;
}
-(void)navbarSave{
	[self saveToConfig];
	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self ];
}
+(NSUInteger)limitIndex:(int)i to:(NSUInteger)upper{
	if(i<0)return 0;
	else if(i>=upper)return upper-1;
	else return i;
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	
	silent_arm.toggleOn = c.silent_arming;
	[sensitivity setVal:(float)c.sensitivity];
	[threshold_angle setVal:(float)c.door_mode_angle];
	if(_isAccel){
		responsiveness.textField.text = [responsiveness_choices_accel objectAtIndex:[MSOptionsViewController limitIndex:(30-c.interval)/2 to:responsiveness_choices_accel.count]];
		[sensitivity2 setVal:(float)c.sensitivity2];
		responsiveness.label.text = NSLocalizedString(@"Duration for Carried Away",nil);
	}else{
		responsiveness.textField.text = [responsiveness_choices objectAtIndex:c.interval-1];
		responsiveness.label.text = NSLocalizedString(@"Sampling Frequency",nil);
	}
	trigger_delay.textLabel.text = [trigger_delay_choices objectAtIndex:c.door_mode_delay_index];
	auto_reset_delay.textLabel.text = (_isPir||c.hmc_timeout_mode)?[pir_reset_choices objectAtIndex:c.pir_reset_delay_index]:
							[auto_reset_choices objectAtIndex:c.auto_reset_delay_index];
	email.textField.text = c.email.isEmpty ?c.loginEmail:c.email;
	door_mode.toggleOn = c.door_mode; hmc_timeout_mode.toggleOn=c.hmc_timeout_mode;
	send_email.toggleOn=c.send_email; send_email_close.toggleOn=c.send_email_on_close;
	beep_pc.toggleOn = c.beep_pc; use_speech.toggleOn=c.beep_pc_tts;
	beep_pc_loop.toggleOn=c.beep_pc_loop;
	vibrate.toggleOn = c.beep_pc_vibrate; //beep_tag.toggleOn=c.beep_tag;
	
	en_aa1.toggleOn=c.aa1_en;
	en_aa2.toggleOn = c.aa2_en;
	
	
	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	apns_pause.textField.text = apns_pause_choices[ c.apns_pause_index ];

	aa1_tod.textField.text =[tod_f stringFromDate:[MSOptionsViewController tod2NSDate:c.aa1_tod]]; //[tod_choices objectAtIndex:[tod_min_utc indexOfObject:[NSNumber numberWithInt:c.aa1_tod]]];
	aa2_tod.textField.text = [tod_f stringFromDate:[MSOptionsViewController tod2NSDate:c.aa2_tod]]; 
	ada1_tod.textField.text = [tod_f stringFromDate:[MSOptionsViewController tod2NSDate:c.ada1_tod]];
	ada2_tod.textField.text = [tod_f stringFromDate:[MSOptionsViewController tod2NSDate:c.ada2_tod]];
	
	[super setConfig:c];
}
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	sensitivity = [IASKPSSliderSpecifierViewCell newWithTitle:_isAccel?NSLocalizedString(@"Sensitivity for Moved",nil):NSLocalizedString(@"Sensitivity",nil) Min:0 Max:100 Step:1 Unit:@"%" delegate:self];
	threshold_angle = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Threshold Angle",nil) Min:5 Max:90 Step:0.5 Unit:@"°" delegate:self];

	responsiveness = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:_isAccel?NSLocalizedString(@"Duration for Carried Away",nil): NSLocalizedString(@"Sampling Frequency",nil)];
	sensitivity2=[IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Sensitivity for Carried Away",nil) Min:0 Max:100 Step:1 Unit:@"%" delegate:self];
	
	trigger_delay = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	trigger_delay.textLabel.font = [UIFont systemFontOfSize:17];
	trigger_delay.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	auto_reset_delay = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	auto_reset_delay.textLabel.font = [UIFont systemFontOfSize:17];
	auto_reset_delay.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	email = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"\tto:" delegate:self];
	door_mode = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Door/Gate Mode",nil) helpText:NSLocalizedString(@"Door/gate mode calculates the angle between current orientation and the orientation when tag was armed. If it becomes larger than a threshold angle, tag is reported open, if it becomes smaller, tag is reported closed.",nil) delegate:self];
	hmc_timeout_mode =[IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Notify @Motion Start/Stop",nil) helpText:NSLocalizedString(@"If enabled, tag will only transmit moved event once at start of motion, and if no motion is detected for longer than specified timeout, transmit a timed out event.",nil) delegate:self];

	//arm_cell = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:@"Arm" delegate:self];

	send_email = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"The tag will notify you by email when the it is moved, opened, closed, infra-red sensor detected motion or timed out.",nil) delegate:self];

	send_tweet =[IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Tweet",nil) helpText:NSLocalizedString(@"The tag will post tweets on behalf of you of motion sensor events as they occur.",nil) delegate:self];
	open_account_btn = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting...",nil)];
	
	send_email_close = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Notify When Closed/Timed-Out",nil) helpText:NSLocalizedString(@"Notify using selected methods when door is closed and when motion sensor has timed out.",nil) delegate:self];
	beep_pc = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notifications",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' upon motion sensor events.",nil) delegate:self];
	use_speech = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	beep_pc_loop = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tRing Until Reset or Closed",nil) helpText:NSLocalizedString(@"In door/gate mode, keep beeping until door/gate is closed. In motion detection mode, keep beeping until reset or time out.",nil) delegate:self];
	vibrate = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-Sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil)  delegate:self];
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	apns_pause =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPause Action Effective For: ",nil)];
	
//	beep_tag = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:@"Make Tag Beep" helpText:@"Automatically trigger tag to beep upon the moved or opened event." delegate:self];
	
	en_aa1 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Enable Schedule 1",nil) helpText:nil delegate:self];
	en_aa2 = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Enable Schedule 2",nil) helpText:nil delegate:self];
	
	arm_disarm = [IASKPSToggleSwitchSpecifierViewCell newLoadingWithTitle:NSLocalizedString(@"Arm/Disarm",nil) Progress:NSLocalizedString(@"Configuring...",nil) helpText:NSLocalizedString(@"Arm or disarm the motion sensor. Disarm the motion sensor when not needed to significantly increase battery life. You can also tap the 'keypad' icon on the toolbar to arm/disarm motion sensors.",nil) delegate:self];
	silent_arm = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Silent Arming/Disarming",nil) helpText:NSLocalizedString(@"Do not emit sound form tag when arming/disarming manually or by schedule.",nil) delegate:self];
	
	aa1_tod = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Arm At: ",nil)];
	aa2_tod = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Arm At: ",nil)];
	ada1_tod = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Disarm At: ",nil)];
	ada2_tod = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Disarm At: ",nil)];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO; 
	
	rn_open =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify Open:",nil)];  rn_open.textField.text = rnc_timespan_choices[0];
	rn_detected =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify Motion Detect:",nil)]; rn_detected.textField.text = rnc_timespan_choices[0];
	
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

// [triggering condition (sensitivity, responsiveness, doormode_on_off, threshold_angle_slider)]
// [when moved/opened (when tag movement is detected/when has been opened for x, send email, address, also, ringpc, usespeech, keep, vib, tagbeep)  
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return (_isReedPir?3:4 ) + (_armDisarmState!=ArmDisarmSwitchStateHidden?1:0);
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(_armDisarmState!=ArmDisarmSwitchStateHidden){
		if(section==0)return nil;
		section--;
	}
	if(_isReedPir)section++;
	if(section==0)return NSLocalizedString(@"Triggering Conditions:",nil);
	else if(section==1){
		//if(door_mode.toggle.on)return @"When Opened:";	
		//else return @"When Moved:";
		return NSLocalizedString(@"When Moved/Opened:",nil);
	}
	else if(section==2)return NSLocalizedString(@"Arm/Disarm Schedule 1:",nil);
	else return NSLocalizedString(@"Arm/Disarm Schedule 2:",nil);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(_armDisarmState!=ArmDisarmSwitchStateHidden){
		if(section==0)return _isPir8F? 2: (_isReedPir?1:2);
		section--;
	}
	if(_isReedPir)section++;
	if(section==0 && _isALS)
		return 2;		// hmc timeout and sampling freq
	else if(section==0 && !_isAccel)
		return (door_mode.toggleOn?4:3) + (!door_mode.toggleOn&&_isHmcTimeout?1:0);
	else if(section==0 && _isAccel)
		return (door_mode.toggleOn?2:5);
	else if(section==1)return (_isReedPir?1:2)+(send_email.toggleOn?2:1)+(send_tweet.toggleOn?2:1)+1+(beep_pc.toggleOn?6:1);
	else if(section==2)return en_aa1.toggleOn?10:1;
	else return en_aa2.toggleOn?10:1;
}
-(void) setArmDisarmState:(ArmDisarmSwitchState)armDisarmState{
	_armDisarmState=armDisarmState;
	arm_disarm.toggleOn = (armDisarmState==ArmDisarmSwitchStateOn);
	arm_disarm.toggleState.text = arm_disarm.toggle.on?NSLocalizedString(@"On",nil):NSLocalizedString(@"Off",nil);
}
-(void) editedTableViewCell:(UITableViewCell*)cell{

	int actionSection = (_isReedPir?0:1) + (_armDisarmState==ArmDisarmSwitchStateHidden?0:1);
	
	_modified=YES;
	if(cell == arm_disarm){
		[arm_disarm updateToggleOn];
		if(arm_disarm.toggle.on){
			[self saveToConfig];
			[self.delegate armBtnPressed:arm_disarm withConfig:self.config];
		}else{
			[self.delegate disarmBtnPressed:arm_disarm];
		}
	}
	else if(cell == send_email)
	{
		NSLog(@"OptionsViewController editedTableViewCell send_email called");
		[self.tableView beginUpdates];
		[send_email updateToggleOn];
		if(send_email.toggle.on){
			if(email.textField.text.length==0)email.textField.text = self.loginEmail;
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:2 inSection:actionSection]/*, [NSIndexPath indexPathForRow:3 inSection:2]*/, nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:2 inSection:actionSection]/*, [NSIndexPath indexPathForRow:3 inSection:2]*/, nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}else if(cell==send_tweet){
		NSLog(@"OptionsViewController editedTableViewCell send_tweet called");
		[self.tableView beginUpdates];
		NSIndexPath *accbtnip = [NSIndexPath indexPathForRow:send_email.toggle.on?4:3 inSection:actionSection];
		[send_tweet updateToggleOn];
		if(send_tweet.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:accbtnip, nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:accbtnip, nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}else if(cell == door_mode){
		NSLog(@"OptionsViewController editedTableViewCell door_mode called");

		[self.tableView beginUpdates];
		[door_mode updateToggleOn];
		if(_isAccel){
			if(door_mode.toggle.on){
				[self.tableView reloadRowsAtIndexPaths:
				 @[[NSIndexPath indexPathForRow:1 inSection:actionSection-1]] withRowAnimation:UITableViewRowAnimationFade];
				
				[self.tableView deleteRowsAtIndexPaths:
				 @[[NSIndexPath indexPathForRow:2 inSection:actionSection-1],[NSIndexPath indexPathForRow:3 inSection:actionSection-1],[NSIndexPath indexPathForRow:4 inSection:actionSection-1]] withRowAnimation:UITableViewRowAnimationFade];
			}else{
				[self.tableView reloadRowsAtIndexPaths:
				 @[[NSIndexPath indexPathForRow:1 inSection:actionSection-1]] withRowAnimation:UITableViewRowAnimationFade];
				
				[self.tableView insertRowsAtIndexPaths:
				 @[[NSIndexPath indexPathForRow:2 inSection:actionSection-1],[NSIndexPath indexPathForRow:3 inSection:actionSection-1],[NSIndexPath indexPathForRow:4 inSection:actionSection-1]] withRowAnimation:UITableViewRowAnimationFade];
			}
		}else{
			if(door_mode.toggle.on){
				if(_isHmcTimeout){
					[self.tableView reloadRowsAtIndexPaths:
					 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:actionSection-1], nil] withRowAnimation:UITableViewRowAnimationFade];
				}else{
					[self.tableView insertRowsAtIndexPaths:
					 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:actionSection-1], nil] withRowAnimation:UITableViewRowAnimationFade];
				}
			}else{
				if(_isHmcTimeout){
					[self.tableView reloadRowsAtIndexPaths:
					 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:actionSection-1], nil] withRowAnimation:UITableViewRowAnimationFade];
				}else{
					[self.tableView deleteRowsAtIndexPaths:
					 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:actionSection-1], nil] withRowAnimation:UITableViewRowAnimationFade];
				}
			}
		}
		[self.tableView reloadRowsAtIndexPaths:
		 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:actionSection], nil] withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
		
		//[door_mode updateToggleOn];
		//[self.tableView reloadData];
		
	}else if(cell==hmc_timeout_mode){
		NSLog(@"OptionsViewController editedTableViewCell hmc_timeout_mode called");
		[hmc_timeout_mode updateToggleOn];
		if(hmc_timeout_mode.toggle.on){
			auto_reset_delay.textLabel.text = [pir_reset_choices
											   objectAtIndex:self.config.pir_reset_delay_index];
		}else{
			auto_reset_delay.textLabel.text = [auto_reset_choices
											   objectAtIndex:self.config.auto_reset_delay_index];
		}
		[self.tableView reloadData];
//		[self.tableView reloadRowsAtIndexPaths:
	//	 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:actionSection], nil] withRowAnimation:UITableViewRowAnimationFade];
	}
	else if(cell==beep_pc){
		NSLog(@"OptionsViewController editedTableViewCell beep_pc called");
		int base = (send_email.toggle.on?5:4)+(send_tweet.toggle.on?2:1);
		[self.tableView beginUpdates];
		[beep_pc updateToggleOn];
		NSArray* ips = [NSArray arrayWithObjects:
						[NSIndexPath indexPathForRow:base inSection:actionSection],
						[NSIndexPath indexPathForRow:base+1 inSection:actionSection],
						[NSIndexPath indexPathForRow:base+2 inSection:actionSection],
						[NSIndexPath indexPathForRow:base+3 inSection:actionSection],
						[NSIndexPath indexPathForRow:base+4 inSection:actionSection],
						nil];
		if(beep_pc.toggle.on){	
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}else if(cell==en_aa1){
		NSLog(@"OptionsViewController editedTableViewCell en_aa1 called");
		[self.tableView beginUpdates];
		[en_aa1 updateToggleOn];
		NSMutableArray* ips = [[[NSMutableArray alloc]initWithCapacity:9] autorelease];
		for(int i=1;i<10;i++){
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:actionSection+1]];
		}
		if(en_aa1.toggle.on){
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];			
		}
		[self.tableView endUpdates];
	}
	else if(cell==en_aa2){
		NSLog(@"OptionsViewController editedTableViewCell en_aa2 called");
		[self.tableView beginUpdates];
		[en_aa2 updateToggleOn];
		NSMutableArray* ips = [[[NSMutableArray alloc]initWithCapacity:9] autorelease];
		for(int i=1;i<10;i++){
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:actionSection+2]];
		}
		if(en_aa2.toggle.on){
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];			
		}
		[self.tableView endUpdates];
	}
	else
		NSLog(@"OptionsViewController editedTableViewCell other called");

	[self scheduleRecalculatePopoverSize];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSSliderSpecifierViewCell	class]])
		return 86;
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}
-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	if(_isALS && section==1)return NSLocalizedString(@"Motion light sensor detects when there is sudden change in brightness caused by moving the tag or changing its surroundings abruptly, such as picking up the tag by hand or opening a drawer containing the tag.",nil);
	else return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	int section = (int)(_isReedPir?  ip.section+1:ip.section);

	if(_armDisarmState!=ArmDisarmSwitchStateHidden){
		if(ip.section==0){
			if(_isPir8F && ip.row==1){
				return sensitivity;
			}else if(ip.row==1)
				return silent_arm;
			else
				return arm_disarm;
		}
		section--;
	}

	if(section==0){
		NSArray* cells;
		if(_isALS){
			cells = @[responsiveness, hmc_timeout_mode];
		}
		else if(_isAccel){
			if(door_mode.toggleOn)cells = @[door_mode, threshold_angle];
			else cells = @[door_mode, sensitivity, sensitivity2, responsiveness, hmc_timeout_mode];
		}else{
			if(door_mode.toggleOn)cells = @[sensitivity, responsiveness, door_mode, threshold_angle];
			else if(_isHmcTimeout)cells = @[sensitivity, responsiveness, door_mode, hmc_timeout_mode];
			else if(!_isPir) cells=@[sensitivity, responsiveness, door_mode];
			else cells = @[sensitivity];
		}
		return [cells objectAtIndex:ip.row];
	}else if(section==1){
		NSMutableArray* cells = [NSMutableArray arrayWithCapacity:9];
		if(door_mode.toggleOn || (_isReedPir&&!_isPir))[cells addObject:trigger_delay];
		else [cells addObject:auto_reset_delay];
		[cells addObject:send_email];
		if(send_email.toggleOn){
			[cells addObject:email]; 
		}
		[cells addObject:send_tweet];
		if(send_tweet.toggleOn){
			[cells addObject:open_account_btn];
			//NSLog(@"send_tweet on");
		}else{
			//NSLog(@"send_tweet off");
		}
		[cells addObject:send_email_close];
		[cells addObject:beep_pc];
		if(beep_pc.toggleOn){
			[cells addObject:use_speech];
			[cells addObject:apns_pause];
			[cells addObject:apns_sound];
			[cells addObject:vibrate];
			[cells addObject:beep_pc_loop];
		}
//		[cells addObject:beep_tag];
		[cells addObject: (_isPir || hmc_timeout_mode.toggle.on) ? rn_detected : rn_open ];
		if(ip.row<cells.count)
			return [cells objectAtIndex:ip.row];
		else
			return nil;
	}
	else if(section==2){
		if(ip.row==0)return en_aa1;
		else if(ip.row==1)return ada1_tod;
		else if(ip.row==2)return aa1_tod;
		else{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DOW"];
			
			if (!cell) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DOW"] autorelease];   
				NSLog(@"Created DOW");
			}
			cell.textLabel.text = [day_of_week objectAtIndex:ip.row-3];
			NSLog(@"Setting DOW cell %@",cell.textLabel.text);
			cell.accessoryType = self.config.aa1_dow&(1<<(ip.row-3)) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}
	else if(section==3){
		if(ip.row==0)return en_aa2;
		else if(ip.row==1)return ada2_tod;
		else if(ip.row==2)return aa2_tod;
		else{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DOW"];
			if (!cell) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DOW"] autorelease];   
			}
			cell.textLabel.text = [day_of_week objectAtIndex:ip.row-3];
			cell.accessoryType = self.config.aa2_dow&(1<<(ip.row-3)) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			return cell;
		}
	}
	return nil;
}

+(NSDate *)roundDateTo15Minutes:(NSDate *)mydate{
	NSDateComponents *time = [[NSCalendar currentCalendar]
							  components:NSHourCalendarUnit | NSMinuteCalendarUnit
							  fromDate:mydate];
	NSInteger minutes = [time minute];
	int remain = minutes % 15;
	// if less then 3 then round down
	if (remain<7){
		mydate = [mydate dateByAddingTimeInterval:-60*(remain)];
	}else{
		mydate = [mydate dateByAddingTimeInterval:60*(15-remain)];
	}
	return mydate;
}

#import "ActionSheetDatePicker.h"

-(void)setRnc_detected:(NSMutableDictionary *)rnc_detected{
	[_rnc_detected autorelease];
	_rnc_detected = [rnc_detected retain];
	int selected=0;
	if(self.rnc_detected){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_detected.intervalSec){
				selected=i; break;
			}
	}
	rn_detected.textField.text = rnc_timespan_choices[selected];
}
-(void)setRnc_open:(NSMutableDictionary *)rnc_open{
	[_rnc_open autorelease];
	_rnc_open = [rnc_open retain];
	int selected=0;
	if(self.rnc_open){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_open.intervalSec){
				selected=i; break;
			}
	}
	rn_open.textField.text = rnc_timespan_choices[selected];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
		[tableView beginUpdates];
		[tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
		return;
	}

	OptionPicker *picker=nil;
	NSMutableDictionary* c = self.config;
	
	int section = (int)(_isReedPir?ip.section+1:ip.section);
	if(_armDisarmState!=ArmDisarmSwitchStateHidden){
		section--;
	}

	if(cell== responsiveness){
		if(_isAccel){
			picker = [[[OptionPicker alloc]initWithOptions:responsiveness_choices_accel Selected: [MSOptionsViewController limitIndex:(30-c.interval)/2 to:responsiveness_choices_accel.count]
													  Done:^(NSInteger selected, BOOL now){
														  responsiveness.textField.text = [responsiveness_choices_accel objectAtIndex:[MSOptionsViewController limitIndex:(int)selected
																																									   to:responsiveness_choices_accel.count]];
														  self.config.interval=30-(int)selected*2;
													  } helpText:NSLocalizedString(@"The minimum amount of time tag has to move for carried away event to trigger.",nil)] autorelease];
			
		}else{
			picker = [[[OptionPicker alloc]initWithOptions:responsiveness_choices Selected:[c interval]-1
													  Done:^(NSInteger selected, BOOL now){
														  responsiveness.textField.text = [responsiveness_choices objectAtIndex:selected];
														  self.config.interval=(int)selected+1;
													  } helpText:NSLocalizedString(@"Use higher sampling frequency to detect cases where door opens then quickly closes (or in motion detection mode, cases when tag is moved then put back to original position quickly). Use lower sampling frequency for longer battery life at the expense of longer delay in notification.",nil)] autorelease];
		}
	}
	else if(section==1){
		if(ip.row == 0){
			if(door_mode.toggle.on || (_isReedPir & !_isPir)){
				
				picker = [[[OptionPicker alloc]initWithOptions:trigger_delay_choices Selected:[c door_mode_delay_index]
														  Done:^(NSInteger selected, BOOL now){
															  trigger_delay.textLabel.text = [trigger_delay_choices objectAtIndex:selected];
															  c.door_mode_delay=trigger_delay_choices_val[selected];
														  } helpText:NSLocalizedString(@"Cancel notification if door is opened but closed within specified time.",nil) ] autorelease];

			}else if(_isPir || hmc_timeout_mode.toggle.on){
				picker = [[[OptionPicker alloc]initWithOptions:pir_reset_choices Selected:[c pir_reset_delay_index]
														  Done:^(NSInteger selected, BOOL now){
															  auto_reset_delay.textLabel.text = [pir_reset_choices
																								 objectAtIndex:selected];
															  c.auto_reset_delay = pir_reset_choices_val[selected];
														  } helpText:NSLocalizedString(@"If no motion is detected after specified time, the sensor enters into timed out state and a notifcaition is sent.",nil)] autorelease];
			}else{
				picker = [[[OptionPicker alloc]initWithOptions:auto_reset_choices Selected:[c auto_reset_delay_index]
														  Done:^(NSInteger selected, BOOL now){
															  auto_reset_delay.textLabel.text = [auto_reset_choices
																								 objectAtIndex:selected];
															  c.auto_reset_delay = auto_reset_choices_val[selected];
														  } helpText:NSLocalizedString(@"After motion is detected, you can automatically reset the sensor to armed state after this delay.",nil) ] autorelease];
			}
			
		}else if(send_tweet.toggle.on && ((send_email.toggle.on && ip.row==4) || (!send_email.toggle.on && ip.row==3))){
			[self.delegate optionViewTwitterLoginBtnClicked:open_account_btn];
		}else{
			//UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
			if(cell == apns_sound){

				picker = [[[OptionPicker alloc]initWithOptions:
						   [NSArray arrayWithObjects:apns_sound_choices count:sizeof(apns_sound_choices)/sizeof(NSString*)]
													  Selected:c.apns_sound_index
														  Done:^(NSInteger selected, BOOL now){
															  apns_sound.textField.text = apns_sound_choices[selected];
															  c.apnsSound =apns_sound_choices[selected];
															  [super playAiff:selected];
														  } ] autorelease];
			}else if(cell == apns_pause){

				picker = [[[OptionPicker alloc]initWithOptions:
						   [NSArray arrayWithObjects:apns_pause_choices count:sizeof(apns_pause_choices)/sizeof(NSString*)]
													  Selected:c.apns_pause_index
														  Done:^(NSInteger selected, BOOL now){
															  apns_pause.textField.text = apns_pause_choices[selected];
															  c.apns_pause =apns_pause_values[selected];
														  } helpText:NSLocalizedString(@"Swipe left on a notification of motion sensor events such as 'Opened' or 'Detected' to see 'Pause' and 'Disarm' button. 'Pause' to temporarily stop receiving the notification but still keep populating Event History. 'Disarm' will temporarily disarm the motion sensor. Here you can choose the time after which to automatically resume receiving events or re-arm the sensor.",nil)] autorelease];
			}
			else if(cell==rn_detected){
				int selected=0;
				if(self.rnc_detected){
					for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
						if(rnc_timespan_values[i]== self.rnc_detected.intervalSec){
							selected=i; break;
						}
				}
				picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
													  Selected:selected
														  Done:^(NSInteger selected_new, BOOL now){
															  rn_detected.textField.text = rnc_timespan_choices[selected_new];
															  
															  if(_rnc_detected==nil && selected_new>0){
																  _rnc_detected=[@{@"eventType":@5} mutableCopy];
															  }
															  self.rnc_detected.intervalSec = rnc_timespan_values[selected_new];
															  if(self.rnc_detected && selected_new!=selected){
																  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																	  if(obj==self.rnc_detected)return;
																  
																  [self.updatedRepeatNotifyConfigs addObject:self.rnc_detected];
															  }
														  } helpText:NSLocalizedString(@"Choose to get notified just once or repeatedly when motion is detected until no motion is detected for a time out period (timed out event). ",nil) ] autorelease];
			}
			else if(cell==rn_open){
				int selected=0;
				if(self.rnc_open){
					for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
						if(rnc_timespan_values[i]== self.rnc_open.intervalSec){
							selected=i; break;
						}
				}
				picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
													  Selected:selected
														  Done:^(NSInteger selected_new, BOOL now){
															  rn_open.textField.text = rnc_timespan_choices[selected_new];
															  
															  if(_rnc_open==nil && selected_new>0){
																  _rnc_open=[@{@"eventType":@3} mutableCopy];
															  }
															  self.rnc_open.intervalSec = rnc_timespan_values[selected_new];
															  if(self.rnc_open && selected_new!=selected){
																  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																	  if(obj==self.rnc_open)return;
																  
																  [self.updatedRepeatNotifyConfigs addObject:self.rnc_open];
															  }
															  
														  } helpText:NSLocalizedString(@"Choose to get notified just once or repeatedly when door is open until closed. ",nil)] autorelease];
			}

		}
	}else if(section==2){
		//UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
		if(ip.row==1){
			ActionSheetDatePicker *datePicker = [[[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeTime selectedDate:[MSOptionsViewController tod2NSDate:c.ada1_tod]
																					doneBlock:^(ActionSheetDatePicker* picker, NSDate* date, id origin){
				ada1_tod.textField.text = [tod_f stringFromDate:date];
				c.ada1_tod = [MSOptionsViewController NSDate2tod:date];
			} cancelBlock:nil origin:cell] autorelease];
			
			[datePicker addCustomButtonWithTitle:NSLocalizedString(@"Now",nil) value:[MSOptionsViewController roundDateTo15Minutes:[NSDate date]]];
			//self.actionSheetPicker.hideCancel = YES;
			[datePicker showActionSheetPicker];
		}else if(ip.row==2){
			ActionSheetDatePicker *datePicker = [[[ActionSheetDatePicker alloc] initWithTitle:@"" 
																			   datePickerMode:UIDatePickerModeTime selectedDate:[MSOptionsViewController tod2NSDate:c.aa1_tod]
																						 doneBlock:^(ActionSheetDatePicker* picker, NSDate* date, id origin){
																							 aa1_tod.textField.text = [tod_f stringFromDate:date];
																							 c.aa1_tod = [MSOptionsViewController NSDate2tod:date];
																						 } cancelBlock:nil origin:cell] autorelease];
			[datePicker addCustomButtonWithTitle:NSLocalizedString(@"Now",nil) value:[MSOptionsViewController roundDateTo15Minutes:[NSDate date]]];
			[datePicker showActionSheetPicker];
		}else{
			[tableView deselectRowAtIndexPath:ip animated:YES];
			if(c.aa1_dow & (1<<(ip.row-3))){
				c.aa1_dow &= ~(1<<(ip.row-3));
			}else{
				c.aa1_dow |= (1<<(ip.row-3));
				c.aa2_dow &= ~(1<<(ip.row-3));				
			}
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:ip, nil] withRowAnimation:UITableViewRowAnimationFade];
			if(en_aa2.toggle.on){
				[self.tableView reloadRowsAtIndexPaths:
				 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:ip.row inSection:ip.section+1], nil] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	}else if(section==3){
		//UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
		if(ip.row==1){
			ActionSheetDatePicker *datePicker = [[[ActionSheetDatePicker alloc] initWithTitle:@"" 
																			   datePickerMode:UIDatePickerModeTime selectedDate:[MSOptionsViewController tod2NSDate:c.ada2_tod]
																					doneBlock:^(ActionSheetDatePicker* picker, NSDate* date, id origin){
																							 ada2_tod.textField.text = [tod_f stringFromDate:date];
																							 c.ada2_tod = [MSOptionsViewController NSDate2tod:date];
																						 } cancelBlock:nil origin:cell] autorelease];
			[datePicker addCustomButtonWithTitle:NSLocalizedString(@"Now",nil) value:[MSOptionsViewController roundDateTo15Minutes:[NSDate date]]];
			[datePicker showActionSheetPicker];
		}else if(ip.row==2){
			ActionSheetDatePicker *datePicker = [[[ActionSheetDatePicker alloc] initWithTitle:@"" 
																			   datePickerMode:UIDatePickerModeTime selectedDate:[MSOptionsViewController tod2NSDate:c.aa2_tod]
																					doneBlock:^(ActionSheetDatePicker* picker, NSDate* date, id origin){
																							 aa2_tod.textField.text = [tod_f stringFromDate:date];
																							 c.aa2_tod = [MSOptionsViewController NSDate2tod:date];
																						 } cancelBlock:nil origin:cell] autorelease];
			[datePicker addCustomButtonWithTitle:NSLocalizedString(@"Now",nil) value:[MSOptionsViewController roundDateTo15Minutes:[NSDate date]]];
			[datePicker showActionSheetPicker];
		}else{
			[tableView deselectRowAtIndexPath:ip animated:YES];
			if(c.aa2_dow & (1<<(ip.row-3))){
				c.aa2_dow &= ~(1<<(ip.row-3));
			}else{
				c.aa2_dow |= (1<<(ip.row-3));
				c.aa1_dow &= ~(1<<(ip.row-3));				
			}
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
			if(en_aa1.toggle.on){
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:ip.row inSection:ip.section-1], nil] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	}
	[super presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:ip]];
}

@end



@implementation OorOptionsViewController
@synthesize modified=_modified;
@synthesize loginEmail=_loginEmail;
- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		_modified=NO;
    }
    return self;
}
-(void)releaseViews{
	[email_oor release]; email_oor=nil;
	[send_email_oor release]; send_email_oor=nil;
	[send_tweet release]; send_tweet=nil;
	[tweetLogin release]; tweetLogin=nil;
	[beep_pc_oor release]; beep_pc_oor=nil; [use_speech_oor release]; use_speech_oor=nil; [vibrate_oor release]; vibrate_oor=nil;
	[apns_sound release]; apns_sound=nil; [oor_grace release]; oor_grace=nil;
}
-(void)dealloc{
	self.loginEmail=nil;
	[self releaseViews];
	self.config=nil;
	[super dealloc];
}

-(void)navbarSave{

	NSMutableDictionary* c = self.config;
	c.send_email_oor = send_email_oor.toggle.on;
	c.email_oor=email_oor.textField.text;
	c.beep_pc_oor = beep_pc_oor.toggle.on;
	c.beep_pc_tts_oor = use_speech_oor.toggle.on;
	c.beep_pc_vibrate_oor = vibrate_oor.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	
	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self ];
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];	
	send_email_oor.toggleOn=c.send_email_oor;
	send_tweet.toggleOn=c.send_tweet;
	email_oor.textField.text = c.email_oor.isEmpty?@"":c.email_oor;
	beep_pc_oor.toggleOn= c.beep_pc_oor;
	use_speech_oor.toggleOn=c.beep_pc_tts_oor;
	vibrate_oor.toggleOn=c.beep_pc_vibrate_oor;

	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	[super setConfig:c];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
		
	email_oor =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"\tto:" delegate:self];
	send_email_oor = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"Get notified by email when the tag is out of range or back in range.",nil) delegate:self];
	send_tweet = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"Automatically post a tweet when the tag is out of range or back in range.",nil) delegate:self];
	tweetLogin = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting...",nil)];
	beep_pc_oor = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Receive push notifications on iOS/Android devices chosen at 'Phone Options' when the tag is out of range and when it is back in range.",nil) delegate:self];
	use_speech_oor = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	vibrate_oor = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil) delegate:self];
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	oor_grace = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Grace Period:",nil)];
	
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
	return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==1)
		return NSLocalizedString(@"When Out of Range:",nil);
	else
		return NSLocalizedString(@"Notification Grace Period",nil);
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)
		return 1;
	else
		return (send_email_oor.toggleOn?2:1)+(send_tweet.toggleOn?2:1)+(beep_pc_oor.toggleOn?4:1);
}
-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;

	if(cell == send_email_oor){
		[self.tableView beginUpdates];
		[send_email_oor updateToggleOn];
		if(send_email_oor.toggle.on){
			if(email_oor.textField.text.length==0)email_oor.textField.text = self.loginEmail;
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:1], nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:1], nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}
	else if(cell==send_tweet){
		int base = send_email_oor.toggle.on?3:2;
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
	}
	else if(cell==beep_pc_oor){
		int base = (send_email_oor.toggle.on?3:2) + (send_tweet.toggle.on?2:1);
		[self.tableView beginUpdates];
		[beep_pc_oor updateToggleOn];
		if(beep_pc_oor.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],
			  [NSIndexPath indexPathForRow:base+1 inSection:1],[NSIndexPath indexPathForRow:base+2 inSection:1],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:1],
			  [NSIndexPath indexPathForRow:base+1 inSection:1],[NSIndexPath indexPathForRow:base+2 inSection:1], nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}

	[self scheduleRecalculatePopoverSize];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
		[tableView beginUpdates];
		[tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}else
	if(cell == apns_sound){
		OptionPicker *picker=nil;
		picker = [[[OptionPicker alloc]initWithOptions:
				   [NSArray arrayWithObjects:apns_sound_choices count:sizeof(apns_sound_choices)/sizeof(NSString*)]
											  Selected:self.config.apns_sound_index
												  Done:^(NSInteger selected, BOOL now){
													  apns_sound.textField.text = apns_sound_choices[selected];
													  self.config.apnsSound =apns_sound_choices[selected];
													  [super playAiff:selected];
												  } ] autorelease];
		[super presentPicker:picker fromCell:apns_sound];
		
	}else if(cell==oor_grace){
		OptionPicker *picker=nil;
		picker = [[[OptionPicker alloc]initWithOptions:
				   [NSArray arrayWithObjects:oor_grace_choices count:sizeof(oor_grace_choices)/sizeof(NSString*)]
											  Selected:_oor_grace_selected_index
												  Done:^(NSInteger selected, BOOL now){
													  _oor_grace_selected_index=(int)selected;
													  oor_grace.textField.text = oor_grace_choices[_oor_grace_selected_index];
												  } helpText:NSLocalizedString(@"Grace period for notifying out of range. If tag comes back in range within this time no out of range event will be generated.",nil) ] autorelease];
		[super presentPicker:picker fromCell:oor_grace];		
	}
	else	if(cell==tweetLogin)
		[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
}
-(void)setOorGrace:(int)oorGrace{
	_oor_grace_selected_index=2;
	for(int i=0;i<sizeof(oor_grace_values)/sizeof(int);i++)
		if(oor_grace_values[i]== oorGrace)_oor_grace_selected_index=i;
	oor_grace.textField.text = oor_grace_choices[_oor_grace_selected_index];
}
-(int)oorGrace{
	return oor_grace_values[_oor_grace_selected_index];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.section==0)return oor_grace;
	else{
		NSMutableArray* cells = [NSMutableArray arrayWithCapacity:5];
		[cells addObject:send_email_oor];
		if(send_email_oor.toggleOn){
			[cells addObject:email_oor];
		}
		[cells addObject:send_tweet];
		if(send_tweet.toggleOn)
			[cells addObject:tweetLogin];
		[cells addObject:beep_pc_oor];
		if(beep_pc_oor.toggleOn){
			[cells addObject:use_speech_oor];
			[cells addObject:apns_sound];
			[cells addObject:vibrate_oor];
		}
		return [cells objectAtIndex:ip.row];
	}
}
@end


@implementation LbOptionsViewController
@synthesize modified=_modified;
@synthesize loginEmail=_loginEmail;
- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		_modified=NO;
		notify_every_choices = [[NSArray
								   arrayWithObjects:NSLocalizedString(@"Two hour",nil), NSLocalizedString(@"Six hour",nil), NSLocalizedString(@"Day",nil), NSLocalizedString(@"Three Days",nil), NSLocalizedString(@"Week",nil), nil] retain];
    }
    return self;
}
-(void)releaseViews{
	[email release]; email=nil;
	[send_email release]; send_email=nil;
	[send_tweet release]; send_tweet=nil;
	[tweetLogin release]; tweetLogin=nil;
	
	[beep_pc release]; beep_pc=nil; [use_speech release]; use_speech=nil; [vibrate release]; vibrate=nil;
	[apns_sound release]; apns_sound=nil;
	[enabled release]; enabled=nil; [threshold release]; threshold=nil; [notify_every release]; notify_every=nil;
}
-(void)dealloc{
	self.loginEmail=nil;
	[self releaseViews];
	self.config=nil;
	[notify_every_choices release];
	[super dealloc];
}

-(void)navbarSave{
	
	NSMutableDictionary* c = self.config;
	c.send_email = send_email.toggle.on;
	c.email=email.textField.text;
	c.beep_pc = beep_pc.toggle.on;
	c.beep_pc_tts = use_speech.toggle.on;
	c.beep_pc_vibrate = vibrate.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	c.enabled = enabled.toggle.on;
	c.threshold = threshold.slider.value;

	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self ];
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];
	send_email.toggleOn=c.send_email;
	send_tweet.toggleOn=c.send_tweet;
	email.textField.text = c.email.isEmpty?self.loginEmail:c.email;
	beep_pc.toggleOn= c.beep_pc;
	use_speech.toggleOn=c.beep_pc_tts;
	vibrate.toggleOn=c.beep_pc_vibrate;
	enabled.toggleOn = c.enabled;
	[threshold setVal:c.threshold];
	notify_every.textField.text = [notify_every_choices objectAtIndex:c.notify_every_index];

	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	[super setConfig:c];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	email =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"\tto:" delegate:self];
	send_email = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"The tag will notify you by email when the the battery drops below a threshold.",nil) delegate:self];
	send_tweet = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"Automatically post a tweet when the tag battery drops below a threshold.",nil) delegate:self];
	tweetLogin = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting...",nil)];
	beep_pc = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' when battery drops below a threshold.",nil) delegate:self];
	use_speech = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	vibrate = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil)  delegate:self];
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	
	enabled =[IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Enable Low-Battery Alerts",nil) helpText:NSLocalizedString(@"If enabled, the Cloud checks the battery voltage reported by the tag everytime it communicates with the tag. If battery voltage is lower than a threshold, notification(s) are sent.",nil) delegate:self];
	threshold = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Threshold",nil) Min:1.5 Max:3.5 Step:0.05 Unit:@"volts" delegate:self];
	notify_every =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify Every:",nil)];

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSSliderSpecifierViewCell	class]])
		return 86;
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return enabled.toggleOn? (3+(send_email.toggleOn?2:1)+(send_tweet.toggleOn?2:1)+(beep_pc.toggleOn?4:1)) : 1;
}
-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;
	
	if(cell == enabled){
		[self.tableView beginUpdates];
		[enabled updateToggleOn];
		NSMutableArray* ips = [NSMutableArray arrayWithCapacity:10];
		int num = (3+(send_email.toggle.on?2:1)+(beep_pc.toggle.on?4:1)+(send_tweet.toggle.on?2:1));
		for(int i=1;i<num;i++){
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:0]];
		}
		if(enabled.toggle.on){
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}
	else if(cell == send_email){
		[self.tableView beginUpdates];
		[send_email updateToggleOn];
		if(send_email.toggle.on){
			if(email.textField.text.length==0)email.textField.text = self.loginEmail;
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:0], nil] withRowAnimation:UITableViewRowAnimationTop];
		}else
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:3 inSection:0], nil] withRowAnimation:UITableViewRowAnimationTop];
		
		[self.tableView endUpdates];
	}
	else if(cell==send_tweet){
		[self.tableView beginUpdates];
		[send_tweet updateToggleOn];
		int base = send_email.toggle.on?5:4;
		if(send_tweet.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}
	else if(cell==beep_pc){
		int base = 2+(send_email.toggle.on?3:2) + (send_tweet.toggle.on?2:1);
		[self.tableView beginUpdates];
		[beep_pc updateToggleOn];
		if(beep_pc.toggle.on){
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],[NSIndexPath indexPathForRow:base+1 inSection:0],
			  [NSIndexPath indexPathForRow:base+2 inSection:0], nil] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:base inSection:0],[NSIndexPath indexPathForRow:base+1 inSection:0],
			  [NSIndexPath indexPathForRow:base+2 inSection:0],
			  nil] withRowAnimation:UITableViewRowAnimationTop];
		}
		[self.tableView endUpdates];
	}

	[self scheduleRecalculatePopoverSize];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	OptionPicker *picker=nil;
	NSMutableDictionary* c = self.config;
	UITableViewCell* cell =[self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
		[tableView beginUpdates];
		[tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
	}
	else
	if(cell==notify_every ){
		picker = [[[OptionPicker alloc]initWithOptions:notify_every_choices Selected:[c notify_every_index]
												  Done:^(NSInteger selected, BOOL now){
													  notify_every.textField.text = [notify_every_choices objectAtIndex:selected];
													  c.notify_every=notify_every_choices_val[selected];
												  } ] autorelease];
	}else if(cell == apns_sound){
		
		picker = [[[OptionPicker alloc]initWithOptions:
				   [NSArray arrayWithObjects:apns_sound_choices count:sizeof(apns_sound_choices)/sizeof(NSString*)]
											  Selected:c.apns_sound_index
												  Done:^(NSInteger selected, BOOL now){
													  apns_sound.textField.text = apns_sound_choices[selected];
													  c.apnsSound =apns_sound_choices[selected];
													  [super playAiff:selected];
												  } ] autorelease];
	}
	else if(cell==tweetLogin)
		[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
	[super presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:ip]];
}

// [when out of range (enabled, threshold, send_email, email_addr, tweet, tweet_login, ringpc, usespeech, vib, notify every)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	NSMutableArray* cells = [NSMutableArray arrayWithCapacity:10];
	[cells addObject:enabled];
	if(enabled.toggleOn){
		[cells addObject:threshold];
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
			[cells addObject:apns_sound];
			[cells addObject:vibrate];
		}
		[cells addObject:notify_every];
	}
	return [cells objectAtIndex:ip.row];
}
@end


@implementation PhoneOptionsViewController
@synthesize modified=_modified;

- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		_modified=NO;
    }
    return self;
}
-(void)dealloc{
	self.config=nil;
	[super dealloc];
}

-(void)navbarSave{
	for(int i=0;i<self.config.mobile_notifications.count;i++){
		NSMutableDictionary* mn = (NSMutableDictionary*)[self.config.mobile_notifications objectAtIndex:i];
		BOOL enabled = [(IASKPSToggleSwitchSpecifierViewCell*)[mobile_notifications objectAtIndex:i] toggle].on;
		[mn setValue:[NSNumber numberWithBool:!enabled] forKey:@"disabled"];
		[mn removeObjectForKey:@"name"];
	}	
	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self];
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];
	
	[mobile_notifications release];
	mobile_notifications = [[NSMutableArray arrayWithCapacity:c.mobile_notifications.count] retain];
	for(int i=0;i<c.mobile_notifications.count;i++){
		NSDictionary* mn = (NSDictionary*)[c.mobile_notifications objectAtIndex:i];
		IASKPSToggleSwitchSpecifierViewCell* cell= [IASKPSToggleSwitchSpecifierViewCell newWithTitle:[mn objectForKey:@"name"] helpText:nil delegate:self];
		cell.toggleOn = ![[mn objectForKey:@"disabled"] boolValue];
		[mobile_notifications addObject:cell];
		[cell release];
	}
	[super setConfig:c];
}
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

// [enable notifications on () ] 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"Enable Notifications On:",nil);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.config.mobile_notifications.count;
}

-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	return [mobile_notifications objectAtIndex:ip.row];
}
@end


@implementation NSMutableDictionary (MSConfig)

- (NSString*)email{ return [self objectForKey:@"email"];}
-(NSString*)email_oor{return [self objectForKey:@"email_oor"];}
-(void)setEmail:(NSString *)email{[self setObject:email==nil?@"":email forKey:@"email"];}
-(void)setEmail_oor:(NSString *)email{[self setObject:email==nil?@"":email forKey:@"email_oor"];}
-(int) auto_reset_delay{return [[self objectForKey:@"auto_reset_delay"] intValue];}
-(void)setAuto_reset_delay:(int)auto_reset_delay{[self setObject:[NSNumber numberWithInt:auto_reset_delay] forKey:@"auto_reset_delay"];}
-(BOOL) beep_pc{return [[self objectForKey:@"beep_pc"] boolValue];}
-(void)setBeep_pc:(BOOL)beep_pc{[self setObject:[NSNumber numberWithBool:beep_pc] forKey:@"beep_pc"];}
-(BOOL) beep_pc_loop{return [[self objectForKey:@"beep_pc_loop"] boolValue];}
-(void)setBeep_pc_loop:(BOOL)beep_pc_loop{[self setObject:[NSNumber numberWithBool:beep_pc_loop] forKey:@"beep_pc_loop"];}
-(BOOL) beep_pc_oor{return [[self objectForKey:@"beep_pc_oor"] boolValue];}
-(void)setBeep_pc_oor:(BOOL)beep_pc_oor{[self setObject:[NSNumber numberWithBool:beep_pc_oor] forKey:@"beep_pc_oor"];}
-(BOOL) beep_pc_tts{return [[self objectForKey:@"beep_pc_tts"] boolValue];}
-(void)setBeep_pc_tts:(BOOL)beep_pc_tts{[self setObject:[NSNumber numberWithBool:beep_pc_tts] forKey:@"beep_pc_tts"];}

-(BOOL) notify_normal{return [[self objectForKey:@"notify_normal"] boolValue];}
-(void)setNotify_normal:(BOOL)notify_normal{[self setObject:[NSNumber numberWithBool:notify_normal] forKey:@"notify_normal"];}

-(BOOL) beep_pc_tts_oor{return [[self objectForKey:@"beep_pc_tts_oor"] boolValue];}
-(void)setBeep_pc_tts_oor:(BOOL)beep_pc_tts_oor{[self setObject:[NSNumber numberWithBool:beep_pc_tts_oor] forKey:@"beep_pc_tts_oor"];}
-(BOOL) beep_pc_vibrate{return [[self objectForKey:@"beep_pc_vibrate"] boolValue];}
-(void)setBeep_pc_vibrate:(BOOL)beep_pc_vibrate{[self setObject:[NSNumber numberWithBool:beep_pc_vibrate] forKey:@"beep_pc_vibrate"];}

-(BOOL) notify_open{return [[self objectForKey:@"notify_open"] boolValue];}
-(void)setNotify_open:(BOOL)notify_open{
	[self setObject:[NSNumber numberWithBool:notify_open] forKey:@"notify_open"];
}
-(BOOL) beep_pc_vibrate_oor{return [[self objectForKey:@"beep_pc_vibrate_oor"] boolValue];}
-(void)setBeep_pc_vibrate_oor:(BOOL)beep_pc_vibrate_oor{[self setObject:[NSNumber numberWithBool:beep_pc_vibrate_oor] forKey:@"beep_pc_vibrate_oor"];}
-(BOOL) beep_tag{return [[self objectForKey:@"beep_tag"] boolValue];}
-(void)setBeep_tag:(BOOL)beep_tag{[self setObject:[NSNumber numberWithBool:beep_tag] forKey:@"beep_tag"];}

-(BOOL) silent_arming{return [[self objectForKey:@"silent_arming"] boolValue]; }
-(void) setSilent_arming:(BOOL)silent_arming{ [self setObject:[NSNumber numberWithBool:silent_arming] forKey:@"silent_arming"]; }

-(BOOL) door_mode{return [[self objectForKey:@"door_mode"] boolValue];}
-(void)setDoor_mode:(BOOL)door_mode{[self setObject:[NSNumber numberWithBool:door_mode] forKey:@"door_mode"];}

-(BOOL) hmc_timeout_mode{return [[self objectForKey:@"hmc_timeout_mode"] boolValue];}
-(void)setHmc_timeout_mode:(BOOL)hmc_timeout_mode{[self setObject:[NSNumber numberWithBool:hmc_timeout_mode] forKey:@"hmc_timeout_mode"];}

-(int) door_mode_delay{return [[self objectForKey:@"door_mode_delay"] intValue];}
-(void)setDoor_mode_delay:(int)door_mode_delay{[self setObject:[NSNumber numberWithInt:door_mode_delay] forKey:@"door_mode_delay"];}

-(int) door_mode_delay_index{
	int i=0;
	for(;i<sizeof(trigger_delay_choices_val)/sizeof(int);i++)
		if(trigger_delay_choices_val[i]== self.door_mode_delay)
			return i;	
	return 0;
}
-(int) pir_reset_delay_index{
	int i=0;
	for(;i<sizeof(pir_reset_choices_val)/sizeof(int);i++)
		if(pir_reset_choices_val[i]== self.auto_reset_delay)
			return i;
	return 0;
}
-(int) apns_sound_index{
	int i=1;
	if(self.apnsSound.isEmpty)return 0;
	for(;i< sizeof(apns_sound_choices)/sizeof(NSString*);i++)
		if( [self.apnsSound isEqualToString:apns_sound_choices[i]])
			return i;
	return 0;
}
-(int) apns_pause_index{
	int i=0;
	for(;i< sizeof(apns_pause_values)/sizeof(int);i++)
		if(self.apns_pause == apns_pause_values[i])
			return i;
	return 4;
}

-(int) auto_reset_delay_index{
	int i=0;
	for(;i<sizeof(auto_reset_choices_val)/sizeof(int);i++)
		if(auto_reset_choices_val[i]== self.auto_reset_delay)
			return i;
	return 0;
}
-(int) notify_every_index{
	int i=0;
	for(;i<sizeof(notify_every_choices_val)/sizeof(int);i++)
		if(notify_every_choices_val[i]== self.notify_every)
			return i;
	return 0;
}

-(float) door_mode_angle{return [[self objectForKey:@"door_mode_angle"] floatValue];}
-(void)setDoor_mode_angle:(float)door_mode_angle{[self setObject:[NSNumber numberWithFloat:door_mode_angle] forKey:@"door_mode_angle"];}

-(int) aa1_tod{return [[self objectForKey:@"aa1_tod"] intValue];}
-(void)setAa1_tod:(int)aa1_tod{[self setObject:[NSNumber numberWithInt:aa1_tod] forKey:@"aa1_tod"];}
-(int) aa2_tod{return [[self objectForKey:@"aa2_tod"] intValue];}
-(void)setAa2_tod:(int)aa2_tod{[self setObject:[NSNumber numberWithInt:aa2_tod] forKey:@"aa2_tod"];}
-(int) ada1_tod{return [[self objectForKey:@"ada1_tod"] intValue];}
-(void)setAda1_tod:(int)ada1_tod{[self setObject:[NSNumber numberWithInt:ada1_tod] forKey:@"ada1_tod"];}
-(int) ada2_tod{return [[self objectForKey:@"ada2_tod"] intValue];}
-(void)setAda2_tod:(int)ada2_tod{[self setObject:[NSNumber numberWithInt:ada2_tod] forKey:@"ada2_tod"];}
-(int) aa1_dow{return [[self objectForKey:@"aa1_dow"] intValue];}
-(void)setAa1_dow:(int)aa1_dow{[self setObject:[NSNumber numberWithInt:aa1_dow] forKey:@"aa1_dow"];}
-(int) aa2_dow{return [[self objectForKey:@"aa2_dow"] intValue];}
-(void)setAa2_dow:(int)aa2_dow{[self setObject:[NSNumber numberWithInt:aa2_dow] forKey:@"aa2_dow"];}
-(BOOL) aa1_en{return [[self objectForKey:@"aa1_en"] boolValue];}
-(void)setAa1_en:(BOOL)aa1_en{[self setObject:[NSNumber numberWithBool:aa1_en] forKey:@"aa1_en"];}


-(BOOL) aa2_en{return [[self objectForKey:@"aa2_en"] boolValue];}
-(void)setAa2_en:(BOOL)aa2_en{[self setObject:[NSNumber numberWithBool:aa2_en] forKey:@"aa2_en"];}
-(int)tzo{return [[self objectForKey:@"tzo"] intValue];}
-(void)setTzo:(int)tzo{[self setObject:[NSNumber numberWithInt:tzo] forKey:@"tzo"];}
-(int)apns_pause{return [[self objectForKey:@"apns_pause"] intValue];}
-(void)setApns_pause:(int)apns_pause{[self setObject:[NSNumber numberWithInt:apns_pause] forKey:@"apns_pause"];}

-(float)th_window {return [[self objectForKey:@"th_window"] floatValue];}
-(void)setTh_window:(float)th_window{[self setObject:[NSNumber numberWithFloat:th_window] forKey:@"th_window"]; }
-(float) th_low{return [[self objectForKey:@"th_low"] floatValue];}
-(void)setTh_low:(float)th_low{[self setObject:[NSNumber numberWithFloat:th_low] forKey:@"th_low"];}
-(float) th_high{return [[self objectForKey:@"th_high"] floatValue];}
-(void)setTh_high:(float)th_high{[self setObject:[NSNumber numberWithFloat:th_high] forKey:@"th_high"];}

-(float)lux_th_low{return [[self objectForKey:@"lux_th_low"] floatValue]; }
-(float)lux_th_high{return [[self objectForKey:@"lux_th_high"] floatValue]; }
-(void)setLux_th_low:(float)th_low{[self setObject:[NSNumber numberWithFloat:th_low] forKey:@"lux_th_low"];}
-(void)setLux_th_high:(float)th_low{[self setObject:[NSNumber numberWithFloat:th_low] forKey:@"lux_th_high"];}

-(int)temp_unit{	id temp_unit_s = [self objectForKey:@"temp_unit"];
	if(temp_unit_s)
		return [temp_unit_s intValue];
	else
		return chosen_temp_unit;
}
-(void)setTemp_unit:(int)temp_unit{
	[self setObject:[NSNumber numberWithInt:temp_unit] forKey:@"temp_unit"];
}

-(int) intervalSec{return [[self objectForKey:@"intervalSec"] intValue];}
-(void)setIntervalSec:(int)interval{[self setObject:[NSNumber numberWithInt:interval] forKey:@"intervalSec"];}

-(int)th_monitor_interval{return [[self objectForKey:@"th_monitor_interval"] intValue];}
-(void)setTh_monitor_interval:(int)th_monitor_interval{ [self setObject:[NSNumber numberWithInt:th_monitor_interval] forKey:@"th_monitor_interval"];}

-(int) interval{return [[self objectForKey:@"interval"] intValue];}
-(void)setInterval:(int)interval{[self setObject:[NSNumber numberWithInt:interval] forKey:@"interval"];}

//@property (nonatomic, retain) NSArray *mobile_notifications; //: [{uuid:ffffffff-fdec-c798-ffff-ffffca2cbb0c, name:LG-P350a, disabled:false}]
-(NSArray*) mobile_notifications{return [self objectForKey:@"mobile_notifications"];}
-(void)setMobile_notifications:(NSArray *)mobile_notifications{[self setObject:mobile_notifications forKey:@"mobile_notifications"];}

-(BOOL) send_email{return [[self objectForKey:@"send_email"] boolValue];}
-(void)setSend_email:(BOOL)send_email{[self setObject:[NSNumber numberWithBool:send_email] forKey:@"send_email"];}

-(BOOL) send_tweet{return [[self objectForKey:@"send_tweet"] boolValue];}
-(void)setSend_tweet:(BOOL)send_tweet{[self setObject:[NSNumber numberWithBool:send_tweet] forKey:@"send_tweet"];}

-(BOOL) send_email_on_close{return [[self objectForKey:@"send_email_on_close"] boolValue];}
-(void)setSend_email_on_close:(BOOL)send_email_on_close{[self setObject:[NSNumber numberWithBool:send_email_on_close] forKey:@"send_email_on_close"];}
-(BOOL) send_email_oor{return [[self objectForKey:@"send_email_oor"] boolValue];}
-(void)setSend_email_oor:(BOOL)send_email_oor{[self setObject:[NSNumber numberWithBool:send_email_oor] forKey:@"send_email_oor"];}

-(int) sensitivity{return [[self objectForKey:@"sensitivity"] intValue];}
-(int) sensitivity2{return [[self objectForKey:@"sensitivity2"] intValue];}
-(void)setSensitivity:(int)sensitivity{[self setObject:[NSNumber numberWithInt:sensitivity] forKey:@"sensitivity"];}
-(void)setSensitivity2:(int)sensitivity{[self setObject:[NSNumber numberWithInt:sensitivity] forKey:@"sensitivity2"];}

-(float) threshold{return [[self objectForKey:@"threshold"] floatValue];}
-(void)setThreshold:(float)threshold{[self setObject:[NSNumber numberWithFloat:threshold] forKey:@"threshold"];}
-(BOOL)enabled{return [[self objectForKey:@"enabled"] boolValue];}
-(void)setEnabled:(BOOL)enabled{[self setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];}
-(int)notify_every{return [[self objectForKey:@"notify_every"] intValue];}
-(void)setNotify_every:(int)notify_every{[self setObject:[NSNumber numberWithInt:notify_every] forKey:@"notify_every"];}

-(BOOL) isMsConfig{ 
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.MotionSensorConfig"] == YES;
}
-(BOOL) isOorConfig{ 
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.OutOfRangeConfig"] == YES;
}
-(BOOL) isTempConfig{ 
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.TempSensorConfig"] == YES;
}
-(BOOL) isCapConfig{ 
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.CapSensorConfig"] == YES;
}
-(BOOL) isLightConfig{
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.LightSensorConfig"] == YES;
}
-(BOOL) isKumostatConfig{
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.KumostatConfig"] == YES;
}
-(BOOL) isPhonesConfig{
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.MobileNotificationConfig"] == YES;
}
-(BOOL) isLBConfig{
	return[[self objectForKey:@"__type"] isEqualToString:@"MyTagList.LowBatteryConfig"] == YES;
}

-(NSString*)apnsSound{ NSObject* o = [self objectForKey:@"apnsSound"];
	if([o isKindOfClass:[NSString class]])return (NSString*)o; else return nil;}
-(void)setApnsSound:(NSString *)apnsSound{[self setObject:apnsSound forKey:@"apnsSound"];}

-(NSString*)loginEmail{ return [self objectForKey:@"loginEmail"];}
-(NSString*)loginPwd{return [self objectForKey:@"loginPwd"];}
-(NSString*)twitterID{ return [self objectForKey:@"twitterID"];}
-(NSString*)twitterPwd{return [self objectForKey:@"twitterPwd"];}
-(void)setLoginEmail:(NSString *)loginEmail{[self setObject:loginEmail forKey:@"loginEmail"];}
-(void)setLoginPwd:(NSString *)loginPwd{[self setObject:loginPwd forKey:@"loginPwd"];}
-(void)setTwitterID:(NSString *)twitterID{[self setObject:twitterID forKey:@"twitterID"];}
-(void)setTwitterPwd:(NSString *)twitterPwd{[self setObject:twitterPwd forKey:@"twitterPwd"];}
-(BOOL) allowMore{return [[self objectForKey:@"allowMore"] boolValue];}
-(void)setAllowMore:(BOOL)allowMore{[self setObject:[NSNumber numberWithBool:allowMore] forKey:@"allowMore"];}
-(BOOL) isAccountConfig{return [[self objectForKey:@"__type"] isEqualToString:@"MyTagList.AccountConfig"] == YES;
}
-(BOOL) isMessageConfig{return [[self objectForKey:@"__type"] isEqualToString:@"MyTagList.MessageTemplateConfig"] == YES;
}


@end


