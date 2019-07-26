//
//  RawDataChart.m
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "RawDataChart.h"
#import "AsyncURLConnection.h"
#import "Tag.h"

NSString * const graphTIPrefix = @"GraphTI";

#define EPOCH_DIFF 11644473600LL

NSDate* nsdateFromFileTime(int64_t filetime){
	return [NSDate dateWithTimeIntervalSince1970:((filetime / 10000000) - EPOCH_DIFF)];
}


@implementation MultiDayAxis

+(NSDate*) dateFromString:(NSString*)date {
	static NSDateFormatter *dateFormatter;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"M/d/yyyy"];
	}
	return [dateFormatter dateFromString:date];
}
+(NSDate*) dateWithoutTime:(NSDate*)date {
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents* comps = [calendar 	components:NSTimeZoneCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	comps.hour=0;
	comps.minute=0;
	comps.second=0;
	return [calendar dateFromComponents:comps];
	
	//	return [MultiDayAxis dateFromString:[MultiDayAxis stringFromDate:date]];
}
+(NSString*) stringFromDate:(NSDate*)date {
	static NSDateFormatter *dateFormatter;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"M/d/yyyy"];
	}
	return [dateFormatter stringFromDate:date];
}

//-(id)initWithDataDays:(NSArray*) days andFont:(UIFont*)font{
-(id)initWithEarliest:(NSDate*) min andLastest:(NSDate*)max andFont:(UIFont*)font{
	
	//#ifdef DEBUG
	//	[ShinobiChartLog fatalLogMessage:@"logged" fromSource:@"sour"];
	//#endif
	
//	NSDate* max = [[MultiDayAxis dateFromString: [[days objectAtIndex:0] objectForKey:@"date"] ]dateByAddingTimeInterval:3600*24];
//	NSDate* min = [MultiDayAxis dateFromString: [[days objectAtIndex:days.count-1] objectForKey:@"date"] ] ;
	
	self=[super initWithRange:[[[SChartDateRange alloc] initWithDateMinimum:min
															 andDateMaximum:max /*[max dateByAddingTimeInterval:3600*24]*/ ] autorelease]];
	if(self){
		/*		for(int i=2;i<=days.count;i++){
			NSDate* d=[MultiDayAxis dateFromString: [[days objectAtIndex:(days.count-i)] objectForKey:@"date"] ];
			NSTimeInterval secDiff =[d timeIntervalSinceDate:min];
			if(secDiff>3600*25){
		 [self addExcludedTimePeriod:	[[[SChartTimePeriod alloc]initWithStart:min
		 andLength:[SChartDateFrequency dateFrequencyWithSecond:(secDiff-3600*24)]] autorelease]];
			}
			min=d;
		 }
		 */
		self.style.lineWidth=@1;
		self.style.majorTickStyle.labelFont = font;
		self.style.majorTickStyle.labelColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
		self.style.majorTickStyle.tickGap=@-5;
		
		self.style.majorTickStyle.showTicks=YES;
		self.style.gridStripeStyle.showGridStripes=YES;
		self.style.gridStripeStyle.stripeColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.2];
		
		self.enableGesturePanning=YES;
		self.enableGestureZooming=YES;
		self.enableMomentumPanning=YES;
		
		self.allowPanningOutOfDefaultRange=YES;
		
		[self.labelFormatter.dateFormatter setLocale:[NSLocale currentLocale]];
		//[self.labelFormatter.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		// default is last 2 weeks.
		/*		self.defaultRange = [[[SChartDateRange alloc]
		 initWithDateMinimum:[min laterDate:[NSDate dateWithTimeInterval:-3600*24*14 sinceDate:max]]
		 andDateMaximum:max] autorelease];*/
		
	}
	return self;
}

@end

@implementation TimeOfDayAxis
+(NSDate*) baseDate{
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	components.hour=0;
	components.minute=0;
	components.second=0;
	return [calendar dateFromComponents:components];
}

