//
//  SingleTagChart.m
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "SingleTagChart.h"
#import "iToast.h"

@implementation SingleTagChart
@synthesize useLogScaleForLight=_useLogScaleForLight;

-(void)setUseLogScaleForLight:(BOOL)useLogScaleForLight{
	if(self.hasALS){
		if(!_useLogScaleForLight  && useLogScaleForLight){
			[self replaceYAxis:luxAxis withAxis:logAxis];
//			[self redrawChartIncludePlotArea:YES];
		}
		else if(_useLogScaleForLight  && !useLogScaleForLight){
			[self replaceYAxis:logAxis withAxis:luxAxis];

//			[self redrawChartIncludePlotArea:YES];
		}
	}
	_useLogScaleForLight=useLogScaleForLight;
}
-(void)setup{
	NSLog(@"SingleTagChart::init begins");

	_useLogScaleForLight = [[NSUserDefaults standardUserDefaults] boolForKey:LogScalePrefKey];
	
	self.backgroundColor=[UIColor clearColor];
	self.clipsToBounds = NO;
	
	self.type = TemperatureTypeTranslator.instance;
	UIFont* labelFont = [UIFont systemFontOfSize:11.0];
//[self.titleLabel.font fontWithSize:11.0];
	
	
	self.xAxis =[[[TimeOfDayAxis alloc]initWithFont:labelFont forTrend: forTrend]autorelease];
	self.xAxis.allowPanningOutOfDefaultRange=self.xAxis.allowPanningOutOfMaxRange=YES;
	if(forTrend){
		[self.xAxis.labelFormatter.dateFormatter setTimeStyle:NSDateFormatterShortStyle]; //= RecentTrendTimeTickFormatter.instance;
		self.xAxis.style.lineColor=[UIColor clearColor];
	}
	
	temperatureAxis = [[[SChartNumberAxis alloc] init] autorelease];
	
	capAxis = [[SChartNumberAxis alloc] init] ;
	
	SChartAxisStyle* tas =temperatureAxis.style;
	tas.interSeriesSetPadding=@0;
	tas.majorTickStyle.labelFont = labelFont;
	tas.majorTickStyle.showTicks=NO; //YES;
	tas.majorTickStyle.labelColor=[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
	tas.majorTickStyle.tickGap=@-2;

	if(forTrend){
		temperatureAxis.enableGesturePanning=NO;
		tas.majorGridLineStyle.showMajorGridLines=NO;
		tas.lineWidth=@0;
	}else{
		temperatureAxis.enableGesturePanning=YES;
		tas.majorGridLineStyle.showMajorGridLines=YES;
		tas.lineWidth=@0.5;
	}
	temperatureAxis.enableGestureZooming=YES;

	SChartAxisStyle* cas =capAxis.style;
	cas.lineWidth=@0;
	cas.interSeriesSetPadding=@0;
	
	SChartTickStyle* casmt =cas.majorTickStyle;
	casmt.labelFont= labelFont;
	casmt.showTicks=YES;
	casmt.labelColor=CAPCOLOR; //[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
	casmt.tickGap=@-5;
	capAxis.axisPosition = SChartAxisPositionReverse;
	
	capAxis.labelFormatString =[CapTypeTranslator.instance labelFormat];
	temperatureAxis.labelFormatString = @"%.0f°";
	
	if(forTrend){
		capAxis.enableGesturePanning=NO;
	}else{
		capAxis.enableGesturePanning=YES;
		capAxis.majorTickFrequency=@20;
	}
	capAxis.enableGestureZooming=YES;
	
	
	self.yAxis = temperatureAxis;
	
	
	self.datasource=self;
	
	tempSeries=[[NSMutableArray alloc]init];
	capSeries=[[NSMutableArray alloc]init];

	rawTempSeries=[[NSMutableArray alloc]init];
	rawCapSeries=[[NSMutableArray alloc]init];
	bandCapSeries=[[NSMutableArray alloc]init];
	bandTempSeries = [[NSMutableArray alloc] init];
	
	self.date2DLI=[[[NSMutableDictionary alloc]init] autorelease];
	NSLog(@"SingleTagChart::init ends");
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		forTrend=YES;
		[self setup];
	}
	return self;
}
-(id)initWithFrame:(CGRect)frame{
	self=[super initWithFrame:frame];
	if(self){
		forTrend=NO;
		[self setup];
	}
	return self;
}
-(void)setHasALS:(BOOL)hasALS
{
	if(hasALS && luxAxis==nil){

		luxAxis =[[SChartNumberAxis alloc] init] ;
		logAxis = [[SChartLogarithmicAxis alloc]init];

		for(SChartAxis *axis in @[luxAxis, logAxis]){
			axis.axisPosition = SChartAxisPositionReverse;
			SChartAxisStyle *as = axis.style;
			as.lineWidth=@0;
			as.majorTickStyle.tickGap=@-3;
			as.interSeriesSetPadding=@0;
			as.majorTickStyle.labelFont= [UIFont systemFontOfSize:11.0]; //[self.titleLabel.font fontWithSize:10.0];
			as.majorTickStyle.labelColor=LUXCOLOR; //[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
//			as.majorGridLineStyle.showMajorGridLines=YES;
			
			axis.enableGesturePanning=!forTrend;
			
			axis.enableGestureZooming=YES;
			//axis.labelFormatString = @"%.0f";
			axis.labelFormatter = LuxTickFormatter.instance;
			
			//		logAxis.axisLabelsAreFixed=YES;
			//axis.width=@22;
		}
		
	}
	if(hasALS && !_hasALS){
		SChartNumberAxis* yaxis =_useLogScaleForLight?logAxis:luxAxis;
		if(![self.allYAxes containsObject:yaxis]){
			[self addYAxis:yaxis];
			NSLog(@"added luxAxis %@", luxAxis);
		}
		_hasALS=hasALS;
	}
	if(!hasALS && _hasALS){		
		_hasALS=hasALS;
		NSLog(@"removing luxAxis %@", luxAxis);
		SChartNumberAxis* yaxis =_useLogScaleForLight?logAxis:luxAxis;
		if([self.allYAxes containsObject:yaxis])
			[self removeYAxis:yaxis];
	}

	if(hasALS && luxSeries==nil){

		luxSeries = [[NSMutableArray alloc]init];
		rawLuxSeries = [[NSMutableArray alloc]init];
		bandLuxSeries = [[NSMutableArray alloc]init];
		
	}
	
}
-(void)dealloc{
	NSLog(@"SingleTagChart::dealloc");
	[capAxis release]; capAxis=nil;
	[logAxis release]; logAxis=nil;
	[luxAxis release]; luxAxis=nil;
	[tempSeries release]; tempSeries=nil;
	[capSeries release]; capSeries =nil;
	//[battSeries release]; battSeries=nil;
	[rawTempSeries release]; rawTempSeries=nil;
	[rawCapSeries release]; rawCapSeries=nil;
	[bandTempSeries release]; bandTempSeries=nil;
	[bandCapSeries release]; bandCapSeries=nil;
	[luxSeries release]; luxSeries=nil;
	[rawLuxSeries release]; rawLuxSeries=nil;
	[bandLuxSeries release]; bandLuxSeries=nil;
	self.date2DLI=nil;
	[super dealloc];
	NSLog(@"SingleTagChart::dealloc completes");
}

