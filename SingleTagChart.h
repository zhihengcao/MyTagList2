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

@interface SingleTagChart : RawDataChart <SChartDatasource>
{
	
	SChartNumberAxis* temperatureAxis, *capAxis; //, *batteryVoltAxis;
	SChartLogarithmicAxis* logAxis;
	
	NSMutableArray* tempSeries, *capSeries, *luxSeries; //, *battSeries;  // normal data
	NSMutableArray* rawTempSeries, *rawCapSeries, *rawLuxSeries; // zoom data
	NSMutableArray* bandTempSeries, *bandCapSeries, *bandLuxSeries;
	
	float secondaryAxisMin, secondaryAxisMax;
}
- (void) setDataSingleDay:(NSDictionary*) statsEachHour;  // ethLogs+TemperatureEachHour
-(void)setDataMultipleDays: (NSArray*) dataDays withZoom:(SChartDateRange*)range;

@property (nonatomic, assign)BOOL hasALS;
@property (nonatomic, retain)NSMutableDictionary* date2DLI;

@end
