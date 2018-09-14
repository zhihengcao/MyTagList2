//
//  TempOptionsViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"

#import "OptionsViewController.h"
#import "IASKPSDualSliderSpecifierViewCell.h"

@protocol CapOptionsViewControllerDelegate <NSObject>
@required
-(void)capCalibrateBtnClickedForTag:(NSMutableDictionary*)tag Cap:(float)RH BtnCell:(id)sender;
-(void)capResetCalibrateBtnClickedForTag:(NSMutableDictionary*)tag BtnCell:(id)sender;
-(void)armCapSensorForTag:(NSDictionary*)tag;
-(void)armCapSensorForAllTags;
-(void)disarmCapSensorForTag:(NSDictionary*)tag;
-(void)disarmCapSensorForAllTags;
-(void)dewPointModeChanged;
-(void)saveWaterSensorConfig:(NSMutableDictionary*)config;
@end

// [units  (celsius, farenheit)]
// [calibrate current temperature (slider, calibrate btn)]
// [monitor temperature (0:on/off, 1:range, 2:send email->3:address, (3/4):send tweet->(4/5)tweet login (4-6):ringpc->( (5-7):usespeech, (6-8):vib))  
@interface CapOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	NSArray* responsiveness_choices;
	NSArray* cap_unit_choices;
	
	IASKPSSliderSpecifierViewCell *cap_cal;
	IASKPSDualSliderSpecifierViewCell *cap_range;
	
	TableLoadingButtonCell* cap_cal_btn, *cap_uncal_btn;
	IASKPSTextFieldSpecifierViewCell* responsiveness;
	IASKPSTextFieldSpecifierViewCell *email, *email_cap2;
	IASKPSToggleSwitchSpecifierViewCell *monitor_cap, *send_email, *send_email_cap2, *send_tweet, *send_tweet_cap2, *beep_pc, *beep_pc_cap2,
	*use_speech, *use_speech_cap2, *vibrate, *vibrate_cap2, *notify_open_cap2;

	IASKPSTextFieldSpecifierViewCell* cap_units;

	IASKPSTextFieldSpecifierViewCell *apns_sound, *apns_sound_cap2,*apns_pause, *rn_toowet, *rn_toodry, *rn_cap2;
	TableLoadingButtonCell* tweetLogin, *tweetLogin_cap2;
	float old_th_low, old_th_high;
}
-(void)setConfig:(NSMutableDictionary *)c2 andTag:(NSMutableDictionary*)tag;
-(void)updateTag:(NSMutableDictionary*)tag;
-(void)armDisarmCapsensorAsNeededWithApplyAll:(BOOL)applyAll;

@property (nonatomic, retain) NSMutableDictionary* rnc_toowet;
@property (nonatomic, retain) NSMutableDictionary* rnc_toodry;
@property (nonatomic, retain) NSMutableDictionary* rnc_cap2;
@property(nonatomic, assign)BOOL rnc_cap2_changed;

@property(nonatomic,assign) id<CapOptionsViewControllerDelegate> capDelegate;
@property(nonatomic, retain) NSMutableDictionary* tag;
@property(nonatomic, retain) NSString* loginEmail;
@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;

@property (nonatomic, retain) NSMutableDictionary* cap2Config;

@end

