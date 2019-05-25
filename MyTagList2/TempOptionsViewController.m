//
//  TempOptionsViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TempOptionsViewController.h"
#import "OptionPicker.h"
#import "iToast.h"

#define degC_min -35
#define degF_min ((degC_min*9.0/5.0)+32)
#define degC_max 115
#define degF_max ((degC_max*9.0/5.0)+32)
#import "Tag.h"

int chosen_temp_unit=0;    // 0 is Celsius, 1 is Fahrenheit
NSString* const dewPointModeKey=@"mytaglist.dewPointMode";
BOOL dewPointMode = NO;

@implementation TempOptionsViewController
@synthesize modified=_modified, tempDelegate=_tempDelegate, tag=_tag, rnc_toocold=_rnc_toocold, rnc_toohot=_rnc_toohot;
@synthesize loginEmail=_loginEmail;

- (id)initWithDelegate:(id<OptionsViewControllerDelegate, TempOptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		self.tempDelegate = delegate;
		temp_unit_choices = [[NSArray 
							  arrayWithObjects:@"°C", @"°F", nil] retain];
		_modified=NO;
    }
    return self;
}

-(void)releaseViews{
	[temp_units release]; temp_units=nil;
	[temp_range release]; temp_range=nil;
	[temp_cal release]; temp_cal=nil;
	[temp_uncal_btn release]; temp_uncal_btn=nil;
	[threshold_window release]; threshold_window=nil;
	[temp_cal_btn release]; temp_cal_btn=nil;
	[monitor_temp release]; monitor_temp=nil;
	[email release]; email=nil;
	[send_email release]; send_email=nil;
	[beep_pc release]; beep_pc=nil;
	[use_speech release]; use_speech=nil;
	[vibrate release]; vibrate=nil;
	[apns_sound release]; apns_sound=nil;
	[apns_pause release]; apns_pause=nil;
	[send_tweet release]; send_tweet=nil;
	[notify_normal release]; notify_normal=nil;
	[tweetLogin release]; tweetLogin=nil;
	[interval release]; interval=nil;
	[th_low_delay release]; th_low_delay=nil;
	[th_high_delay release]; th_high_delay=nil;
	[rn_toohot release]; rn_toohot=nil;
	[rn_toocold release]; rn_toocold=nil;
	self.cellArray=nil;
}
-(void)dealloc{
	self.loginEmail=nil;
	[self releaseViews];
	[temp_unit_choices release];
	self.config=nil;
	[_rnc_toohot release]; [_rnc_toocold release];
	[super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSSliderSpecifierViewCell	class]])
		return 86;
	else if([cell isKindOfClass:[IASKPSDualSliderSpecifierViewCell	class]])
		return 120; //86;
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}

-(void)navbarSave{

	
	NSMutableDictionary* c = self.config;
	old_th_low =c.th_low;
	old_th_high = c.th_high;
	c.th_low = chosen_temp_unit==0? temp_range.slider.selectedMinimumValue: (temp_range.slider.selectedMinimumValue-32.0)*5.0/9.0;
	c.th_high = chosen_temp_unit==0? temp_range.slider.selectedMaximumValue: (temp_range.slider.selectedMaximumValue-32.0)*5.0/9.0;
	c.th_window = chosen_temp_unit==0? threshold_window.slider.value: (threshold_window.slider.value)*5.0/9.0;
	
	c.send_email = send_email.toggle.on;
	c.email=email.textField.text;
	c.beep_pc = beep_pc.toggle.on;
	c.beep_pc_tts = use_speech.toggle.on;
	c.notify_normal = notify_normal.toggle.on;
	c.beep_pc_vibrate = vibrate.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	
	[self.delegate optionViewSaveBtnClicked:self];

}

-(void)armDisarmTempsensorAsNeededWithApplyAll:(BOOL)applyAll{
	if((_tag.tempEventState==TempDisarmed && monitor_temp.toggle.on) || 
	   (monitor_temp.toggle.on && (enhanced_monitoring_option_changed || fabs(old_th_low-self.config.th_low)>0.02 || fabs(old_th_high-self.config.th_high)>0.02))){
		if(applyAll)
			[_tempDelegate armTempsensorForAllTags];
		else
			[_tempDelegate armTempsensorForTag:_tag];
	}
	else if(_tag.tempEventState!=TempDisarmed && !monitor_temp.toggle.on){
		if(applyAll)
			[_tempDelegate disarmTempsensorForAllTags];
		else
			[_tempDelegate disarmTempsensorForTag:_tag];
	}
}

