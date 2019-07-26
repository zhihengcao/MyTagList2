//
//  LightOptionsViewController.m
//  MyTagList2
//
//  Created by cao on 8/7/16.
//
//

#import "Tag.h"
#import "LightOptionsViewController.h"
#import "OptionPicker.h"

@interface LightOptionsViewController ()

@end

@implementation LightOptionsViewController

@synthesize modified=_modified, lightDelegate=_lightDelegate, tag=_tag;
@synthesize loginEmail=_loginEmail;

- (id)initWithDelegate:(id<OptionsViewControllerDelegate, LightOptionsViewControllerDelegate>)delegate
{
	self = [super initWithDelegate:delegate];
	if (self) {
		self.lightDelegate = delegate;
		_modified=NO;
	}
	return self;
}

-(void)releaseViews{
	[light_range release]; light_range=nil;
	[light_scale release]; light_scale=nil;
	[monitor_light release]; monitor_light=nil;
	[email release]; email=nil;
	[send_email release]; send_email=nil;
	[beep_pc release]; beep_pc=nil; [use_speech release]; use_speech=nil; [vibrate release]; vibrate=nil;
	[apns_sound release]; apns_sound=nil;
	[apns_pause release]; apns_pause=nil;
	[send_tweet release]; send_tweet=nil;
	[tweetLogin release]; tweetLogin=nil;
	[interval release]; interval=nil;
	[th_low_delay release]; th_low_delay=nil;
	[th_high_delay release]; th_high_delay=nil;
	self.cellArray=nil;
}
-(void)dealloc{
	self.loginEmail=nil;
	[self releaseViews];
	self.config=nil;
	[super dealloc];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSLuxRangeSpecifierViewCell	class]])
		return 72;
	else if([cell isKindOfClass:[IASKPSDualSliderSpecifierViewCell	class]])
		return 120;
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]])
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	else
		return 44;
}

-(void)navbarSave{
	NSMutableDictionary* c = self.config;
	old_th_low =c.lux_th_low;
	old_th_high = c.lux_th_high;
	
	c.lux_th_low = light_range.slider.selectedMinimumValue;
	c.lux_th_high = light_range.slider.selectedMaximumValue;

	c.send_email = send_email.toggle.on;
	c.email=email.textField.text;
	c.beep_pc = beep_pc.toggle.on;
	c.beep_pc_tts = use_speech.toggle.on;
	c.beep_pc_vibrate = vibrate.toggle.on;
	c.send_tweet = send_tweet.toggle.on;
	
	[self.delegate optionViewSaveBtnClicked:self];
}

-(void)armDisarmLightSensorAsNeededWithApplyAll:(BOOL)applyAll{
	if((_tag.lightEventState==LightDisarmed && monitor_light.toggle.on) ||
	   (monitor_light.toggle.on && (enhanced_monitoring_option_changed|| fabs(1-old_th_low/self.config.lux_th_low)>1e-5 || fabs(1-old_th_high/self.config.lux_th_high)>1e-5)))
		if(applyAll)
			[_lightDelegate armLightSensorForAllTags];
		else
			[_lightDelegate armLightSensorForTag:_tag];
		else if(_tag.lightEventState!=LightDisarmed && !monitor_light.toggle.on){
			if(applyAll)
				[_lightDelegate disarmLightSensorForAllTags];
			else
				[_lightDelegate disarmLightSensorForTag:_tag];
		}
}

-(void)updateLightRangeSlider{
	
	NSUInteger i = light_scale.range_index;
	light_range.slider.maximumValue = max_range_values[i];
	light_range.slider.minimumValue = min_range_values[i];
	light_range.slider.minimumRange =(max_range_values[i])/200;
	light_range.slider.stepSize = (max_range_values[i])/2000;

	[light_range sliderValueChanged:nil];
	
	[UIView animateWithDuration:0.4
					 animations:^{
						 [light_range.slider layoutIfNeeded];
					 }];

}
static int monitor_interval_choices[] ={15, 30, 60, 90, 120, 180, 300};

-(NSArray*)monitor_interval_labels{
	NSArray* labels =@[NSLocalizedString(@"15 seconds",nil), NSLocalizedString(@"30 seconds",nil), NSLocalizedString(@"1 minute",nil), NSLocalizedString(@"90 seconds",nil),
					   NSLocalizedString(@"2 minute",nil), NSLocalizedString(@"3 minute",nil), NSLocalizedString(@"5 minute",nil)];
	return labels;
}

