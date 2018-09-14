#import <UIKit/UIKit.h>
#import <ShinobiCharts/ShinobiChart.h>
#import "TableTBViewController.h"
#import "ActionSheet+Blocks.h"
#import "SingleTagChart.h"
#import "MultiTagChart.h"

// responsible for holding either of above and set as background view with no marin.
@interface ChartTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>
{
}
@property(nonatomic, retain) RawDataChart* chart;
@end

@interface ShareTextDescription : UIActivityItemProvider
-(id)initWithUUID:(NSArray*)uuids andName:(NSString*)name andType:(NSString*)type fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;
@property (nonatomic, retain)NSString* iosURL;
@property (nonatomic, retain)NSString* webURL;
@end

@class GraphViewController;
typedef void (^shareHandler_t)(GraphViewController* vc, UIBarButtonItem* sender, UIImage* snapshot, NSDate* fromDate, NSDate* toDate);
typedef void (^logDownloader_t)(GraphViewController* vc, UIBarButtonItem* sender, NSString* fromDate, NSString* toDate);


@interface GraphViewController: TableTBViewController
{
	BOOL viewIsLandscape;
	BOOL isMultiTag;
}
@property(nonatomic, copy) syncLoadRawData_t dataLoader;
@property(nonatomic, copy) shareHandler_t shareHandler;
@property(nonatomic, copy) logDownloader_t logDownloader;
@property(nonatomic, assign)id<StatTypeTranslator> type;

-(void)setRangeWithMinimum:(NSDate*)min andMaximum:(NSDate*)max;
-(void)downloadButtonPressed:(id)sender;
@end


@interface DailyGraphViewController : GraphViewController
{
//	UIImageView* tooltipView;
}
// now daily graph always loads secondly if user taps daily button. 
//- (id)initPrimaryWithTitle:(NSString*) title andSpanLoader:(asyncLoadSpan_t)spanLoader andData:(NSDictionary*)data andType:(NSString*)type andDataLoader:(syncLoadRawData_t)loader;

- (id)initSecondaryWithTitle:(NSString*) title andData:(NSMutableDictionary*)data andType:(id<StatTypeTranslator>)type andDataLoader:(syncLoadRawData_t)loader;

+(void)showTooltipNamed:(NSString*)imageName fromView:(UIView*)superView;
@property(nonatomic)BOOL dewPointMode;
@property(nonatomic)BOOL capIsChipTemperatureMode;
@property(nonatomic,retain)NSDictionary* data;
@property(nonatomic,retain)NSMutableDictionary* date2DLI;
//@property (nonatomic, retain)	LandscapeGraphViewController* landscapeVC;
@property (nonatomic, retain)NSMutableDictionary* id2nameMapping;
@end
