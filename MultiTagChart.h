//
//  MultiTagChart.h
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "RawDataChart.h"
#import "iToast.h"
#import "NSData+Base64.h"

@interface MultiTagChart : RawDataChart <SChartDatasource>
{
	NSFormatter* org_formatter;
	NSMutableDictionary* id2BandSeries;
	NSMutableDictionary* id2RawSeries;
	NSMutableDictionary* id2Series;   // tag id -> series data mapping
	NSMutableArray *arrayOfIds;   // series # -> tag id mapping.
	NSDictionary* statTypeTranslation;
}
-(id)initWithFrame:(CGRect)frame andType:(id<StatTypeTranslator>)type;
-(void)updateMetadata:(NSDictionary*)d;

@property(nonatomic, retain)NSArray* colors;
@property(nonatomic, retain)NSMutableDictionary* id2nameMapping;
- (void) setDataSingleDay:(NSDictionary*) hourlyStatDay andMapping:(NSMutableDictionary*)mapping;
@property (nonatomic, retain)NSMutableDictionary* date2DLI;

@end