-(void)setConfig:(NSMutableDictionary *)c andTag:(NSMutableDictionary*)tag
{
	[super view];

	enhanced_monitoring_option_changed=NO;
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];
	
	light_range.slider.forceInRange=NO;
	light_range.slider.selectedMaximumValue =c.lux_th_high;
	light_range.slider.selectedMinimumValue=c.lux_th_low;
	light_range.slider.currentValue = tag.lux;
	
	for(int i=0;i<sizeof(min_range_values)/sizeof(float);i++){
		if(min_range_values[i]<=c.lux_th_low && max_range_values[i]>c.lux_th_low){
			light_scale.range_index = i;
			[self updateLightRangeSlider];
			break;
		}
	}

	send_email.toggleOn = c.send_email;
	send_tweet.toggleOn = c.send_tweet;
	if( !c.email.isEmpty) email.textField.text = c.email;
	else email.textField.text=c.loginEmail;
	beep_pc.toggleOn= c.beep_pc;
	use_speech.toggleOn=c.beep_pc_tts; vibrate.toggleOn=c.beep_pc_vibrate;
	apns_sound.textField.text = c.apnsSound.isEmpty?apns_sound_choices[0]:c.apnsSound;
	apns_pause.textField.text = apns_pause_choices[ c.apns_pause_index ];
		
	int selected=1;
	for(int i=0;i<sizeof(monitor_interval_choices)/sizeof(int);i++)
		if(monitor_interval_choices[i]== c.th_monitor_interval){
			selected=i; break;
		}
	interval.textField.text =[[self monitor_interval_labels] objectAtIndex:selected];
	
	th_high_delay.textField.text = [NSString stringWithFormat:NSLocalizedString(@"%@ readings",nil), [c objectForKey:@"th_high_delay"]];
	th_low_delay.textField.text = [NSString stringWithFormat:NSLocalizedString(@"%@ readings",nil), [c objectForKey:@"th_low_delay"]];
	
	self.tag= tag;
	monitor_light.toggleOn = (tag.lightEventState!=LightDisarmed);
	
	[self updateCellArray];

	[super setConfig:c];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	monitor_light = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Monitor Brightness",nil) helpText:nil delegate:self];
	light_range = [IASKPSDualSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"< Normal Range <",nil) Min:-1 	Max:80000 Unit:@"lx" numberFormat:@"%.5g" delegate:self];
	light_scale = [IASKPSLuxRangeSpecifierViewCell newWithTitle:NSLocalizedString(@"Range:",nil) delegate:self];
	
	email =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Enter Email Addresses",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"\tto:" delegate:self];
	send_email = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Email",nil) helpText:NSLocalizedString(@"The tag will send you email when ambient light becomes too bright, too dark or back to normal range.",nil) delegate:self];
	send_tweet = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Post Tweet",nil) helpText:NSLocalizedString(@"The tag will tweet on behalf of you when ambient light becomes too bright, too dark or back to normal range.",nil) delegate:self];
	tweetLogin = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Twitter Login",nil) Progress:NSLocalizedString(@"Redirecting",nil)];
	
	beep_pc = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"Send Push Notification",nil) helpText:NSLocalizedString(@"Send push notifications to iOS/Android devices chosen at 'Phone Options' when ambient light becomes too bright, too dark or back to normal range.",nil) delegate:self];
	use_speech = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tUse Speech",nil) helpText:NSLocalizedString(@"Instead of a simple beep, speak the name of the tag and the event at your iOS device (when app is open) and Android device (always) with the push notification.",nil) delegate:self];
	vibrate = [IASKPSToggleSwitchSpecifierViewCell newWithTitle:NSLocalizedString(@"\tSilent/No-sound",nil) helpText:NSLocalizedString(@"Do no play any sound together with the push notification.",nil)  delegate:self];
	apns_sound = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPush Notification Sound: ",nil)];
	apns_pause =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"\tPause Action Effective For: ",nil)];
	
	interval =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Check brightness every: ",nil)];
	th_high_delay =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too-bright after consecutive: ",nil)];
	th_low_delay =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Notify too-dark after consecutive: ",nil)];
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
	return monitor_light.toggleOn?2:1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return  section==0?NSLocalizedString(@"Brightness Triggers",nil):NSLocalizedString(@"Notifications",nil);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)
		return monitor_light.toggleOn? 6:1;
	else
		return self.cellArray.count;
}