-(void)setConfig:(NSMutableDictionary *)c andTag:(NSMutableDictionary*)tag
{		
	[super view];
	enhanced_monitoring_option_changed=NO;
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];
	
	chosen_temp_unit = c.temp_unit;
	if(chosen_temp_unit>1)chosen_temp_unit=1;
	else if(chosen_temp_unit<0)chosen_temp_unit=0;
	
	temp_units.textField.text = [temp_unit_choices objectAtIndex:chosen_temp_unit];
	temp_cal.unit=temp_range.unit =chosen_temp_unit?@"°F": @"°C";

	temp_range.slider.currentValue = chosen_temp_unit? tag.temperatureDegC*9.0/5.0+32 : tag.temperatureDegC;
	temp_range.slider.maximumValue = chosen_temp_unit?c.threshold_q.max*9.0/5.0+32:c.threshold_q.max;
	temp_range.slider.minimumValue = chosen_temp_unit?c.threshold_q.min*9.0/5.0+32:c.threshold_q.min;
	temp_range.slider.stepSize = chosen_temp_unit?c.threshold_q.step*9.0/5.0:c.threshold_q.step;
	temp_range.slider.selectedMaximumValue = chosen_temp_unit?c.th_high*9.0/5.0+32:c.th_high;
	temp_range.slider.selectedMinimumValue=chosen_temp_unit? c.th_low*9.0/5.0+32: c.th_low;
	[temp_range sliderValueChanged:nil];

	[threshold_window setVal:chosen_temp_unit>0?c.th_window*9.0/5.0:c.th_window];
	
	send_email.toggleOn = c.send_email;
	send_tweet.toggleOn = c.send_tweet;
	if( !c.email.isEmpty) email.textField.text = c.email;
	else email.textField.text=c.loginEmail;
	beep_pc.toggleOn= c.beep_pc;
	notify_normal.toggleOn = c.notify_normal;
	use_speech.toggleOn=c.beep_pc_tts; vibrate.toggleOn=c.beep_pc_vibrate;
	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	apns_pause.textField.text = apns_pause_choices[ c.apns_pause_index ];


	int selected=1;
	for(int i=0;i<sizeof(monitor_interval_choices)/sizeof(int);i++)
		if(monitor_interval_choices[i]== c.interval){
			selected=i; break;
		}
	interval.textField.text =[[self monitor_interval_labels] objectAtIndex:selected];
	
	th_high_delay.textField.text = [NSString stringWithFormat:NSLocalizedString(@"%@ reading",nil), [c objectForKey:@"th_high_delay"]];
	th_low_delay.textField.text = [NSString stringWithFormat:NSLocalizedString(@"%@ reading",nil), [c objectForKey:@"th_low_delay"]];
	
	self.tag= tag;