-(void)resetNormalData{
	[tempSeries removeAllObjects];
	[capSeries removeAllObjects];
	[bandCapSeries removeAllObjects];
	[bandTempSeries removeAllObjects];
	[luxSeries removeAllObjects];
	[bandLuxSeries removeAllObjects];
	//[battSeries removeAllObjects];
	[_date2DLI removeAllObjects];
}
-(void)initLuxAxisMinMax{
	luxAxisMax= LuxTypeTranslator.instance.ymaxInit;
	luxAxisMin = LuxTypeTranslator.instance.yminInit;
}
-(void)initCapAxisMinMax{
	capAxisMax= CapTypeTranslator.instance.ymaxInit;
	capAxisMin = CapTypeTranslator.instance.yminInit;
}
-(void)finishCapAxisMinMax{
	capAxisMax = [CapTypeTranslator.instance ymaxPost:capAxisMax];
	capAxisMin = [CapTypeTranslator.instance yminPost:capAxisMin];
	
	capAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:capAxisMin] andMaximum:[NSNumber numberWithFloat:capAxisMax]] autorelease];
}
-(void)finishLuxAxisMinMax{
	luxAxisMax = [LuxTypeTranslator.instance ymaxPost:luxAxisMax];
	luxAxisMin = [LuxTypeTranslator.instance yminPost:luxAxisMin];
	
	logAxis.defaultRange = luxAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:luxAxisMin] andMaximum:[NSNumber numberWithFloat:luxAxisMax]] autorelease];
}
-(void)setRawDataMultipleDays: (NSArray*) dataDays{
	
	[rawTempSeries removeAllObjects];
	[rawCapSeries removeAllObjects];
	[rawLuxSeries removeAllObjects];

	TemperatureTypeTranslator* tempT =TemperatureTypeTranslator.instance;
	ymax2=[tempT ymaxInit];
	ymin2=[tempT yminInit];
	[self initCapAxisMinMax];
	if(self.hasALS)[self initLuxAxisMinMax];
	
	for(NSDictionary* day in dataDays){
		NSLog(@"processOneDay(%@)", [day objectForKey:@"date"]);
		[self processOneDay:day baseDate:[MultiDayAxis dateFromString:[day objectForKey:@"date"]] title:nil];
	}

//	if(!self.dewPointMode && capSeries.count>0 && ![self.allYAxes containsObject:capAxis])[self addYAxis:capAxis];
	self.hasCap =(capSeries.count>0 || rawCapSeries.count>0);
	if(!self.dewPointMode && _hasCap){
		
		if(![self.allYAxes containsObject:capAxis]){
			[self addYAxis:capAxis];
			NSLog(@"added capAxis %@", capAxis);
		}
	}
	else 	if([self.allYAxes containsObject:capAxis]){
		[self removeYAxis:capAxis];
		NSLog(@"removed capAxis %@", capAxis);
	}

	/*if(!self.hasALS){
		if(!self.dewPointMode && rawCapSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if((self.dewPointMode || rawCapSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}*/

	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];

	[self finishCapAxisMinMax];
	if(self.hasALS)[self finishLuxAxisMinMax];
	
	[self reloadData];
	[self redrawChartIncludePlotArea:YES];
}
-(void)setDataMultipleDays:(NSArray *)dataDays withZoom:(SChartDateRange *)range
{
	[self resetNormalData];

	if([dataDays count]==0){
		iToast* t =[[iToast makeText:@"No data available."] setDuration:iToastDurationNormal];
		[t showFrom:nil ];
		return;
	}
	
	TemperatureTypeTranslator* tempT =TemperatureTypeTranslator.instance;
	ymax2=[tempT ymaxInit];
	ymin2=[tempT yminInit];
	
	[self initCapAxisMinMax];
	if(self.hasALS)[self initLuxAxisMinMax];
	
	//NSArray* dataDays =[data objectForKey:@"temps"];
	
	NSInteger nDays = dataDays.count;
	for(NSInteger i=1;i<=nDays;i++){
		NSDictionary* day =[dataDays objectAtIndex:(nDays-i)];
		NSDate* baseDate =[MultiDayAxis dateFromString:[day objectForKey:@"date"]];
		
		if(i==1)self.earliestDate=baseDate;
		else if(i==nDays)self.latestDate=baseDate;
		
		[self processOneDay:day baseDate:baseDate title:nil];
	}
	
//	if(!self.dewPointMode && capSeries.count>0 && ![self.allYAxes containsObject:capAxis])[self addYAxis:capAxis];
	self.hasCap =(capSeries.count>0 || rawCapSeries.count>0);
	if(!self.dewPointMode && _hasCap){
		if(![self.allYAxes containsObject:capAxis])
			[self addYAxis:capAxis];
	}
	else 	if([self.allYAxes containsObject:capAxis])
		[self removeYAxis:capAxis];

	
	/*if(!self.hasALS){
		if( !self.dewPointMode && capSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if( (self.dewPointMode|| capSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}*/
	
	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	//temperatureAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];

	[self finishCapAxisMinMax];
	if(self.hasALS)[self finishLuxAxisMinMax];

	if(range!=nil)nDays = [range.maximumAsDate timeIntervalSinceDate:range.minimumAsDate]/3600.0/24.0;
	
	if(nDays>24)
		self.zoomLevel=ChartZoomLevelBand;
	else
		self.zoomLevel = ChartZoomLevelNormal;
	
	[self reloadData];
	[self redrawChartIncludePlotArea:YES];
}
-(void)enteredNormalLevelWithRange:(SChartDateRange *)range done:(loadDone_t)done{
	if(tempSeries.count==0){
		if(self.hourlyData==nil){
			self.hourlyDataLoader(^(NSMutableDictionary* data){
				self.hourlyData=data;
				self.onLoadDone=done;
				[self setDataMultipleDays:[data objectForKey:@"temps"] withZoom:range];
				//[self redrawChartIncludePlotArea:YES];
			});
		}else{
			self.onLoadDone=done;
			[self setDataMultipleDays:[self.hourlyData objectForKey:@"temps"] withZoom:range];
			//[self redrawChartIncludePlotArea:YES];
		}
	}else{
		self.onLoadDone=done;
		[self zoomLevelChanged];
	}
}

