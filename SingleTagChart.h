//
//  SingleTagChart.h
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "RawDataChart.h"
#import "iToast.h"
#import "OptionsViewController.h"
#define LUXCOLOR  [UIColor colorWithRed:(float)0x60/255.0 green:(float)0xa0/255.0 blue:(float)0xdf/255.0 alpha:1]
#define CAPCOLOR [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1]
#define TEMPCOLOR [UIColor redColor]

@interface SingleTagChart : RawDataChart <SChartDatasource>
{
	
	SChartNumberAxis* temperatureAxis, *capAxis, *luxAxis; //, *batteryVoltAxis;
	SChartLogarithmicAxis* logAxis;
	BOOL forTrend;
	
	NSMutableArray* tempSeries, *capSeries, *luxSeries; //, *battSeries;  // normal data
	NSMutableArray* rawTempSeries, *rawCapSeries, *rawLuxSeries; // zoom data
	NSMutableArray* bandTempSeries, *bandCapSeries, *bandLuxSeries;
	
	float capAxisMin, capAxisMax, luxAxisMin, luxAxisMax;
}
- (void) setDataSingleDay:(NSDictionary*) statsEachHour;  // ethLogs+TemperatureEachHour
-(void)setDataMultipleDays: (NSArray*) dataDays withZoom:(SChartDateRange*)range;
-(void)showRecentTrendFileTimes:(NSArray*)filetimes Temperatures:(NSArray*)temps Caps:(NSArray*)caps Lux:(NSArray*)lux tempRange:(NSArray*)tempRange capRange:(NSArray*)capRange luxRange:(NSArray*)luxRange dateRange:(NSArray*)dateRangeFiletime eventsToAnnotate:(NSArray*)events;

@property (nonatomic, assign)BOOL hasALS;
@property (nonatomic, assign)BOOL hasCap;
//-(BOOL) hasCap;
@property (nonatomic, retain)NSMutableDictionary* date2DLI;

@end