//	ds18sel.toggleOn = tag.ds18;
	monitor_temp.toggleOn = (tag.tempEventState!=TempDisarmed);
	[temp_cal setVal:chosen_temp_unit>0?(tag.temperatureDegC*9.0/5.0+32) :tag.temperatureDegC ];
	
	self.rnc_toocold=nil; self.rnc_toohot=nil;
	
	[self updateCellArray];
	[super setConfig:c];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	monitor_temp = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Monitor Temperature",nil) helpText:nil delegate:self];
	temp_units = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Temperature Units:",nil)];
	temp_units.textField.text = [temp_unit_choices objectAtIndex:chosen_temp_unit];
	if(chosen_temp_unit==0){
		temp_range = [IASKPSDualSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"< Normal Range <",nil) Min:degC_min Max:degC_max Unit:@"°C"	numberFormat:@"%.1f"	delegate:self];
		temp_cal = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Calibrate To:",nil) Min:degC_min Max:degC_max Step:0.1 Unit:@"°C" delegate:self];
		threshold_window = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Threshold Window",nil) Min:0 Max:5 Step:0.05 Unit:@"°C" delegate:self];
	}else{
		temp_range = [IASKPSDualSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"< Normal Range <",nil) Min:degF_min Max:degF_max Unit:@"°F" numberFormat:@"%.1f" delegate:self];
		temp_cal = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Calibrate To:",nil) Min:degF_min Max:degF_max Step:0.1 Unit:@"°F" delegate:self];
		threshold_window = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"Threshold Window",nil) Min:0 Max:9 Step:0.1 Unit:@"°F" delegate:self];
	}
	temp_cal_btn = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Calibrate",nil) Progress:NSLocalizedString(@"Saving...",nil)];
	temp_uncal_btn = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Remove Calibration",nil) Progress:NSLocalizedString(@"Saving...",nil)];

	email =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"\tto:" delegate:self];
	send_email = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"The tag will send you email when temperature becomes too high, too low or back to normal range.",nil) delegate:self];
	send_tweet = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"The tag will tweet on behalf of you when temperature becomes too high, too low or back to normal range.",nil) delegate:self];
	tweetLogin = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting",nil)];
	
	beep_pc = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' when temperature becomes too high, too low or returns within the normal range.",nil) delegate:self];
	use_speech = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];

	notify_normal = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tNotify back to normal",nil) helpText:NSLocalizedString(@"In addition to when too hot/too cold, send push notification also when temperature is back to normal range.",nil) delegate:self];

	vibrate = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil)  delegate:self];
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	apns_pause =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPause Action Effective For: ",nil)];

	interval =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Check temperature every: ",nil)];
	th_high_delay =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too hot after consecutive:",nil)];
	th_low_delay =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too cold after consecutive:",nil)];

	rn_toocold =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too cold:",nil)];  rn_toocold.textField.text = rnc_timespan_choices[0];
	rn_toohot =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too hot:",nil)]; rn_toohot.textField.text = rnc_timespan_choices[0];
	
	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
	
	self.cellArray = [[[NSMutableArray alloc]initWithCapacity:15] autorelease];
	[self updateCellArray];

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
	return _tag.isNest? 2:3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==0)
		return nil;
	else if(section==2 && !_tag.isNest)
		if(chosen_temp_unit)
			return [NSLocalizedString(@"Temperature Calibration",nil) stringByAppendingFormat:@" (Raw Reading: %.1f°F)", (_tag.temperatureDegC-_tag.tempCalOffset)*9.0/5.0+32.0];
		else
			return [NSLocalizedString(@"Temperature Calibration",nil) stringByAppendingFormat:@" (Raw Reading: %.1f°C)", _tag.temperatureDegC-_tag.tempCalOffset];

	else
		return NSLocalizedString(@"Monitor Temperature:",nil);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)
		return 1;
	else if(section==2 && !_tag.isNest)
		return 3;
	else
		return self.cellArray.count;
}

-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;
	if(cell == send_email){
		
		NSArray* oldCells = [[self.cellArray copy] autorelease];
		[self.tableView beginUpdates];
		[send_email updateToggleOn];
		if(send_email.toggle.on){
			if(email.textField.text.length==0)email.textField.text = self.loginEmail;
		}
		[self updateCellArray];
		[self animateCellPresence:email fromArray:oldCells toArray:self.cellArray];
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];

	}
	else if(cell==send_tweet){

		NSArray* oldCells = [[self.cellArray copy] autorelease];
		[self.tableView beginUpdates];
		[send_tweet updateToggleOn];
		[self updateCellArray];
		[self animateCellPresence:tweetLogin fromArray:oldCells toArray:self.cellArray];
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];

	}
	else if(cell==beep_pc){

		NSArray* oldCells = [[self.cellArray copy] autorelease];
		[self.tableView beginUpdates];
		[beep_pc updateToggleOn];
		[self updateCellArray];
		[self animateCellPresence:notify_normal fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:use_speech fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_pause fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_sound fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:vibrate fromArray:oldCells toArray:self.cellArray];
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];


	}else if(cell==monitor_temp){

		NSArray* oldCells = [[self.cellArray copy] autorelease];
		[self.tableView beginUpdates];
		[monitor_temp updateToggleOn];
		[self updateCellArray];
		[self animateCellPresence:temp_range fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:threshold_window fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:interval fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:th_low_delay fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:th_high_delay fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:send_email fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:email fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:send_tweet fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:tweetLogin fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:beep_pc fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:notify_normal fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:use_speech fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_pause fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_sound fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:vibrate fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:rn_toohot fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:rn_toocold fromArray:oldCells toArray:self.cellArray];
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
		
	}
}

