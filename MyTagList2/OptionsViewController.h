//
//  OptionsViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKPSSliderSpecifierViewCell.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKPSToggleSwitchSpecifierViewCell.h"
#import "TableTBViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NSTimer+Blocks.h"

extern BOOL dewPointMode;
extern NSString* const dewPointModeKey;
extern float dewPoint(float RH, float T);

extern int chosen_temp_unit;
static NSString* apns_sound_choices[] = {@"Default", @"Quack", @"Single Click", @"Sosumi", @"Temple", @"Uh oh", @"Voltage", @"Whit", @"Wild Eep",
	@"moof", @"Bip", @"Boing", @"ChuToy", @"Clink-Klank", @"Droplet", @"Indigo", @"Laugh", @"Monkey", @"Computer Error", @"Door Bell",
	@"Door Chime", @"Honk", @"Solemn", @"Thin Air", @"Train Horn", @"Your Turn", @"End Fx", @"Door Buzzer",
@"Bottle Rocket", @"Bell Sound Ring", @"Answering Machine", @"Munchausen", @"Laser Blasts", @"Ice Cubes"
	@"Metal Pan", @"Power Off Computer", @"Time Travel", @"Zoom", @"Alarm Frenzy"
};
static NSString* oor_grace_choices[]={@"Immediately notify",@"Notify after 2 minute",@"Notify after 4 minute",@"Notify after 6 minute",@"Notify after 8 minute",@"Notify after 10 minute",
	@"Notify after 14 minute",@"Notify after 20 minute",@"Notify after 30 minute"};
static int oor_grace_values[] = {0,1,2,3,4,5,7,10,15};

static NSString* apns_pause_choices[]={@"5 minute",@"10 minute",@"15 minute",@"30 minute",@"1 hour",@"2 hour",
	@"4 hour",@"8 hour",@"12 hour",@"24 hour",@"48 hour"};
static int apns_pause_values[] = {5,10,15,30,60,120,240,480,720,1440,2880};

static int rnc_timespan_values[]={0, 600, 900, 1800, 3600, 7200, 14400, 28800};
static NSString* rnc_timespan_choices[]= {@"Just once", @"Every 10 minute",@"Every 15 minute",@"Every 30 minute",@"Every hour",@"Every 2 hour", @"Every 4 hour", @"Every 8 hour"};

@interface NSMutableDictionary (MSConfig)
@property (nonatomic) int auto_reset_delay;
@property (nonatomic) BOOL beep_pc;
@property (nonatomic) BOOL beep_pc_loop;
@property (nonatomic) BOOL beep_pc_oor;
@property (nonatomic) BOOL beep_pc_tts;
@property (nonatomic) BOOL notify_normal;
@property (nonatomic) BOOL beep_pc_tts_oor;
@property (nonatomic) BOOL beep_pc_vibrate;
@property (nonatomic) BOOL beep_pc_vibrate_oor;
@property (nonatomic) BOOL beep_tag;
@property(nonatomic)BOOL notify_open;

@property(nonatomic)BOOL silent_arming;
//@property (nonatomic) BOOL beep_tag_autostop;
@property (nonatomic) BOOL door_mode;
@property(nonatomic) BOOL hmc_timeout_mode;
@property (nonatomic) float door_mode_angle;
@property (nonatomic) int door_mode_delay;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *email_oor;
@property (nonatomic) int interval; // 1,2,3,4,5
@property (nonatomic) int th_monitor_interval;
@property (nonatomic) int intervalSec;

@property (nonatomic, retain) NSArray *mobile_notifications; //: [{uuid:ffffffff-fdec-c798-ffff-ffffca2cbb0c, name:LG-P350a, disabled:false}]
@property (nonatomic) BOOL send_email;
@property (nonatomic) BOOL send_tweet;
@property (nonatomic) BOOL send_email_on_close;
@property (nonatomic) BOOL send_email_oor;
@property (nonatomic) int sensitivity; //: 32
@property (nonatomic) int sensitivity2; //: 32
@property (nonatomic) int aa1_tod, aa2_tod, ada1_tod, ada2_tod, aa1_dow, aa2_dow;
@property (nonatomic) BOOL aa1_en, aa2_en;
@property (nonatomic) int tzo;
@property(nonatomic) int apns_pause;
-(int) apns_pause_index;