-(NSUInteger) findBandArrayIndexFor:(NSDate*)date{
	
	NSUInteger i=0;
	for(;i<bandTempSeries.count;i++){
		SChartMultiYDataPoint* dp =bandTempSeries[i];
		if([(NSDate*)dp.xValue compare:date]==NSOrderedDescending)return i;
	}
	return i;
}

-(void)showRecentTrendFileTimes:(NSArray*)filetimes Temperatures:(NSArray*)temps Caps:(NSArray*)caps Lux:(NSArray*)lux tempRange:(NSArray*)tempRange capRange:(NSArray*)capRange luxRange:(NSArray*)luxRange dateRange:(NSArray*)dateRangeFiletime eventsToAnnotate:(NSArray*)events{
	
	noDynamicLoading=YES;
	_zoomLevel=ChartZoomLevelRaw;
	
	self.earliestDate =nsdateFromFileTime([dateRangeFiletime.firstObject longLongValue]);
	self.latestDate = nsdateFromFileTime([dateRangeFiletime.lastObject longLongValue]);
										
	[self.xAxis setRangeWithMinimum:self.earliestDate	 andMaximum:self.latestDate];
	
	//self.xAxis.majorTickFrequency = [SChartDateFrequency dateFrequencyWithMinute:fmaxf(10, floorf([maxDate timeIntervalSinceDate:minDate]/60/4 / 10+0.5)*10.0)];

	[self removeAllAnnotations];
	[rawTempSeries removeAllObjects];
	[rawCapSeries removeAllObjects];
	[rawLuxSeries removeAllObjects];
	
	TemperatureTypeTranslator* tempT =TemperatureTypeTranslator.instance;
	NSMutableArray* annotations = [[NSMutableArray alloc]initWithCapacity:6];
	if(tempRange){
		NSNumber* th_low = [TemperatureTypeTranslator.instance preProcess:[tempRange objectAtIndex:0]];
		NSNumber* th_high = [TemperatureTypeTranslator.instance preProcess:[tempRange objectAtIndex:1]];
		
		ymin2 = [th_low floatValue];
		ymax2 = [th_high floatValue];
		SChartAnnotationZooming* la = 		[SChartAnnotationZooming horizontalBandAtPosition:th_low andMaxY:@-200 withXAxis:self.xAxis andYAxis:temperatureAxis withColor:[TEMPCOLOR colorWithAlphaComponent:0.05] ];
		[annotations addObject:la];
		SChartAnnotationZooming* ha = 		[SChartAnnotationZooming horizontalBandAtPosition:th_high andMaxY:@1000 withXAxis:self.xAxis andYAxis:temperatureAxis withColor:[TEMPCOLOR colorWithAlphaComponent:0.05] ];
		[annotations addObject:ha];
	}else{
		ymax2=[tempT ymaxInit];
		ymin2=[tempT yminInit];
	}
	
	if(capRange){
		NSNumber* th_low = [capRange objectAtIndex:0];
		NSNumber* th_high = [capRange objectAtIndex:1];
		
		capAxisMin = [th_low floatValue];
		capAxisMax = [th_high floatValue];
		SChartAnnotationZooming* la = 		[SChartAnnotationZooming horizontalBandAtPosition:th_low andMaxY:@0 withXAxis:self.xAxis andYAxis:capAxis withColor:[CAPCOLOR colorWithAlphaComponent:0.05] ];
		[annotations addObject:la];
		SChartAnnotationZooming* ha = 		[SChartAnnotationZooming horizontalBandAtPosition:th_high andMaxY:@120 withXAxis:self.xAxis andYAxis:capAxis withColor:[CAPCOLOR colorWithAlphaComponent:0.05] ];
		[annotations addObject:ha];

	}else{
		[self initCapAxisMinMax];
	}
	if(self.hasALS){
		
		if(luxRange){
			NSNumber* th_low = [luxRange objectAtIndex:0];
			NSNumber* th_high = [luxRange objectAtIndex:1];
			
			luxAxisMin = [th_low floatValue];
			luxAxisMax = [th_high floatValue];
			SChartNumberAxis* yaxis = _useLogScaleForLight?logAxis:luxAxis;
			SChartAnnotationZooming* la = 		[SChartAnnotationZooming horizontalBandAtPosition:th_low andMaxY:@0 withXAxis:self.xAxis andYAxis:yaxis withColor:[LUXCOLOR colorWithAlphaComponent:0.05] ];
			[annotations addObject:la];
			SChartAnnotationZooming* ha = 		[SChartAnnotationZooming horizontalBandAtPosition:th_high andMaxY:@1000000 withXAxis:self.xAxis andYAxis:yaxis withColor:[LUXCOLOR colorWithAlphaComponent:0.05] ];
			[annotations addObject:ha];
			
		}else{
			[self initLuxAxisMinMax];
		}
	}
	
	for(int i=0;i<filetimes.count;i++){
		NSNumber* val = [CapTypeTranslator.instance preProcess:[caps objectAtIndex:i]];
		NSDate* time =nsdateFromFileTime([[filetimes objectAtIndex:i] longLongValue]);
		if(val){
			capAxisMax=fmax(capAxisMax, [val floatValue]);
			capAxisMin=fmin(capAxisMin, [val floatValue]);
			
			SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
			dataPoint.xValue = time;
			dataPoint.yValue = val;
			[rawCapSeries addObject:dataPoint];
		}
		if(self.hasALS){
			val = [LuxTypeTranslator.instance preProcess:[lux objectAtIndex:i]];
			if(val){
				SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
				dataPoint.xValue = time;
				dataPoint.yValue = val;
				
				luxAxisMax=fmax(luxAxisMax, [val floatValue]);
				luxAxisMin=fmin(luxAxisMin, [val floatValue]);
				
				[rawLuxSeries addObject:dataPoint];
			}
		}
		val = [TemperatureTypeTranslator.instance preProcess:[temps objectAtIndex:i]];
		if(val){
			SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
			dataPoint.xValue = time;
			dataPoint.yValue = val;
			if([self.latestDate timeIntervalSinceDate:dataPoint.xValue]<0)
				self.latestDate = dataPoint.xValue;
			
			ymax2=fmax(ymax2, [val floatValue]);
			ymin2=fmin(ymin2, [val floatValue]);
			[rawTempSeries addObject:dataPoint];
		}
	}
	
	self.hasCap =(capSeries.count>0 || rawCapSeries.count>0);
	if(!self.dewPointMode && _hasCap){
		if(![self.allYAxes containsObject:capAxis])
			[self addYAxis:capAxis];
	}
	else 	if([self.allYAxes containsObject:capAxis])
		[self removeYAxis:capAxis];

	/*if(!self.hasALS){
		if(!self.dewPointMode && rawCapSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if((self.dewPointMode || rawCapSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}*/
	
	ymin2 = floorf(ymin2 / 2 - 0.5) * 2;
	ymax2 = ceilf(ymax2/2+0.5)*2;
	temperatureAxis.majorTickFrequency = [NSNumber numberWithFloat:fmax(1.0, (ymax2-ymin2)/4)];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];
	
	capAxisMin = floorf(capAxisMin / 2 - 0.5) * 2;
	capAxisMax = ceilf(capAxisMax/2+0.5)*2;
	capAxis.majorTickFrequency = [NSNumber numberWithFloat:fmax(1.0, (capAxisMax-capAxisMin)/4)];
	capAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:capAxisMin] andMaximum:[NSNumber numberWithFloat:capAxisMax]] autorelease];

	
	if(self.hasALS)[self finishLuxAxisMinMax];

	[self reloadData];
	
	for(SChartAnnotation* annotation in annotations)
		[self addAnnotation:annotation];
	
	CGAffineTransform rotationTransform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI/2);
	for(NSArray* e in events){
		NSDate* date =nsdateFromFileTime([[e objectAtIndex:0] longLongValue]);
/*		SChartAnnotation *line = [SChartAnnotation verticalLineAtPosition:date withXAxis:self.xAxis andYAxis:temperatureAxis withWidth:2.f
																			 withColor:[UIColor colorWithWhite:0.7 alpha:1.0]];
		line.position = SChartAnnotationAboveData;
		[self addAnnotation:line];
*/
		SChartAnnotation *eventText = [SChartAnnotation annotationWithText:[e objectAtIndex:1] andFont:[UIFont systemFontOfSize:11.f]
																	withXAxis:self.xAxis andYAxis:temperatureAxis
																  atXPosition:date  andYPosition:[NSNumber numberWithFloat:(ymax2+ymin2)/2]
																withTextColor:[UIColor blackColor]
														  withBackgroundColor:self.plotAreaBackgroundColor];
		
		// rotate the text by 90 degrees
		eventText.transform = rotationTransform;
		eventText.position = SChartAnnotationAboveData;
		[self addAnnotation:eventText];
	}
	
	[annotations release];
	
	[self redrawChartIncludePlotArea:YES];
	//[self redrawChart];
}
// must be called from earliest date
-(float)processOneDay:(NSDictionary *)day baseDate:(NSDate*)baseDate title:(NSMutableString*)title
{
	NSArray* lux = [day objectForKey:@"lux"];
	if(lux!=nil && !self.hasALS){
		self.hasALS=YES;
	}
	if(lux==nil)self.hasALS=NO;
	
	NSArray* caps =[day objectForKey:@"caps"];
	NSArray* temps =[day objectForKey:@"temps"];
	//	NSArray* batts =[day objectForKey:@"batteryVolts"];
	NSArray* tods =[day objectForKey:@"tods"];
	float avg=0; // if hasALS, this will be integrated lux * s * 0.0185 / 1e6 = mol/m^2/d
	
	NSInteger count = tods==nil? 24 : tods.count;
	
	float capMin=[CapTypeTranslator.instance yminInit], capMax =[CapTypeTranslator.instance ymaxInit];
	float tempMin = [TemperatureTypeTranslator.instance yminInit], tempMax = [TemperatureTypeTranslator.instance ymaxInit];
	float luxMin=[LuxTypeTranslator.instance yminInit], luxMax =[LuxTypeTranslator.instance ymaxInit];
	
	for(int i=0;i<count;i++){
		
		NSNumber* val = [CapTypeTranslator.instance preProcess:[caps objectAtIndex:i]];
		if(val){
//			if(self.dewPointMode || self.hasALS){
			if(self.dewPointMode){
				if(self.capIsChipTemperatureMode)
					val = [TemperatureTypeTranslator.instance preProcess:val];
				else
					val= [TemperatureTypeTranslator.instance preProcess:[NSNumber numberWithFloat:dewPoint([val floatValue], [[temps objectAtIndex:i] floatValue])]];
				
				ymax2=fmax(ymax2, [val floatValue]);
				ymin2=fmin(ymin2, [val floatValue]);
			}else{
				capAxisMax=fmax(capAxisMax, [val floatValue]);
				capAxisMin=fmin(capAxisMin, [val floatValue]);
			}
			SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
			dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
			dataPoint.yValue = val;
			if(tods){
				[rawCapSeries addDataPoint:dataPoint];
			}else{
				capMax = fmax(capMax, [val floatValue]); capMin=fmin(capMin, [val floatValue]);
				[capSeries addDataPoint:dataPoint];
			}
		}
		
		if(self.hasALS){
			val = [LuxTypeTranslator.instance preProcess:[lux objectAtIndex:i]];
			if(val){
				SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
				dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
				dataPoint.yValue = val;

				
				luxAxisMax=fmax(luxAxisMax, [val floatValue]);
				luxAxisMin=fmin(luxAxisMin, [val floatValue]);

				if(tods){
					[rawLuxSeries addDataPoint:dataPoint];
					if(i>0){
						int durationSec =[tods[i] intValue]-[tods[i-1] intValue];
						float avg_lux = ([[lux objectAtIndex:i] floatValue]+[[lux objectAtIndex:i-1] floatValue])/2.0f;
						avg += (avg_lux*durationSec)*0.0185f/1e6;
					}
				}else{
					luxMax = fmax(luxMax, [val floatValue]); luxMin=fmin(luxMin, [val floatValue]);
					[luxSeries addDataPoint:dataPoint];
					avg+=[val floatValue]*3600*0.0185/1e6;
				}
			}
		}
		
		val = [TemperatureTypeTranslator.instance preProcess:[temps objectAtIndex:i]];
		if(val){
			SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
			dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
			dataPoint.yValue = val;
			if([self.latestDate timeIntervalSinceDate:dataPoint.xValue]<0)
				self.latestDate = dataPoint.xValue;
			
			if(!self.hasALS)avg+=[val floatValue];
			
			ymax2=fmax(ymax2, [val floatValue]);
			ymin2=fmin(ymin2, [val floatValue]);
			
			if(tods){
				[rawTempSeries addDataPoint:dataPoint];
				//NSLog(@"added %@", dataPoint.xValue);
			}else{
				tempMax = fmax(tempMax, [val floatValue]); tempMin=fmin(tempMin, [val floatValue]);
				[tempSeries addDataPoint:dataPoint];
			}
		}
		
		/*		if(!tods){
			val = [BattTypeTranslator.instance preProcess:[batts objectAtIndex:i]];
			if(val){
		 SChartDataPoint* dataPoint = [SChartDataPoint new];
		 dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
		 dataPoint.yValue = val;
		 [battSeries addObject:dataPoint];
			}
		 }
		 */
	}
	if(!self.hasALS && avg>0)avg/=count;
	
	[self.date2DLI setObject:[NSNumber numberWithFloat:avg] forKey:baseDate];
	
	if(tods==nil){
		//NSInteger bandi= [self findBandArrayIndexFor:baseDate];
		if(capSeries.count>1){
			SChartMultiYDataPoint* capBand = [[SChartMultiYDataPoint new] autorelease];
			capBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
			capBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:capMax], SChartBandKeyLow: [NSNumber numberWithFloat:capMin]}];