-(NSString*)formatStringForFrequency:(NSDateComponents *)frequency{
	return @"HH:mm";
}
-(id)initWithFont:(UIFont*)font forTrend:(BOOL)forTrend{
	self=[super initWithRange:[[[SChartDateRange alloc] initWithDateMinimum:TimeOfDayAxis.baseDate
															 andDateMaximum:[NSDate dateWithTimeInterval:3600*24 sinceDate:TimeOfDayAxis.baseDate]] autorelease]];
	if(self){
		
		self.style.lineWidth=@1;
		self.style.majorTickStyle.labelFont = font;
		self.style.majorTickStyle.labelColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
		self.style.majorTickStyle.tickGap=@-5;
		
		//self.style.lineWidth=@0;
		self.style.majorTickStyle.labelFont = font;
		self.style.majorTickStyle.showTicks=YES;
		self.tickLabelClippingModeLow = self.tickLabelClippingModeHigh =  SChartTickLabelClippingModeNeitherPersist;
		
		//self.style.gridStripeStyle.showGridStripes=YES;
		//self.style.gridStripeStyle.stripeColor = [self.style.gridStripeStyle.stripeColor colorWithAlphaComponent:0.05];
		
//		self.style.majorTickStyle.tickGap=@-2;
		if(!forTrend){
			self.style.gridStripeStyle.showGridStripes=YES;
			self.style.gridStripeStyle.stripeColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.2];
			self.enableGesturePanning=YES;
			self.enableGestureZooming=YES;
			self.enableMomentumPanning=YES;
		}else{
			self.style.majorGridLineStyle.showMajorGridLines=YES;
		}
	}
	return self;
}
@end