-(void) editedTableViewCell:(UITableViewCell*)cell{
	_modified=YES;
	if(cell==light_scale){
		[self updateLightRangeSlider];
	}
	else if(cell == send_email){
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
		[self animateCellPresence:use_speech fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_pause fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:apns_sound fromArray:oldCells toArray:self.cellArray];
		[self animateCellPresence:vibrate fromArray:oldCells toArray:self.cellArray];
		[self.tableView endUpdates];
		[self scheduleRecalculatePopoverSize];
		
	}else if(cell==monitor_light){
		[self.tableView beginUpdates];
		[monitor_light updateToggleOn];
		NSArray* ips = @[[NSIndexPath indexPathForRow:1 inSection:0],[NSIndexPath indexPathForRow:2 inSection:0],
						 [NSIndexPath indexPathForRow:3 inSection:0],[NSIndexPath indexPathForRow:4 inSection:0],[NSIndexPath indexPathForRow:5 inSection:0]];
		if(monitor_light.toggle.on){
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
		}else{
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
		}
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
	
	[cells addObject:send_email];
	if(send_email.toggleOn){
		[cells addObject:email];
	}
	[cells addObject:beep_pc];
	if(beep_pc.toggleOn){
		[cells addObject:use_speech];
		[cells addObject:apns_pause];
		[cells addObject:apns_sound];
		[cells addObject:vibrate];
	}
	[cells addObject:send_tweet];
	if(send_tweet.toggleOn)
		[cells addObject:tweetLogin];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.section==0){
		switch(ip.row){
			case 0: return monitor_light;
			case 1: return light_scale;
			case 2: return light_range;
			case 3: return interval;
			case 4: return th_low_delay;
			case 5: return th_high_delay;
			default: return nil;
		}
	}else
		return [self.cellArray objectAtIndex:ip.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	[tableView deselectRowAtIndexPath:ip animated:YES];
	
	OptionPicker *picker=nil;

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
													  } helpText:NSLocalizedString(@"Swipe left on a notification of 'Too Bright' or 'Too Dark', etc. events to see 'Pause' and 'Stop Monitoring' button. 'Pause' to temporarily stop receiving brightness notification but still keep populating Event History. 'Stop monitoring' will temporarily disable brightness monitoring. Here you can choose the time after which to automatically resume receiving events or re-enable monitoring.",nil)] autorelease];
		}
		else if(cell==interval){
			
			int selected=1;
			for(int i=0;i<sizeof(monitor_interval_choices)/sizeof(int);i++)
				if(monitor_interval_choices[i]== self.config.th_monitor_interval){
					selected=i; break;
				}
			picker = [[[OptionPicker alloc]initWithOptions:[self monitor_interval_labels]
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  interval.textField.text =[[self monitor_interval_labels] objectAtIndex:selected_new];
														  self.config.th_monitor_interval = monitor_interval_choices[selected_new];
														  enhanced_monitoring_option_changed=(selected_new!=selected);
													  } helpText:NSLocalizedString(@"Choose a shorter value to sample brightness more frequently, with a slightly reduced battery life. Measurement are not transmitted (which costs battery life) until after crossing a threshold boundary (for the specified number of times).",nil)] autorelease];
			
		}
		else if(cell==th_high_delay || cell==th_low_delay){
			NSString* key =  cell==th_high_delay?@"th_high_delay":@"th_low_delay";
			static int choices[99];
			NSMutableArray* labels = [[NSMutableArray alloc]initWithCapacity:99];
			for(int i=1;i<=99;i++){
				choices[i-1]=i;
				[labels addObject:[NSString stringWithFormat:NSLocalizedString(@"%d readings",nil), i]];
			}
			int selected=[[self.config objectForKey:key] intValue]-1;
			picker = [[[OptionPicker alloc]initWithOptions:labels
												  Selected:selected
													  Done:^(NSInteger selected_new, BOOL now){
														  ((IASKPSTextFieldSpecifierViewCell*)cell).textField.text = [labels objectAtIndex:selected_new];
														  [self.config setObject:[NSNumber numberWithInteger:selected_new+1] forKey:key];
														  enhanced_monitoring_option_changed=(selected!=selected_new);
													  } helpText:NSLocalizedString(@"If you don't want to get notified when it gets too bright or too dark for only a short period of time, choose a value larger than 1.",nil) ] autorelease];
		}
		else if(cell==tweetLogin){
			[self.delegate optionViewTwitterLoginBtnClicked:tweetLogin];
		}
	if(picker!=nil)
		[super presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:ip]];
	
}
@end
