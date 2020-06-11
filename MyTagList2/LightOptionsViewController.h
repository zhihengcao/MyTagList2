//
//  LightOptionsViewController.h
//  MyTagList2
//
//  Created by cao on 8/7/16.
//
//

#import "OptionsViewController.h"


#import "IASKPSDualSliderSpecifierViewCell.h"
#import "IASKPSLuxRangeSpecifierViewCell.h"


@protocol LightOptionsViewControllerDelegate <NSObject>
@required
-(void)armLightSensorForTag:(NSDictionary*)tag;
-(void)armLightSensorForAllTags;
-(void)disarmLightSensorForTag:(NSDictionary*)tag;
-(void)disarmLightSensorForAllTags;
@end

// [monitor brightness (0:on/off, 1: category_choice 2:range, 3: responsiveness, 4 4:send email->3:address, (3/4):send tweet->(4/5)tweet login (4-6):ringpc->( (5-7):usespeech, (6-8):vib))
@interface LightOptionsViewController : OptionsViewController <IEditableTableViewCellDelegate>
{
	NSArray* responsiveness_choices;
	
	BOOL enhanced_monitoring_option_changed;
	IASKPSDualSliderSpecifierViewCell *light_range;
	
	IASKPSTextFieldSpecifierViewCell *email;
	IASKPSToggleSwitchSpecifierViewCell *monitor_light, *send_email, *send_tweet, *beep_pc, *use_speech, *vibrate, *apns_ca;
	TableLoadingButtonCell* tweetLogin;
	IASKPSTextFieldSpecifierViewCell *apns_sound, *interval, *th_low_delay, *th_high_delay, *apns_pause;

	IASKPSLuxRangeSpecifierViewCell* light_scale;
	
	float old_th_low, old_th_high;
}
-(void)setConfig:(NSMutableDictionary *)c2 andTag:(NSMutableDictionary*)tag;
-(void)armDisarmLightSensorAsNeededWithApplyAll:(BOOL)applyAll;

@property(nonatomic, retain) 	NSMutableArray* cellArray;
@property(nonatomic,assign) id<LightOptionsViewControllerDelegate> lightDelegate;
@property(nonatomic, retain) NSDictionary* tag;
@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;


@end
