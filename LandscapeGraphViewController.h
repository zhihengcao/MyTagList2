//
//  LandscapeGraphViewController.h
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "DailyGraphViewController.h"
#import "RIButtonItem.h"
#import "UIAlertView+Blocks.h"

extern NSString * const LogScalePrefKey;

@interface LandscapeGraphViewController : GraphViewController <UISplitViewControllerDelegate>
{
	UIImage* bgImage, *shadowImage;
	float originalSplitViewRatio;
	
	//	id<UISplitViewControllerDelegate> org_spv_delegate;
}
// if type is nil, it is single tag chart.
- (id)initPrimaryWithTitle:(NSString*)title andFrame:(CGRect) frame andSpanLoader:(asyncLoadSpan_t)spanLoader andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader andType:(NSString*)type andDataLoader:(syncLoadRawData_t)loader;

//- (id)initSecondaryMultiTagWithFrame:(CGRect)frame Title:(NSString*)title andSpanLoader:(asyncLoadSpan_t)spanLoader andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader;

//- (id)initSecondarySingleTagWithFrame:(CGRect)frame Title:(NSString*)title andSpanLoader:(asyncLoadSpan_t)spanLoader andHourlyLoader:(asyncLoadHourlyData_t)hourlyLoader andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader;


@property(nonatomic, retain) RawDataChart* chart;
@property (nonatomic, retain)	DailyGraphViewController* portraitVC;
@end
