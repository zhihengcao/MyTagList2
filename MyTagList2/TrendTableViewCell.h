//
//  TrendTableViewCell.h
//  WirelessTag
//
//  Created by cao on 3/21/19.
//

#import <UIKit/UIKit.h>
#import "SingleTagChart.h"

@interface TrendTableViewCell : UITableViewCell{
	int redrawn;
}
@property (retain, nonatomic) IBOutlet UIImageView *image;
@property (retain, nonatomic) IBOutlet UILabel *lux_unit;
@property (retain, nonatomic) IBOutlet UILabel *timestamp;
@property (retain, nonatomic) IBOutlet SingleTagChart *chart;
@property (retain, nonatomic) IBOutlet UITextView *name;
@property (retain, nonatomic) IBOutlet UILabel *temp;
@property (retain, nonatomic) IBOutlet UILabel *cap_unit;
@property (retain, nonatomic) IBOutlet UILabel *cap;
@property (retain, nonatomic) IBOutlet UILabel *lux;
@property (retain, nonatomic) IBOutlet UILabel *temp_unit;
@property (retain, nonatomic) NSDictionary *trend;
@property (retain, nonatomic) NSArray *span;
@property (assign, nonatomic) BOOL useDegF;

-(void)setTrend:(NSDictionary*)t useDegF: (BOOL)useDegF andFiletimeSpan:(NSArray*)span;

@end