-(void)animateCellPresence:(UITableViewCell*)cell fromArray:(NSArray*)oldCells toArray:(NSArray*)newCells{
	NSUInteger oldIndex = [oldCells indexOfObject:cell];
	NSUInteger newIndex = [newCells indexOfObject:cell];
	if(oldIndex==NSNotFound && newIndex!=NSNotFound){
		[self.tableView insertRowsAtIndexPaths:
		 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:newIndex inSection:1],nil] withRowAnimation:UITableViewRowAnimationFade];
	}else if(newIndex==NSNotFound && oldIndex!=NSNotFound){
		[self.tableView deleteRowsAtIndexPaths:
		 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:oldIndex inSection:1],nil] withRowAnimation:UITableViewRowAnimationFade];
	}
}
-(void)updateCellArray{
	[self.cellArray removeAllObjects];
	NSMutableArray* cells = self.cellArray;
	[cells addObject:monitor_temp];
	if(monitor_temp.toggleOn){
		[cells addObject:temp_range];
		[cells addObject:threshold_window];
		if(_tag.rev>=0x2F){
			[cells addObject:interval];
			[cells addObject:th_low_delay];
			[cells addObject:th_high_delay];
		}
		[cells addObject:send_email];
		if(send_email.toggleOn){
			[cells addObject:email];
		}
		[cells addObject:beep_pc];
		if(beep_pc.toggleOn){
			[cells addObject:notify_normal];
			[cells addObject:use_speech];
			[cells addObject:apns_pause];
			[cells addObject:apns_sound];
			[cells addObject:vibrate];
		}
		[cells addObject:send_tweet];
		if(send_tweet.toggleOn)
			[cells addObject:tweetLogin];

		[cells addObject:rn_toohot];
		[cells addObject:rn_toocold];
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.section==0){
		return temp_units;
	}
	else if(ip.section==2 && !_tag.isNest){
		if(ip.row==0)
			return temp_cal;
		else if(ip.row==1)
			return temp_cal_btn;
		else
			return temp_uncal_btn;
	}else{
		return [self.cellArray objectAtIndex:ip.row];
	}
}

-(void)convertDegFtoC
{
	threshold_window.slider.value = (threshold_window.slider.value*5.0/9.0);
	threshold_window.slider.maximumValue=5;
	
	temp_cal.slider.maximumValue = degC_max;
	temp_cal.slider.minimumValue = degC_min;
	temp_cal.unit=temp_range.unit = @"°C";
	[temp_cal setVal: (temp_cal.slider.value-32)*5.0/9.0];
	temp_range.slider.selectedMinimumValue = (temp_range.slider.selectedMinimumValue-32)*5.0/9.0;
	temp_range.slider.minimumValue = (temp_range.slider.minimumValue-32)*5.0/9.0;
	temp_range.slider.maximumValue = (temp_range.slider.maximumValue-32)*5.0/9.0;
	temp_range.slider.stepSize=temp_range.slider.stepSize*5.0/9.0;
	temp_range.slider.selectedMaximumValue = (temp_range.slider.selectedMaximumValue-32)*5.0/9.0;
	[temp_range sliderValueChanged:nil];
}

-(void)convertDegCtoF
{
	threshold_window.slider.maximumValue=9;
	threshold_window.slider.value = (threshold_window.slider.value*9.0/5.0);
	
	temp_cal.slider.maximumValue = degF_max;
	temp_cal.slider.minimumValue = degF_min;
	temp_cal.unit=temp_range.unit = @"°F";
	[temp_cal setVal:(temp_cal.slider.value*9.0/5.0+32)];

	temp_range.slider.selectedMaximumValue = (temp_range.slider.selectedMaximumValue*9.0/5.0+32);
	temp_range.slider.minimumValue = temp_range.slider.minimumValue*9.0/5.0+32;
	temp_range.slider.maximumValue = temp_range.slider.maximumValue*9.0/5.0+32;
	temp_range.slider.stepSize=temp_range.slider.stepSize*9.0/5.0;
	temp_range.slider.selectedMinimumValue = (temp_range.slider.selectedMinimumValue*9.0/5.0+32);
	[temp_range sliderValueChanged:nil];
}
- (void)showLoadingBarItem:(id) item
{
	if(item==temp_cal_btn)[temp_cal_btn showLoading];
	else [super showLoadingBarItem:item];
}
- (void)revertLoadingBarItem:(id) item{
	if(item==temp_cal_btn)[temp_cal_btn revertLoading];
	else [super revertLoadingBarItem:item];
}

