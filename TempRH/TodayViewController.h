//
//  TodayViewController.h
//  TempRH
//
//  Created by cao on 10/29/15.
//
//

#import <UIKit/UIKit.h>
#import <NotificationCenter/NotificationCenter.h>

#import "AsyncURLConnection.h"
#import "Tag.h"
#import "NSTimer+Blocks.h"

typedef NS_ENUM(NSInteger, WidgetCellAuxMode) {
	AuxModeUpdatedAgo=0,
	AuxModeHumidity=1,
	AuxModeEventString=2
};

@interface TodayViewController : UITableViewController
@property(nonatomic) WidgetCellAuxMode currentAuxMode;
@property(nonatomic,retain)UITableViewCell *configBtn;
@property(nonatomic,retain)	NSTimer* updateTimer;
@property(nonatomic, copy) void (^updateCallback)(NCUpdateResult);
@end


#import <QuartzCore/CAGradientLayer.h>

@interface WidgetCell : UITableViewCell
{
}

- (void) setData:(NSDictionary*) tag forMode:(WidgetCellAuxMode)mode;

@property(nonatomic,assign) bool useDegF;
@property(nonatomic, retain) UILabel *tagAux;
@end