@property(nonatomic, readonly) BOOL isMsConfig;
@property(nonatomic, readonly) BOOL isTempConfig;
@property(nonatomic, readonly) BOOL isCapConfig;
@property(nonatomic, readonly) BOOL isLightConfig;
@property(nonatomic, readonly) BOOL isKumostatConfig;
@property(nonatomic, readonly) BOOL isOorConfig;
@property(nonatomic, readonly) BOOL isPhonesConfig;
@property(nonatomic, readonly) BOOL isLBConfig;

@property (nonatomic) float threshold;
@property (nonatomic) BOOL enabled;
@property (nonatomic) int notify_every;

@property (nonatomic, retain) NSString *apnsSound;
-(int) apns_sound_index;

@property (nonatomic, retain) NSString *loginEmail;
@property (nonatomic, retain) NSString *loginPwd;
@property (nonatomic, retain) NSString *twitterID;
@property (nonatomic, retain) NSString *twitterPwd;
@property (nonatomic) BOOL allowMore;
@property(nonatomic, readonly) BOOL isAccountConfig;

//@property (nonatomic, retain) NSMutableDictionary *oor; //: {title:"", detail:""}
//@property (nonatomic, retain) NSMutableDictionary *motion_detected, *door_opened, *door_closed, *door_open_toolong;
//@property (nonatomic, retain) NSMutableDictionary *temp_toohigh, *temp_toolow, *temp_normal;
@property(nonatomic, readonly) BOOL isMessageConfig;

@property(nonatomic) float th_window;
@property(nonatomic) float th_low;
@property(nonatomic) float th_high;
@property(nonatomic) int temp_unit;

@property(nonatomic) float lux_th_low;
@property(nonatomic) float lux_th_high;

-(int) door_mode_delay_index;
-(int) auto_reset_delay_index;
-(int) pir_reset_delay_index;
-(int) notify_every_index;

@end
@class OptionPicker;

@class OptionsViewController;

@protocol OptionsViewControllerDelegate <NSObject>
@required
-(void)optionViewSaveBtnClicked:(OptionsViewController*)opv;
-(void)optionViewTwitterLoginBtnClicked:(TableLoadingButtonCell*)btncell;
-(void)optionViewWebAccountBtnClicked:(TableLoadingButtonCell*)btncell;
-(void)optionEarnReferralBtnClicked:(TableLoadingButtonCell*)btncell;
- (void)disarmBtnPressed:(id)sender;
- (void)armBtnPressed:(id)sender withConfig:(NSDictionary*)config;
@end

@interface OptionsViewController : TableTBViewController 
{
	UIPopoverController *popoverController;
	AVAudioPlayer* apnsSoundPlayer;
}
-(void)scheduleRecalculatePopoverSize;

-(void)presentPicker:(OptionPicker*)picker fromCell:(UITableViewCell*)cell;
-(void)playAiff:(NSInteger)index;

@property(nonatomic,retain)NSMutableArray* updatedRepeatNotifyConfigs;

@property(nonatomic,assign) id<OptionsViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary* config;
//@property (nonatomic, assign) UIPopoverController *popoverContainer;
- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate;
@end

// [triggering condition (sensitivity, responsiveness, doormode_on_off, threshold_angle_slider)]
// [when moved/opened (when tag movement is detected/when has been opened for x, send email, address, send_tweet, account, also, ringpc, usespeech, keep, vib, tagbeep)  
// [Arm/disarm Schedule1 (enable schedule 1, disarm at (choices), arm at (choices), sun,mon,tue,wed,thur,fri,sat)
// [Arm/disarm Schedule2 (enable schedule 1, disarm at (choices), arm at (choices), sun,mon,tue,wed,thur,fri,sat)
#import "ActionSheetDatePicker.h"