@implementation RecentTrendTimeTickFormatter
-(NSString *)stringForObjectValue:(id)obj onAxis:(SChartAxis *)axis{
	return @".";
}
+ (RecentTrendTimeTickFormatter*)instance {
	static RecentTrendTimeTickFormatter* inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

@end
@implementation LuxTickFormatter
-(NSString *)stringForObjectValue:(id)obj onAxis:(SChartAxis *)axis{
	float val = [obj floatValue];
	if(fabs(val)<10)return [NSString stringWithFormat:@"%.2f", val];
	else if(fabs(val)<100)return [NSString stringWithFormat:@"%.1f", val];
	else if(fabs(val)<1000)return [NSString stringWithFormat:@"%.0f", val];
	else if(fabs(val)<10000)return [NSString stringWithFormat:@"%.1fk", val/1000.0];
	else if(fabs(val)<100000)return [NSString stringWithFormat:@"%.0fk", val/1000.0];
	else if(fabs(val)<1000000)return [NSString stringWithFormat:@"%.0fk", val/1000.0];
	else return @"...";
}
+ (LuxTickFormatter*)instance {
	static LuxTickFormatter* inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

@end


@implementation MotionEventTickFormatter
-(NSString *)stringForObjectValue:(id)obj onAxis:(SChartAxis *)axis{
	switch([obj intValue]){
		case 0: return NSLocalizedString(@"Disarmed",nil);
		case 1: return NSLocalizedString(@"Armed",nil);
		case 2: return NSLocalizedString(@"Moved",nil);
		case 3: return NSLocalizedString(@"Opened",nil);
		case 4: return NSLocalizedString(@"Closed",nil);
		case 5: return NSLocalizedString(@"Detected",nil);
		case 6: return NSLocalizedString(@"Time out",nil);
		default: return @"";
	}
}
+ (MotionEventTickFormatter*)instance {
	static MotionEventTickFormatter* inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

@end
#pragma mark Translators
BOOL temp_unit;

@implementation MotionTypeTranslator

+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{return NSLocalizedString(@"Motion Event (# of times)",nil);}
-(NSString*)tooltipGen:(float)deg{
	return [NSString stringWithFormat:@"%.0f times", deg];
}
-(NSString*)labelFormat{
	return @"%.0f times";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	return degC;
}
-(float)ymaxInit{return 0;}
-(float)ymaxPost:(float)ymax{
	return ymax+0.5;
}
-(float)yminInit{return 100;}
-(float)yminPost:(float)ymin{
	return ymin-0.5;
}
@end

@implementation SignalTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{return NSLocalizedString(@"Received Signal Level + TX Back-Off",nil);}
-(NSString*)tooltipGen:(float)deg{
	return [NSString stringWithFormat:@"Effectively %.1f dBm", deg];
}
-(NSString*)labelFormat{
	return @"%.0fdBm";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	if ([degC floatValue] == 0.0) return nil;
	return degC;
}
-(float)ymaxInit{return -120.0f;}
-(float)ymaxPost:(float)ymax{
	return ymax;
}
-(float)yminInit{return 0.0f;}
-(float)yminPost:(float)ymin{
	return ymin;
}
@end


@implementation BattTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{return NSLocalizedString(@"Battery Voltage",nil);}
-(NSString*)tooltipGen:(float)deg{
	return [NSString stringWithFormat:@"%.2f volts", deg];
}
-(NSString*)labelFormat{
	return @"%.1fV";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	if ([degC floatValue] == 0.0) return nil;
	return degC;
}
-(float)ymaxInit{return 2.0;}
-(float)ymaxPost:(float)ymax{
	return ymax+0.1;
}
-(float)yminInit{return 3.5;}
-(float)yminPost:(float)ymin{
	return ymin-0.1;
}
@end

@implementation LuxTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}
-(NSString*)name{return NSLocalizedString(@"Ambient Light (lux)",nil);}
-(NSString*)tooltipGen:(float)deg{
	return [NSString stringWithFormat:@"%g lux", deg];
}
-(NSString*)labelFormat{
	return @"xxx";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	return degC;
}
-(float)ymaxInit{return 0;}
-(float)ymaxPost:(float)ymax{
	return ymax*1.05f;
}
-(float)yminInit{return 80000;}
-(float)yminPost:(float)ymin{
	return ymin*0.95f;
}
@end


@implementation CapTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{
	if(self.dewPointMode){
		if(temp_unit)
			return NSLocalizedString(@"Dew Point (°F)",nil);
		else
			return NSLocalizedString(@"Dew Point (°C)",nil);
	}
	return NSLocalizedString(@"Moisture/RH",nil);
}
-(NSString*)tooltipGen:(float)deg{
	return [NSString stringWithFormat:@"%.1f%%", deg];
}
-(NSString*)labelFormat{
	return @"%.0f%%";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	if ([degC floatValue] == -99) return nil;
	return degC;
}
-(float)ymaxInit{return self.dewPointMode? -100: 0;}
-(float)ymaxPost:(float)ymax{
	return ceilf( ymax / 20 + 0.5) * 20;
}
-(float)yminInit{return self.dewPointMode? 220: 100;}
-(float)yminPost:(float)ymin{
	return floor(ymin / 20 - 0.5) * 20;
}
@end

@implementation TemperatureTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{
	if(temp_unit)
		return NSLocalizedString(@"Temperature (°F)",nil);
	else
		return NSLocalizedString(@"Temperature (°C)",nil);
}
-(NSString*)tooltipGen:(float)deg{
	float degf;
	if (temp_unit) degf = deg;
	else degf = deg * 9.0 / 5.0 + 32.0;
	return [NSString stringWithFormat:@"%.1f°F/%.1f°C", degf, (degf - 32) * 5.0 / 9.0];
}
-(NSString*)labelFormat{
	return temp_unit ? @"%.1f°F" : @"%.1f°C";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	if ([degC floatValue] == 0.0) return nil;
	return temp_unit == 1 ? [NSNumber numberWithFloat:[degC floatValue] * 9.0 / 5.0 + 32.0] : degC;
}
-(float)ymaxInit{return temp_unit == 1 ? -28 : -40;}
-(float)ymaxPost:(float)ymax{
//	float ret =ceilf( fmin(temp_unit ? 220 : 125, ymax) / 5 + 0.5) * 5;
	float ret = ceilf(ymax / 5 + 0.5) * 5;
	//	NSLog(@"ymaxPost(%f)=%f",ymax, ret);
	return ret;
}
-(float)yminInit{return temp_unit == 1 ? 220 : 115;}
-(float)yminPost:(float)ymin{
	float ret = floorf(ymin / 5 - 0.5) * 5;
	//	NSLog(@"yminPost(%f)=%f",ymin, ret);
	return ret;
}
@end
@implementation DewPointTypeTranslator
+ (id<StatTypeTranslator>)instance {
	static id<StatTypeTranslator> inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

-(NSString*)name{
	if(temp_unit)
		return NSLocalizedString(@"Dew Point (°F)",nil);
	else
		return NSLocalizedString(@"Dew Point (°C)",nil);
}
-(NSString*)tooltipGen:(float)deg{
	float degf;
	if (temp_unit) degf = deg;
	else degf = deg * 9.0 / 5.0 + 32.0;
	return [NSString stringWithFormat:@"%.1f°F/%.1f°C", degf, (degf - 32) * 5.0 / 9.0];
}
-(NSString*)labelFormat{
	return temp_unit ? @"%.1f°F" : @"%.1f°C";
}
-(NSNumber*)preProcess:(NSNumber*)degC{
	if ([degC floatValue] == 0.0) return nil;
	return temp_unit == 1 ? [NSNumber numberWithFloat:[degC floatValue] * 9.0 / 5.0 + 32.0] : degC;
}
-(float)ymaxInit{return temp_unit == 1 ? -28 : -40;}
-(float)ymaxPost:(float)ymax{
	float ret =ceilf( fmin(temp_unit ? 220 : 125, ymax) / 5 + 0.5) * 5;
	//	NSLog(@"ymaxPost(%f)=%f",ymax, ret);
	return ret;
}
-(float)yminInit{return temp_unit == 1 ? 220 : 115;}
-(float)yminPost:(float)ymin{
	float ret = floorf(ymin / 5 - 0.5) * 5;
	//	NSLog(@"yminPost(%f)=%f",ymin, ret);
	return ret;
}
@end

id<StatTypeTranslator> findTranslator(NSString* type){
	if([type isEqualToString:@"temperature"])
		return TemperatureTypeTranslator.instance;
	else if([type isEqualToString:@"cap"])
		return CapTypeTranslator.instance;
	else if([type isEqualToString:@"dp"])
		return DewPointTypeTranslator.instance;
	else if([type isEqualToString:@"light"])
		return LuxTypeTranslator.instance;
	else if([type isEqualToString:@"batteryVolt"])
		return BattTypeTranslator.instance;
	else if([type isEqualToString:@"signal"])
		return SignalTypeTranslator.instance;
	else //if([type isEqualToString:@"motion"])
		return MotionTypeTranslator.instance;
}

@interface EventTypeFormatter : NSNumberFormatter
+ (EventTypeFormatter*) instance;
@end
@implementation EventTypeFormatter
+ (EventTypeFormatter*) instance {
	static EventTypeFormatter* inst = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ inst = [[self alloc] init]; });
	return inst;
}

- (NSString *)stringFromNumber:(NSNumber *)number{
	return [self stringForObjectValue:number];
}

- (NSString *)stringForObjectValue:(id)obj{
	switch([obj intValue]){
		case 0: return NSLocalizedString(@"Disarmed",nil);
		case 1: return NSLocalizedString(@"Armed",nil);
		case 2: return NSLocalizedString(@"Moved",nil);
		case 3: return NSLocalizedString(@"Opened",nil);
		case 4: return NSLocalizedString(@"Closed",nil);
		case 5: return NSLocalizedString(@"Detected",nil);
		case 6: return NSLocalizedString(@"TimeOut",nil);
	}
	return @"";
}
@end

@implementation RawDataChart
@synthesize dataLoader=_dataLoader, hourlyDataLoader=_hourlyDataLoader, spanLoader=_spanLoader, onLoadDone=_onLoadDone;
@synthesize hourlyData=_hourlyData, earliestDate=_earliestDate, latestDate=_latestDate, pendingEndDate=_pendingEndDate, pendingStartDate=_pendingStartDate, completeDate=_completeDate;
@synthesize dewPointMode=_dewPointMode, capIsChipTemperatureMode=_capIsChipTemperatureMode, askForReview=_askForReview, useLogScaleForLight=_useLogScaleForLight;

-(void)setDewPointMode:(BOOL)dewPointMode{
	_dewPointMode=dewPointMode;
	((CapTypeTranslator*)[CapTypeTranslator instance]).dewPointMode =dewPointMode;
}

-(void)setRawDataMultipleDays: (NSArray*) dataDays{}
-(void)justShownCompleteDay:(NSDate*)date {}

/*-(void)setXAxisFor:(NSArray*)dataDays{
	self.xAxis = [[[MultiDayAxis alloc]initWithDataDays:dataDays andFont:[self.titleLabel.font fontWithSize:9]] autorelease];
}*/

-(void)setMultiDayXAxis{
	self.xAxis = [[[MultiDayAxis alloc]initWithEarliest:self.earliestDate andLastest:self.latestDate andFont:[UIFont systemFontOfSize:11.0]] autorelease];
	self.askForReview = [self.latestDate timeIntervalSinceDate:self.earliestDate]>10*3600*24;
}

-(id)initWithFrame:(CGRect)frame{
	self=[super initWithFrame:frame];
	if(self){
		
		SChartTheme* theme = [[SChartiOS7Theme new] autorelease];

/*		for(int i=0;i<colors.count;i++){
			SChartLineSeriesStyle* ls =[theme lineSeriesStyleForSeriesAtIndex:i+6 selected:NO];
			SChartBandSeriesStyle* bs = [theme bandSeriesStyleForSeriesAtIndex:i+6 selected:NO];
			
			UIColor* color =[colors objectAtIndex:i];
			ls.pointStyle.color = ls.lineColor= color;
			
			bs.lineColorHigh = bs.lineColorLow = color;
			bs.areaColorNormal  = bs.areaColorInverted = [color colorWithAlphaComponent:0.65];
		} */

		SChartLegendStyle* tl = theme.legendStyle;
		tl.font = [self.legend.style.font fontWithSize:9.0]; //[UIFont systemFontOfSize:7.0];
		tl.marginWidth=@4;
		tl.textAlignment = NSTextAlignmentRight;
		tl.horizontalPadding=@1;
		tl.verticalPadding=@2;
		tl.borderWidth=@0;
		tl.areaColor=[UIColor colorWithWhite:1 alpha:0];
		tl.orientation =SChartLegendOrientationHorizontal;


/*		theme.legendStyle.font = [self.legend.style.font fontWithSize:18.0]; //[UIFont systemFontOfSize:7.0];
		theme.legendStyle.marginWidth=@4;
		theme.legendStyle.textAlignment = NSTextAlignmentRight;
		theme.legendStyle.horizontalPadding=@1;
		theme.legendStyle.verticalPadding=@4;
		theme.legendStyle.borderWidth=@0;
		theme.legendStyle.areaColor=[UIColor colorWithWhite:1 alpha:0];
		theme.legendStyle.orientation =SChartLegendOrientationHorizontal;
*/
		[super applyTheme:theme];

		self.autoresizingMask =  ~UIViewAutoresizingNone;
		self.backgroundColor = [UIColor whiteColor];
		self.borderThickness=@0;
		self.plotAreaBorderThickness=0;
		
		//_chart.titleCentresOn = SChartTitleCentresOnPlottingArea;
		//_chart.titlePosition = SChartTitlePositionCenter;
		//self.overlapChartTitle = YES;
		self.titleLabel.font = [self.titleLabel.font fontWithSize:12];
		self.titleLabel.textColor=[UIColor darkGrayColor];
		
		self.delegate = self;
		self.legend.placement = SChartLegendPlacementInsidePlotArea;
		self.legend.position= SChartLegendPositionTopLeft;
		self.legend.autosizeLabels=YES;
		//self.legend.position= SChartLegendPositionBottomMiddle;
		self.legend.hidden = NO;

		queue=nil;
		_zoomLevel=ChartZoomLevelNormal;
	}
	return self;
}
-(void)setupYAxis:(SChartAxis*)axis{
	UIFont* labelFont = [UIFont systemFontOfSize:11.0]; //[self.titleLabel.font fontWithSize:10.0];
	SChartAxisStyle *as = axis.style;
	as.majorTickStyle.labelFont = labelFont;
	as.majorTickStyle.labelColor=[UIColor blackColor];
/*	if([axis isKindOfClass:[SChartLogarithmicAxis class]]){
		axis.width=@45;
	}else{
		axis.width=@25;
	}*/
	as.majorTickStyle.tickGap=@-2;
	as.lineWidth=@0.5;
	as.interSeriesSetPadding=@0;
	axis.enableGesturePanning=YES;
	axis.enableGestureZooming=YES;
	as.majorGridLineStyle.showMajorGridLines=YES;
	as.majorTickStyle.showTicks=YES;
}

-(void)sChart:(ShinobiChart *)chart alterTickMark:(SChartTickMark *)tickMark beforeAddingToAxis:(SChartAxis *)axis
{
	if(![axis isXAxis]){
		UILabel *label =tickMark.tickLabel;
		if(label.text.length>3){
			label.lineBreakMode=NSLineBreakByCharWrapping;
			label.numberOfLines=0;
			//tickMark.tickLabel.transform=CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), tickMark.tickLabel.bounds.size.width, tickMark.tickLabel.bounds.size.height);
			[label sizeToFit];
		}
	}
}

-(void)dealloc{
	if(queue)dispatch_release(queue);
	self.completeDate = nil;
	self.pendingEndDate=nil;
	self.pendingStartDate=nil;
	self.earliestDate=nil;
	self.latestDate=nil;
	self.hourlyData=nil;
	self.hourlyDataLoader=nil;
	self.spanLoader=nil;
	self.dataLoader=nil;
	self.onLoadDone=nil;
	self.spinner=nil;
	[super dealloc];
}
-(void)setupRaw{
	if(queue)return;
	queue = dispatch_queue_create("com.mytaglist.queue", NULL);
	rawData=[[NSMutableArray alloc]init];
	rawDataDates = [[NSMutableArray alloc]init];
}

-(void)loadDataTo:(NSDate*)end done:(loadDone_t)done{
	if(queue_length==0 && self.spinner==nil){
		self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
	}
	queue_length++;
	__block NSDate* oldEndDate = [_pendingEndDate copy];
	self.pendingEndDate =[MultiDayAxis dateWithoutTime:end];
	NSLog(@"loadDataTo(%@==>%@", oldEndDate, _pendingEndDate);
	dispatch_async(queue, ^{
		NSArray* days = _dataLoader([MultiDayAxis stringFromDate: [oldEndDate dateByAddingTimeInterval:3600*24]],[MultiDayAxis stringFromDate:_pendingEndDate]);
		[oldEndDate release];
		if(days!=nil){
			@synchronized(rawDataDates){
				for(int i=0;i<days.count;i++){
					NSDictionary* day =days[i];
					[rawData addObject:day];
					[rawDataDates addObject:[MultiDayAxis dateFromString:[day objectForKey:@"date"]]];
				}
			}
		}
		translatedEnd=-1; translatedStart=-1;
		queue_length--;
		
		if(queue_length==0)
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.spinner removeSpinner]; self.spinner=nil;
				self.onLoadDone=done;
				[self translateRawData];
			});
	});
	
}
-(void)loadDataFrom:(NSDate*)start done:(loadDone_t)done{
	if(queue_length==0 && self.spinner==nil){
		self.spinner = [SpinnerView loadSpinnerIntoView:self.window];
	}

	queue_length++;
	__block NSDate* oldStartDate =[_pendingStartDate copy];
	self.pendingStartDate =[MultiDayAxis dateWithoutTime:start];
	
	NSLog(@"loadDataFrom(%@==>%@", oldStartDate, _pendingStartDate);
	
	dispatch_async(queue, ^{
		NSArray* days = _dataLoader([MultiDayAxis stringFromDate:_pendingStartDate],
									[MultiDayAxis stringFromDate:[oldStartDate dateByAddingTimeInterval:-3600*24]]);
		[oldStartDate release];
		if(days!=nil){
			@synchronized(rawDataDates){
				for(int i=0;i<days.count;i++){
					NSDictionary* day =days[days.count-i-1];
					[rawData insertObject:day atIndex:0];
					[rawDataDates insertObject:[MultiDayAxis dateFromString:[day objectForKey:@"date"]] atIndex:0];
				}
			}
		}
		translatedEnd=-1; translatedStart=-1;
		queue_length--;
		
		if(queue_length==0)
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.spinner removeSpinner]; self.spinner=nil;
				self.onLoadDone=done;
				[self translateRawData];
			});
	});
}
-(void)clearRawData{
	@synchronized(rawDataDates){
		self.pendingEndDate=nil;
		self.pendingStartDate=nil;
		[rawData removeAllObjects];
		[rawDataDates removeAllObjects];
	}
}
// return YES if reloaded chart.
-(BOOL)translateRawData{
	
	SChartDateRange* range =(SChartDateRange*)self.xAxis.axisRange;
	
	@synchronized(rawDataDates){
		
		int startIndex=-1, endIndex=-1;
		int zone=0;
		for(int i=0;i<rawDataDates.count;i++){
			if(zone==0){
				if([(NSDate*)rawDataDates[i] compare:[range.minimumAsDate dateByAddingTimeInterval:-3600*24] ]== NSOrderedDescending){   // i > minDate-(1day)
					zone=1;
					startIndex=i;
				}
			}else if(zone==1){
				endIndex=i;
				if([(NSDate*)rawDataDates[i] compare:[range.maximumAsDate dateByAddingTimeInterval:3600*24] ]== NSOrderedDescending){   // i > maxDate+(1day)
					zone=2;
					break;
				}
			}
		}
		if(startIndex==-1)return NO;
		if(endIndex==-1)endIndex=startIndex;
		
		if(startIndex!=translatedStart || endIndex!=translatedEnd){
			translatedEnd=endIndex; translatedStart=startIndex;
			NSLog(@"translating from i=%d,%d", startIndex, endIndex);
			
			//self.xAxis.defaultRange=self.xAxis.axisRange;
			for(SChartAxis* axis in self.allAxes)
				axis.defaultRange = axis.axisRange;
			
			[self setRawDataMultipleDays:[rawData subarrayWithRange:NSMakeRange(startIndex, endIndex-startIndex+1)]];

			return YES;
		}else{
			return NO;
		}
	}
}