//			[bandCapSeries insertObject:capBand atIndex:bandi];
			[bandCapSeries addDailyDataPoint:capBand];
		}
		if(luxSeries.count>1){
			SChartMultiYDataPoint* luxBand = [[SChartMultiYDataPoint new] autorelease];
			luxBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
			luxBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:luxMax], SChartBandKeyLow: [NSNumber numberWithFloat:luxMin]}];
//			[bandLuxSeries insertObject:luxBand atIndex:bandi];
			[bandLuxSeries addDailyDataPoint:luxBand];
		}
		SChartMultiYDataPoint* tempBand = [[SChartMultiYDataPoint new] autorelease];
		tempBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
		tempBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:tempMax], SChartBandKeyLow: [NSNumber numberWithFloat:tempMin]}];
		//[bandTempSeries insertObject:tempBand atIndex:bandi ];
		[bandTempSeries addDailyDataPoint:tempBand];
	}
	return avg;
}

-(void)updateMetadata:(NSDictionary *)d{
	temp_unit =[[d objectForKey:@"temp_unit"] boolValue];
}

// used by daily chart only.
-(void)setDataSingleDay:(NSDictionary *)statsEachHour
{
	[self resetNormalData];
	
	TemperatureTypeTranslator* tempT =TemperatureTypeTranslator.instance;
	ymax2=[tempT ymaxInit]; ymin2=[tempT yminInit];
	[self initCapAxisMinMax];
	if(self.hasALS)[self initLuxAxisMinMax];

	
	float avg = [self processOneDay:statsEachHour baseDate:[TimeOfDayAxis baseDate] title:nil];
	
	if(self.hasALS){
		NSDate* baseDate = [MultiDayAxis dateFromString:[statsEachHour objectForKey:@"date"]];
		NSNumber* dli = [self.date2DLI objectForKey:baseDate];
		self.title = [[statsEachHour objectForKey:@"date"] stringByAppendingFormat:@" DLI: %.2f mol/m\u00B2/d", dli!=nil? [dli floatValue] : avg];
	}else
		self.title = [[statsEachHour objectForKey:@"date"] stringByAppendingFormat:@" Average: %.1f°%@", avg, temp_unit?@"F":@"C" ];
	
	//[self removeYAxis:capAxis];
	self.hasCap =(capSeries.count>0 || rawCapSeries.count>0);
	if(!self.dewPointMode && _hasCap){
		if(![self.allYAxes containsObject:capAxis])
			[self addYAxis:capAxis];
	}
	else 	if([self.allYAxes containsObject:capAxis])
			[self removeYAxis:capAxis];

	/*if(!self.hasALS){
		if(!self.dewPointMode && capSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if((self.dewPointMode || capSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}*/
	
	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	//temperatureAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];

	[self finishCapAxisMinMax];
	if(self.hasALS)[self finishLuxAxisMinMax];

	[self reloadData];
}
-(void)justShownCompleteDay:(NSDate *)date{

	if(self.hasALS){
		NSNumber* dli =self.date2DLI[date];
		if(dli!=nil){
			iToast* toast =[[iToast makeText:[NSString stringWithFormat:@"%@ DLI: %.2f mol/m\u00B2", [MultiDayAxis stringFromDate:date],
											  [dli floatValue]]] setDuration:1500];
			
			toast.theSettings.toastType=iToastTypeInfo;
			[toast show];
		}
	}else{
		NSNumber* dli =self.date2DLI[date];
		if(dli!=nil){
			iToast* toast =[[iToast makeText:[NSString stringWithFormat:@"%@ Average: %.1f°%@",  [MultiDayAxis stringFromDate:date],
											  [dli floatValue], temp_unit?@"F":@"C" ]] setDuration:1500];
			
			toast.theSettings.toastType=iToastTypeInfo;
			[toast show];
		}
	}
}
- (SChartAxis *)sChart:(ShinobiChart *)chart yAxisForSeriesAtIndex:(NSInteger)index {
	
	if(index==0)return temperatureAxis;
	else if(index==1 && _hasCap){
		if(self.dewPointMode)return temperatureAxis;
		else return capAxis;
	}
	else if(_hasALS){
		return _useLogScaleForLight?logAxis:luxAxis;
	}else
		return nil;
	
	/*if(self.hasALS){
		// always has cap.
		if(index==0 || index==1)return temperatureAxis;
		else return _useLogScaleForLight?logAxis:capAxis;
	}else{
		if(index==0 || self.dewPointMode)return temperatureAxis;
		else return capAxis;
	}*/
}
- (NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
	if(self.hasALS){
		return _hasCap? 3:2;
	}else{
		return  _hasCap?2:1;
	}
}

