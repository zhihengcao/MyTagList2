//
//  RawDataChart.h
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import <ShinobiCharts/ShinobiCharts.h>
#import "SpinnerView.h"

extern NSString * const LogScalePrefKey;
extern NSDate* nsdateFromFileTime(int64_t filetime);
extern BOOL temp_unit;
extern int ZoomLevelFromTI(NSTimeInterval ti);
extern NSString * const graphTIPrefix;

@protocol StatTypeTranslator <NSObject>
@required
-(NSString*)name;
-(NSString*)tooltipGen:(float)deg;
-(NSString*)labelFormat;
-(NSNumber*)preProcess:(NSNumber*)degC;
-(float)ymaxInit;
-(float)ymaxPost:(float)ymax;
-(float)yminInit;
-(float)yminPost:(float)ymin;
+(id<StatTypeTranslator>)instance;
@end

extern id<StatTypeTranslator> findTranslator(NSString* type);

typedef NS_ENUM(NSInteger, ChartZoomLevel) {
	ChartZoomLevelRaw=0,
	ChartZoomLevelRaw2=1,
	ChartZoomLevelRaw3=2,
	ChartZoomLevelNormal=3,
	ChartZoomLevelBand=4
};

typedef void (^loadDone_t)();
typedef void (^onDataSpan)(NSDictionary* metadata);
typedef void (^asyncLoadSpan_t)(onDataSpan done);

typedef void (^onHourlyData)(NSMutableDictionary* dataDays);
typedef void (^asyncLoadHourlyData_t)(onHourlyData done);

typedef NSArray* (^syncLoadRawData_t)(NSString* startDate, NSString* endDate);

@interface MultiDayAxis :  SChartDateTimeAxis// SChartDiscontinuousDateTimeAxis
+(NSDate*) dateFromString:(NSString*)date ;
+(NSDate*) dateWithoutTime:(NSDate*)date ;
+(NSString*) stringFromDate:(NSDate*)date ;
//-(id)initWithDataDays:(NSArray*) days andFont:(UIFont*)font;
-(id)initWithEarliest:(NSDate*) min andLastest:(NSDate*)max andFont:(UIFont*)font;

@end

@interface RawDataChart: ShinobiChart <SChartDelegate>
{
	ChartZoomLevel _zoomLevel;
	NSMutableArray* rawDataDates, *rawData;  // cache
	dispatch_queue_t queue;
	float ymax2, ymin2;
	int translatedStart, translatedEnd;
	int queue_length;
	BOOL noDynamicLoading;
}
@property (nonatomic, assign)BOOL dewPointMode;
@property(nonatomic, assign) BOOL useLogScaleForLight;
@property (nonatomic, assign)BOOL capIsChipTemperatureMode;

// implemented by subclasses
-(void)updateMetadata:(NSDictionary *)d;
-(void)zoomLevelChanged;  // calls redraw
-(void)setRawDataMultipleDays: (NSArray*) dataDays;

-(void)justShownCompleteDay:(NSDate*)date;

-(void)enteredNormalLevelWithRange:(SChartDateRange*)range done:(loadDone_t)done;
-(void)enteredRawLevelWithRange:(SChartDateRange*)range done:(loadDone_t)done;
-(void)updateZoomPan:(SChartDateRange*) range Done:(loadDone_t)done;
-(void)updateZoomPanMinDate:(NSDate*)min MaxDate:(NSDate*)max Done:(loadDone_t)done;
-(void)setupYAxis:(SChartAxis*)axis;
-(void)setMultiDayXAxis;

@property(nonatomic)BOOL askForReview;

@property (nonatomic, retain)	SpinnerView* spinner;

@property(nonatomic, assign)ChartZoomLevel zoomLevel;
@property(nonatomic, assign)id<StatTypeTranslator> type;
@property(nonatomic, retain) NSDate* latestDate, *earliestDate, *completeDate;

@property(nonatomic,retain) NSDate* pendingStartDate;
@property(nonatomic,retain) NSDate* pendingEndDate;
@property(nonatomic,copy) syncLoadRawData_t dataLoader;
@property(nonatomic,copy) asyncLoadHourlyData_t hourlyDataLoader;
@property(nonatomic,copy) asyncLoadSpan_t spanLoader;

@property(nonatomic,copy) loadDone_t onLoadDone;

@property(nonatomic, retain) NSMutableDictionary* hourlyData; // includes metadata.

@end

@interface MotionEventTickFormatter : SChartTickLabelFormatter
+ (MotionEventTickFormatter*)instance;
@end

@interface LuxTickFormatter : SChartTickLabelFormatter
+ (LuxTickFormatter*)instance;
@end

@interface RecentTrendTimeTickFormatter : SChartTickLabelFormatter
+ (RecentTrendTimeTickFormatter*)instance;
@end


@interface SignalTypeTranslator : NSObject <StatTypeTranslator>
@end
@interface LuxTypeTranslator : NSObject <StatTypeTranslator>
@end

@interface MotionTypeTranslator : NSObject <StatTypeTranslator>
@end
@interface BattTypeTranslator : NSObject <StatTypeTranslator>
@end
@interface TimeOfDayAxis : SChartDateTimeAxis
+(NSDate*) baseDate;
-(id)initWithFont:(UIFont*)font forTrend:(BOOL)forTrend;
@end
@interface CapTypeTranslator : NSObject <StatTypeTranslator>
@property(nonatomic)BOOL dewPointMode;
@end
@interface TemperatureTypeTranslator : NSObject <StatTypeTranslator>
@end
@interface DewPointTypeTranslator : NSObject <StatTypeTranslator>
@end

@interface NSMutableArray (ChartSeries)
-(void)addDataPoint:(SChartDataPoint*)dataPoint;
-(void)addDailyDataPoint:(SChartMultiYDataPoint*)dataPoint;
@end