-(void)zoomLevelChanged{
	//NSLog(@"zoomLevelChanged to %ld", zoomLevel);
	//self.xAxis.defaultRange=self.xAxis.axisRange;
	
	//self.xAxis.allowPanningOutOfMaxRange=(zoomLevel<ChartZoomLevelNormal);
	
	for(SChartAxis* axis in self.allAxes)
		axis.defaultRange = axis.axisRange;
	
	[self reloadData];
	[self redrawChartIncludePlotArea:YES];
}
-(void)enteredRawLevelWithRange:(SChartDateRange*)range done:(loadDone_t)done{
	[self setupRaw];
	
	if(_pendingEndDate==nil){
		
		[self clearRawData];
		self.pendingEndDate =[MultiDayAxis dateWithoutTime: [range.minimumAsDate dateByAddingTimeInterval:-3600*36]];
		self.pendingStartDate = [self.pendingEndDate dateByAddingTimeInterval:3600*24];
		[self loadDataTo:[range.maximumAsDate dateByAddingTimeInterval:3600*24] done:done];
		
	}else{
		
		if([range.minimumAsDate timeIntervalSinceDate:_pendingEndDate]>3600*24*2 ||
		   [range.maximumAsDate timeIntervalSinceDate:_pendingStartDate]<-3600*24*2)
		{
			[self clearRawData];
			self.pendingEndDate =[MultiDayAxis dateWithoutTime: [range.minimumAsDate dateByAddingTimeInterval:-3600*36]];
			self.pendingStartDate = [self.pendingEndDate dateByAddingTimeInterval:3600*24];
			[self loadDataTo:[range.maximumAsDate dateByAddingTimeInterval:3600*24] done:done];
		}else{
			self.onLoadDone=done;
			[self zoomLevelChanged];
		}
	}
}
// return YES if did redraw
-(BOOL)rawLevelRangeChangedWithRange:(SChartDateRange*)range done:(loadDone_t)done{
	// if max is on the last day, load 2 more days.
	if([range.maximumAsDate compare:_pendingEndDate]== NSOrderedDescending) {		// maximumAsDate > _pendingEndDate(0 hour)
		[self loadDataTo:[_pendingEndDate dateByAddingTimeInterval:3600*48] done:done];
		return YES;
	}
	// if min is on the last minute of first day, load 2 more days.
	else if([range.minimumAsDate compare:[_pendingStartDate dateByAddingTimeInterval:3600*24]]==NSOrderedAscending){
		[self loadDataFrom: [_pendingStartDate dateByAddingTimeInterval:-3600*48] done:done];
		return YES;
	}else{
		if(queue_length==0)
			return [self translateRawData];
		else return YES;
	}
}
int ZoomLevelFromTI(NSTimeInterval ti){
	if(ti<3600*24){
		return ChartZoomLevelRaw;
	}
	else if(ti<3600*24*4){
		return ChartZoomLevelRaw2;
	}
	else if(ti<3600*24*32){
		return ChartZoomLevelNormal;
	}else{
		return ChartZoomLevelBand;
	}
}
-(void)updateZoomPanMinDate:(NSDate*)min MaxDate:(NSDate*)max Done:(loadDone_t)done{
	[self updateZoomPan:[[[SChartDateRange alloc]initWithDateMinimum:min andDateMaximum:max]autorelease]  Done:done];
}
-(void)updateCompleteDay:(SChartDateRange*)range{
	NSTimeInterval ti =[range.maximumAsDate timeIntervalSince1970] - [range.minimumAsDate timeIntervalSince1970];
	if(ti > 3600*24 && ti<3600*60){
		// find the complete date
		NSDate* date = [MultiDayAxis dateWithoutTime:
						[NSDate dateWithTimeIntervalSince1970:[range.maximumAsDate timeIntervalSince1970]/2.0 + [range.minimumAsDate timeIntervalSince1970]/2.0]
						//[NSDate dateWithTimeIntervalSince1970:[range.maximumAsDate timeIntervalSince1970]-3600*24]
						];
		
//		if([ ((SChartDateRange*)self.xAxis.dataRange).maximumAsDate timeIntervalSinceDate:date]<24*3600)
//			date = [date dateByAddingTimeInterval:-24*3600];
		
		if(_completeDate==nil || ![_completeDate isEqualToDate:date]){
			self.completeDate = date;
			[self justShownCompleteDay:date];
		}
	}
}
// this does NOT actually update range. Call this after finger updated zoom or pan, or after last xx hour button pressed. Then, set xaxis in the done callback.
-(void)updateZoomPan:(SChartDateRange*) range Done:(loadDone_t)done{
//	SChartDateRange* range =(SChartDateRange*)self.xAxis.axisRange;
	//	SChartDateRange* range = [[[SChartDateRange alloc]initWithDateMinimum:[range1.minimumAsDate dateByAddingTimeInterval:3600*48]
	//        andDateMaximum:[range1.maximumAsDate dateByAddingTimeInterval:-3600*48]] autorelease];
	
	if(noDynamicLoading)return;
	
	int oldZoomLevel = _zoomLevel;
	
	NSTimeInterval ti =[range.maximumAsDate timeIntervalSince1970] - [range.minimumAsDate timeIntervalSince1970];

	[[NSUserDefaults standardUserDefaults]setDouble:ti forKey: [graphTIPrefix stringByAppendingString:NSStringFromClass([self.type class])]];

	
	_zoomLevel = ZoomLevelFromTI(ti);
	
	if(_zoomLevel>=ChartZoomLevelNormal && oldZoomLevel<ChartZoomLevelNormal){
		[self enteredNormalLevelWithRange:range done:done];
	}
	else if(_zoomLevel<ChartZoomLevelNormal){
		if(oldZoomLevel>=ChartZoomLevelNormal)
			[self enteredRawLevelWithRange:range done:done];
		else
			if([self rawLevelRangeChangedWithRange:range done:done])return;
		
	}else if(oldZoomLevel!=_zoomLevel){
		self.onLoadDone=done;
		[self zoomLevelChanged];
	}else
		done();
}
-(void)sChartDidFinishLoadingData:(ShinobiChart *)chart{
//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
	
/*	if(chart.allYAxes.count>1){
		NSLog(@"2nd YAxis range = %@", ((SChartAxis*)[chart.allYAxes objectAtIndex:1]).axisRange);
	}
*/
	if(self.onLoadDone!=nil){
		NSLog(@"sChartDidFinishLoadingData calling onLoadDone");
		_onLoadDone();
		self.onLoadDone=nil;
	}else{
		NSLog(@"sChartDidFinishLoadingData onLoadDone is nil");
	}
//	});

}
/*-(void)sChartDidFinishZooming:(ShinobiChart *)chart
{
	SChartDateRange* range = (SChartDateRange*)self.xAxis.axisRange;
	NSTimeInterval ti =[range.maximumAsDate timeIntervalSince1970] - [range.minimumAsDate timeIntervalSince1970];
	[[NSUserDefaults standardUserDefaults]setDouble:ti forKey: [graphTIPrefix stringByAppendingString:NSStringFromClass([self.type class])]];
}*/