static int monitor_interval_choices[] ={15, 30, 60, 90, 120, 180, 300};
-(NSArray*)monitor_interval_labels{
	NSArray* labels =@[NSLocalizedString(@"15 seconds",nil), NSLocalizedString(@"30 seconds",nil), NSLocalizedString(@"1 minute",nil),
					   NSLocalizedString(@"90 seconds",nil), NSLocalizedString(@"2 minutes",nil), NSLocalizedString(@"3 minutes",nil), NSLocalizedString(@"5 minutes",nil)];
	return labels;
}
-(void)setRnc_toohot:(NSMutableDictionary *)rnc_toohot{
	[_rnc_toohot autorelease];
	_rnc_toohot = [rnc_toohot retain];
	int selected=0;
	if(self.rnc_toohot){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_toohot.intervalSec){
				selected=i; break;
			}
	}
	rn_toohot.textField.text = rnc_timespan_choices[selected];
}
-(void)setRnc_toocold:(NSMutableDictionary *)rnc_toocold{
	[_rnc_toocold autorelease];
	_rnc_toocold = [rnc_toocold retain];
	int selected=0;
	if(self.rnc_toocold){
		for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
			if(rnc_timespan_values[i]== self.rnc_toocold.intervalSec){
				selected=i; break;
			}
	}
	rn_toocold.textField.text = rnc_timespan_choices[selected];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	[tableView deselectRowAtIndexPath:ip animated:YES];

	OptionPicker *picker=nil;
	if(ip.section==0){
		picker = [[[OptionPicker alloc]initWithOptions:temp_unit_choices Selected:chosen_temp_unit
												  Done:^(NSInteger selected, BOOL now){
													  temp_units.textField.text = [temp_unit_choices objectAtIndex:selected];
													  if(chosen_temp_unit!=(int)selected){
														  chosen_temp_unit=(int)selected;
														  self.config.temp_unit = (int)selected;
														  
														  if(selected)[self convertDegCtoF];
														  else [self convertDegFtoC];
														  [[self tableView] reloadData];
													  }
												  } ] autorelease];
	}else if(ip.section==2 && !_tag.isNest){
		if(ip.row==1){
			float degC = temp_cal.slider.value; 
			if(chosen_temp_unit)degC = (degC-32.0)*5.0/9.0;
			[self.tempDelegate tempCalibrateBtnClickedForTag:_tag Temperature:degC BtnCell:temp_cal_btn ThresholdSlider:temp_range.slider useDegF:chosen_temp_unit!=0];
		}else if(ip.row==2){
			float degC =_tag.temperatureDegC-_tag.tempCalOffset;
			if(chosen_temp_unit)
				[temp_cal setVal: degC*9.0/5.0+32.0];
			else
				[temp_cal setVal:degC];
			
			[self.tempDelegate tempCalibrateBtnClickedForTag:_tag Temperature:degC BtnCell:temp_cal_btn ThresholdSlider:temp_range.slider useDegF:chosen_temp_unit!=0];
		}
	}else{
		UITableViewCell* cell =[self tableView:tableView cellForRowAtIndexPath:ip];
		if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
			[((IASKPSToggleSwitchSpecifierViewCell*)cell) toggleHelp];
			[tableView beginUpdates];
			[tableView endUpdates];
			[self scheduleRecalculatePopoverSize];
		}
		else
		
		if(cell==apns_sound){
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
													  } helpText:NSLocalizedString(@"Swipe left on a notification of 'Too Hot' or 'Too Cold' events to see 'Pause' and 'Stop Monitoring' button. 'Pause' to temporarily stop receiving the notification but still keep populating Event History. 'Stop monitoring' will temporarily disable temperature monitoring. Here you can choose the time after which to automatically resume receiving events or re-enable monitoring.",nil) ] autorelease];
		}
		else if(cell==interval){
			
			int selected=1;
			for(int i=0;i<sizeof(monitor_interval_choices)/sizeof(int);i++)
				if(monitor_interval_choices[i]== self.config.interval){
					selected=i; break;
				}
			picker = [[[OptionPicker alloc]initWithOptions:[self monitor_interval_labels]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  interval.textField.text =[[self monitor_interval_labels] objectAtIndex:selected_new];
														  self.config.interval = monitor_interval_choices[selected_new];
														  enhanced_monitoring_option_changed=enhanced_monitoring_option_changed||(selected_new!=selected);
													  } helpText:NSLocalizedString(@"Choose a shorter value to measure temperature more frequently, with a slightly reduced battery life. Measurement are not transmitted (which costs battery life) until after crossing a threshold boundary (for the specified number of times).",nil)] autorelease];
			
		}
		else if(cell==rn_toocold){
			int selected=0;
			if(self.rnc_toocold){
				for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
					if(rnc_timespan_values[i]== self.rnc_toocold.intervalSec){
						selected=i; break;
					}
			}
			picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  rn_toocold.textField.text = rnc_timespan_choices[selected_new];
														  
														  if(_rnc_toocold==nil && selected_new>0){
															  _rnc_toocold=[@{@"eventType":@3} mutableCopy];
														  }
														  self.rnc_toocold.intervalSec = rnc_timespan_values[selected_new];
														  if(self.rnc_toocold && selected_new!=selected){
															  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																  if(obj==self.rnc_toocold)return;

															  [self.updatedRepeatNotifyConfigs addObject:self.rnc_toocold];
														  }
													  } helpText:NSLocalizedString(@"Choose to get notified just once or repeatedly when temperature falls below lower limit until the temperature returns to normal. ",nil)] autorelease];
		}
		else if(cell==rn_toohot){
			int selected=0;
			if(self.rnc_toohot){
				for(int i=0;i<sizeof(rnc_timespan_values)/sizeof(int);i++)
					if(rnc_timespan_values[i]== self.rnc_toohot.intervalSec){
						selected=i; break;
					}
			}
			picker = [[[OptionPicker alloc]initWithOptions:[NSArray arrayWithObjects:rnc_timespan_choices count:sizeof(rnc_timespan_choices)/sizeof(NSString*)]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  rn_toohot.textField.text = rnc_timespan_choices[selected_new];

														  if(_rnc_toohot==nil && selected_new>0){
															  _rnc_toohot=[@{@"eventType":@2} mutableCopy];
														  }
														  self.rnc_toohot.intervalSec = rnc_timespan_values[selected_new];
														  if(self.rnc_toohot && selected_new!=selected){
															  for(NSMutableDictionary* obj in self.updatedRepeatNotifyConfigs)
																  if(obj==self.rnc_toohot)return;
															  
															  [self.updatedRepeatNotifyConfigs addObject:self.rnc_toohot];
														  }
														  
													  } helpText:NSLocalizedString(@"Choose to get notified just once or repeatedly when temperature exceeds upper limit until the temperature returns to normal. ",nil)] autorelease];
		}
		else if(cell==th_high_delay || cell==th_low_delay){
			NSString* key =  cell==th_high_delay?@"th_high_delay":@"th_low_delay";
			static int choices[99];
			NSMutableArray* labels = [[NSMutableArray alloc]initWithCapacity:99];
			for(int i=1;i<=99;i++){
				choices[i-1]=i;
				[labels addObject:[NSString stringWithFormat:@"%d reading%@", i, i>1?@"s":@"", nil]];
			}
			int selected =[[self.config objectForKey:key] intValue]-1;
			picker = [[[OptionPicker alloc]initWithOptions:labels
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  ((IASKPSTextFieldSpecifierViewCell*)cell).textField.text = [labels objectAtIndex:selected_new];
														  [self.config setObject:[NSNumber numberWithInteger:selected_new+1] forKey:key];
														  enhanced_monitoring_option_changed=enhanced_monitoring_option_changed||(selected_new!=selected);
													  } helpText:NSLocalizedString(@"If you don't want to get notified when temperature gets too hot or too cold for only a short period of time, choose a value larger than 1.",nil)] autorelease];
		}
		else if(cell==tweetLogin){
			[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
		}
	}
	if(picker!=nil)
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
	}
 */
}


@end