enum ArmDisarmSwitchState
{
	ArmDisarmSwitchStateHidden = 0,
	ArmDisarmSwitchStateOn,       // Invalid configuration
	ArmDisarmSwitchStateOff
};
typedef enum ArmDisarmSwitchState ArmDisarmSwitchState;

@interface MSOptionsViewController : OptionsViewController<IEditableTableViewCellDelegate>
{
	NSDateFormatter *tod_f;
	NSArray* responsiveness_choices, *responsiveness_choices_accel;
	NSArray *trigger_delay_choices, *auto_reset_choices, *pir_reset_choices;
	NSArray* day_of_week;
	//NSMutableArray *tod_choices, *tod_min_utc;
	
	IASKPSSliderSpecifierViewCell* sensitivity,*sensitivity2, *threshold_angle;
	IASKPSTextFieldSpecifierViewCell* responsiveness, *email;
	UITableViewCell* trigger_delay, *auto_reset_delay; 
	TableLoadingButtonCell* open_account_btn; 
	IASKPSTextFieldSpecifierViewCell *aa1_tod, *ada1_tod, *aa2_tod, *ada2_tod;
	IASKPSTextFieldSpecifierViewCell *apns_sound, *apns_pause, *rn_open, *rn_detected;
	IASKPSToggleSwitchSpecifierViewCell *door_mode, *hmc_timeout_mode, *send_email, *send_tweet, *send_email_close, *beep_pc, *use_speech, *beep_pc_loop,
	*vibrate, /* *beep_tag, */ *en_aa1, *en_aa2, *silent_arm;
	IASKPSToggleSwitchSpecifierViewCell *arm_disarm;
}
+(NSDate*)tod2NSDate:(int)tod;
+(int)NSDate2tod:(NSDate*)date;
+(NSDate *)roundDateTo15Minutes:(NSDate *)mydate;

@property (nonatomic, retain) NSMutableDictionary* rnc_open;
@property (nonatomic, retain) NSMutableDictionary* rnc_detected;

@property(nonatomic, retain) NSString* loginEmail;
@property (nonatomic, readonly) BOOL modified;
@property (nonatomic, assign) ArmDisarmSwitchState armDisarmState;
@property (nonatomic, assign) BOOL isReedPir;
@property (nonatomic, assign) BOOL isAccel;
@property (nonatomic, assign) BOOL isALS;
@property (nonatomic, assign) BOOL isPir;
@property (nonatomic, assign) BOOL isPir8F;
@property (nonatomic, assign) BOOL isHmcTimeout;
-(void) editedTableViewCell:(id)cell;
@end

// [when out of range (email, addr, tweet, login, ringpc, usespeech, vib)
@interface OorOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	IASKPSTextFieldSpecifierViewCell *email_oor;
	IASKPSTextFieldSpecifierViewCell *apns_sound, *oor_grace;
	int _oor_grace_selected_index;
	
	IASKPSToggleSwitchSpecifierViewCell *send_email_oor, *send_tweet, *beep_pc_oor, *use_speech_oor, *vibrate_oor;
	TableLoadingButtonCell* tweetLogin;
}
@property(nonatomic, retain) NSString* loginEmail;
@property (nonatomic, readonly) BOOL modified;
@property(nonatomic)int oorGrace;
-(void) editedTableViewCell:(id)cell;
@end

// [when out of range (email, addr, tweet, login, ringpc, usespeech, vib)
@interface LbOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	IASKPSSliderSpecifierViewCell* threshold;
	IASKPSTextFieldSpecifierViewCell *email;
	IASKPSTextFieldSpecifierViewCell* notify_every;
	IASKPSToggleSwitchSpecifierViewCell *send_email, *send_tweet, *beep_pc, *use_speech, *vibrate, *enabled;
	IASKPSTextFieldSpecifierViewCell *apns_sound;
	TableLoadingButtonCell* tweetLogin;
	
	NSArray* notify_every_choices;
}
@property(nonatomic, retain) NSString* loginEmail;
@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;
@end


// [enable notifications on () ] 
@interface PhoneOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	NSMutableArray* mobile_notifications;
}
@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;
@end