- (void)sChartIsZooming:(ShinobiChart *)chart
//-(void)sChartDidFinishZooming:(ShinobiChart *)chart
{
	SChartDateRange* range = (SChartDateRange*)self.xAxis.axisRange;
	[self updateZoomPan: range Done:^(){}];
	[self updateCompleteDay:range];
}
- (void)sChartIsPanning:(ShinobiChart *)chart
//-(void)sChartDidFinishPanning:(ShinobiChart *)chart
{
	SChartDateRange* range = (SChartDateRange*)self.xAxis.axisRange;
	//[self updateZoomPan: (SChartDateRange*)self.xAxis.axisRange Done:^(){}];
	if(_zoomLevel<ChartZoomLevelNormal){
		if([self rawLevelRangeChangedWithRange:range done:^(){}])return;
	}
	[self updateCompleteDay:range];
}
@end

@implementation NSMutableArray (ChartSeries)
-(void)addDataPoint:(SChartDataPoint*)dataPoint{
	if(self.count>0){
		if(  [(NSDate*)dataPoint.xValue timeIntervalSinceDate:[self.lastObject xValue]] > 3600 * 5.0 ){
			SChartDataPoint* nullPoint = [[SChartDataPoint new] autorelease];
			nullPoint.xValue = [(NSDate*)[self.lastObject xValue] dateByAddingTimeInterval:1];
			nullPoint.yValue = nil;
			[self addObject:nullPoint];
			SChartDataPoint* nullPoint2 = [[SChartDataPoint new] autorelease];
			nullPoint2.xValue = [(NSDate*)[self.lastObject xValue] dateByAddingTimeInterval:2];
			nullPoint2.yValue = nil;
			[self addObject:nullPoint];
		}
	}
	[self addObject:dataPoint];
}
-(void)addDailyDataPoint:(SChartMultiYDataPoint*)dataPoint{
	if(self.count>0){
		if(  [(NSDate*)dataPoint.xValue timeIntervalSinceDate:[self.lastObject xValue]] > 3600 * 25.0 ){

			NSDictionary* lastY = [self.lastObject yValues];
			double midpoint = ([[lastY objectForKey:SChartBandKeyLow]doubleValue] + [[lastY objectForKey:SChartBandKeyHigh]doubleValue])/2.0;
			NSMutableDictionary* nullY =[NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithDouble:midpoint],
																						SChartBandKeyLow:[NSNumber numberWithDouble:midpoint]}];

			SChartMultiYDataPoint* nullPoint0 = [[SChartMultiYDataPoint new] autorelease];
			nullPoint0.xValue = [(NSDate*)[self.lastObject xValue] dateByAddingTimeInterval:3600];
			nullPoint0.yValues = nullY;
			[self addObject:nullPoint0];

			SChartMultiYDataPoint* nullPoint = [[SChartMultiYDataPoint new] autorelease];
			nullPoint.xValue = [(NSDate*)[dataPoint xValue] dateByAddingTimeInterval:-3600];
			nullPoint.yValues = nullY;
			[self addObject:nullPoint];
		}
	}
	[self addObject:dataPoint];
}

@end
