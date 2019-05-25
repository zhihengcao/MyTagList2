//
//  TempOptionsViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"
#import "IASKPSDualSliderSpecifierViewCell.h"

@protocol TempOptionsViewControllerDelegate <NSObject>
@required
-(void)tempCalibrateBtnClickedForTag:(NSMutableDictionary*)tag Temperature:(float)degC BtnCell:(id)sender ThresholdSlider:(RangeSlider*)thresholdSlider useDegF:(bool)useDegF;
-(void)armTempsensorForTag:(NSDictionary*)tag;
-(void)armTempsensorForAllTags;
-(void)disarmTempsensorForTag:(NSDictionary*)tag;
-(void)disarmTempsensorForAllTags;
@end

// [units  (celsius, farenheit)]
// [calibrate current temperature (slider, calibrate btn)]
// [monitor temperature (0:on/off, 1:range, 2:send email->3:address, (3/4):send tweet->(4/5)tweet login (4-6):ringpc->( (5-7):usespeech, (6-8):vib))  
@interface TempOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	NSArray* temp_unit_choices;
	BOOL enhanced_monitoring_option_changed;
	
	IASKPSTextFieldSpecifierViewCell* temp_units;
	IASKPSSliderSpecifierViewCell *temp_cal, *threshold_window;
	TableLoadingButtonCell* temp_cal_btn, *temp_uncal_btn;
	IASKPSDualSliderSpecifierViewCell *temp_range;
	
	IASKPSTextFieldSpecifierViewCell *email;
	IASKPSToggleSwitchSpecifierViewCell *monitor_temp, *send_email, *send_tweet, *beep_pc, *use_speech, *vibrate, *notify_normal;
	TableLoadingButtonCell* tweetLogin;
	IASKPSTextFieldSpecifierViewCell *apns_sound, *interval, *th_low_delay, *th_high_delay, *apns_pause, *rn_toohot, *rn_toocold;

	float old_th_low, old_th_high;
}
-(void)setConfig:(NSMutableDictionary *)c andTag:(NSMutableDictionary*)tag;
-(void)armDisarmTempsensorAsNeededWithApplyAll:(BOOL)applyAll;

@property (nonatomic, retain) NSMutableDictionary* rnc_toohot;
@property (nonatomic, retain) NSMutableDictionary* rnc_toocold;

@property(nonatomic, retain) 	NSMutableArray* cellArray;
@property(nonatomic,assign) id<TempOptionsViewControllerDelegate> tempDelegate;
@property(nonatomic, retain) NSMutableDictionary* tag;
@property(nonatomic, retain) NSString* loginEmail;
@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;
@end