-(SChartSeries*)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
	
	if(_zoomLevel>=ChartZoomLevelBand){
		SChartBandSeries* bandSeries = [[[SChartBandSeries alloc]init]autorelease];
		bandSeries.style.lineWidth=@2;
		if(index==0){
			bandSeries.title=[TemperatureTypeTranslator.instance name];
			bandSeries.style.lineColorLow = bandSeries.style.lineColorHigh = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
			bandSeries.style.areaColorNormal=[UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
		}else if(index==1 && _hasCap){
			bandSeries.title = self.capIsChipTemperatureMode?@"Chip Temperature":[CapTypeTranslator.instance name];
			bandSeries.style.areaColorNormal=[UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.5];
			bandSeries.style.lineColorHigh =bandSeries.style.lineColorLow =[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
		}else{
			bandSeries.title = [LuxTypeTranslator.instance name];
			bandSeries.style.areaColorNormal=[UIColor colorWithRed:(float)0x60/255.0 green:(float)0xa0/255.0  blue:(float)0xdf/255.0 alpha:0.5];
			bandSeries.style.lineColorHigh =bandSeries.style.lineColorLow =[UIColor colorWithRed:(float)0x60/255.0 green:(float)0xa0/255.0 blue:(float)0xdf/255.0 alpha:1];
		}
		return bandSeries;
	}else{
		SChartLineSeries* lineSeries = [[[SChartLineSeries alloc] init] autorelease];
		lineSeries.style.lineWidth=@2;

		if(!forTrend){
			lineSeries.style.pointStyle.radius=@4;
			lineSeries.style.pointStyle.innerRadius=@0.5;
		}
		//lineSeries.style.selectedPointStyle.radius=@8;
		//lineSeries.style.selectedPointStyle.innerRadius=@4;

		//legendItemlineSeries.legendItem
		//lineSeries.style.pointStyle.showPoints=YES;
		if(index==0){
			lineSeries.title=[TemperatureTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(!forTrend && _zoomLevel<ChartZoomLevelNormal);
			
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor = TEMPCOLOR;
			/*	}else if(index==1){
			 lineSeries.title=[BattTypeTranslator.instance name];
			 lineSeries.style.lineColor = [UIColor blueColor];
			 */	}
		else if(index==1 && _hasCap){
			lineSeries.title = self.capIsChipTemperatureMode?@"Chip Temperature": [CapTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(!forTrend && _zoomLevel<ChartZoomLevelNormal);
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor = CAPCOLOR;
		}else{
			lineSeries.title = [LuxTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(!forTrend && _zoomLevel<ChartZoomLevelNormal);
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor =LUXCOLOR;
		}
		//lineSeries.crosshairEnabled=YES;
		return lineSeries;
	}
}
- (NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)index {
	if(_zoomLevel==ChartZoomLevelRaw){
		if(index==0)return rawTempSeries.count;
		else if(index==1 && _hasCap) return rawCapSeries.count;
		else return rawLuxSeries.count;
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		if(index==0)return floor(rawTempSeries.count/2.0);
		else if(index==1 && _hasCap) return floor(rawCapSeries.count/2.0);
		else return floor(rawLuxSeries.count/2.0);
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		if(index==0)return floor(rawTempSeries.count/4.0);
		else if(index==1 && _hasCap) return floor(rawCapSeries.count/4.0);
		else return floor(rawLuxSeries.count/4.0);
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		if(index==0)return tempSeries.count;
		else if(index==1 && _hasCap) return capSeries.count;
		else return luxSeries.count;
	}
	else{
		if(index==0)return bandTempSeries.count;
		else if(index==1 && _hasCap) return bandCapSeries.count;
		else return bandLuxSeries.count;
	}
}

- (id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)index {
	if(_zoomLevel==ChartZoomLevelRaw){
		if(index==0)return rawTempSeries[dataIndex];
		else if(index==1 && _hasCap) return rawCapSeries[dataIndex];
		else return rawLuxSeries[dataIndex];
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		if(index==0)return rawTempSeries[dataIndex*2];
		else if(index==1 && _hasCap) return rawCapSeries[dataIndex*2];
		else return rawLuxSeries[dataIndex*2];
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		if(index==0)return rawTempSeries[dataIndex*4];
		else if(index==1 && _hasCap) return rawCapSeries[dataIndex*4];
		else return rawLuxSeries[dataIndex*4];
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		if(index==0)return tempSeries[dataIndex];
		else if(index==1 && _hasCap) return capSeries[dataIndex];
		else return luxSeries[dataIndex];
	}else{
		if(index==0)return bandTempSeries[dataIndex];
		else if(index==1 && _hasCap) return bandCapSeries[dataIndex];
		else return bandLuxSeries[dataIndex];
	}
}

@end
