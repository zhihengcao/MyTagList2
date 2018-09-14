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
			[self replaceYAxis:capAxis withAxis:logAxis];
//			[self redrawChartIncludePlotArea:YES];
		}
		else if(_useLogScaleForLight  && !useLogScaleForLight){
			[self replaceYAxis:logAxis withAxis:capAxis];

//			[self redrawChartIncludePlotArea:YES];
		}
	}
	_useLogScaleForLight=useLogScaleForLight;
}
-(id)initWithFrame:(CGRect)frame{
	self=[super initWithFrame:frame];
	if(self){
		_useLogScaleForLight = [[NSUserDefaults standardUserDefaults] boolForKey:LogScalePrefKey];
		
		self.type = TemperatureTypeTranslator.instance;
		UIFont* labelFont = [self.titleLabel.font fontWithSize:10.0];
		self.xAxis =[[[TimeOfDayAxis alloc]initWithFont:labelFont]autorelease];
		self.xAxis.allowPanningOutOfDefaultRange=self.xAxis.allowPanningOutOfMaxRange=YES;
		
		temperatureAxis = [[[SChartNumberAxis alloc] init] autorelease];
		
		capAxis = [[SChartNumberAxis alloc] init] ;
		
		//capAxis.rangePaddingHigh = @50;
		
		/*batteryVoltAxis=[[[SChartNumberAxis alloc] initWithRange:
		 [[[SChartNumberRange alloc] initWithMinimum:@2.6 andMaximum:@3.1] autorelease]] autorelease];
		 batteryVoltAxis.style.lineWidth=@0.5;
		 batteryVoltAxis.axisPosition = SChartAxisPositionReverse;
		 #ifndef DEBUG
		 batteryVoltAxis.width=@27;
		 #endif
		 batteryVoltAxis.style.majorTickStyle.tickGap=@-6;
		 batteryVoltAxis.labelFormatString=[BattTypeTranslator.instance labelFormat];
		 batteryVoltAxis.style.interSeriesPadding=@0;
		 batteryVoltAxis.style.majorTickStyle.labelFont= labelFont;
		 
		 //batteryVoltAxis.style.majorTickStyle.showTicks=YES;
		 batteryVoltAxis.majorTickFrequency=@0.1;
		 */
		
		temperatureAxis.style.lineWidth=@0.5;
		temperatureAxis.style.interSeriesSetPadding=@0;
		temperatureAxis.style.majorTickStyle.labelFont = labelFont;
		temperatureAxis.style.majorTickStyle.showTicks=YES;
		temperatureAxis.style.majorTickStyle.labelColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
		//temperatureAxis.style.minorTickStyle.showTicks=YES;
		//temperatureAxis.style.majorTickStyle.lineWidth=@1;
		//temperatureAxis.style.majorTickStyle.lineLength=@0;
		//temperatureAxis.style.majorGridLineStyle.showMajorGridLines=YES;
		//temperatureAxis.style.majorTickStyle.showTicks=YES;
		//#ifndef DEBUG
		//temperatureAxis.width=@25;
		//#endif
		temperatureAxis.style.majorTickStyle.tickGap=@-2;
		temperatureAxis.enableGesturePanning=YES;
		temperatureAxis.enableGestureZooming=YES;
		//temperatureAxis.style.interSeriesSetPadding=@0;
		
		capAxis.style.lineWidth=@0;
		capAxis.style.interSeriesSetPadding=@0;
		capAxis.style.majorTickStyle.labelFont= labelFont;
		capAxis.style.majorTickStyle.showTicks=YES;
//		capAxis.style.majorTickStyle.lineWidth=@1;
//		capAxis.style.majorTickStyle.lineLength=@50;
//		capAxis.style.minorTickStyle.showTicks=YES;
		capAxis.style.majorTickStyle.labelColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
		capAxis.axisPosition = SChartAxisPositionReverse;
		//capAxis.style.majorGridLineStyle.showMajorGridLines=YES;
		//capAxis.style.majorGridLineStyle.dashedMajorGridLines=YES;
		
//		capAxis.allowPanningOutOfMaxRange=YES;
//		capAxis.allowPanningOutOfDefaultRange=YES;
		
//		capAxis.defaultRange =
//		[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:0.1] andMaximum:[NSNumber numberWithFloat:99.9]] autorelease];
		capAxis.enableGesturePanning=YES;
		capAxis.enableGestureZooming=YES;
		//#ifndef DEBUG
		//capAxis.width=@30;
		//#endif
		capAxis.style.majorTickStyle.tickGap=@-3;
		
		//capAxis.style.interSeriesSetPadding=@0;
		
		self.yAxis = temperatureAxis;

		//if(!self.dewPointMode)
		//	[self addYAxis:capAxis];
		
		self.datasource=self;
		
		tempSeries=[[NSMutableArray alloc]init];
		capSeries=[[NSMutableArray alloc]init];
		//battSeries=[[NSMutableArray alloc]init];
		rawTempSeries=[[NSMutableArray alloc]init];
		rawCapSeries=[[NSMutableArray alloc]init];
		bandCapSeries=[[NSMutableArray alloc]init];
		bandTempSeries = [[NSMutableArray alloc] init];
		
		self.date2DLI=[[[NSMutableDictionary alloc]init] autorelease];
	}
	NSLog(@"SingleTagChart::init");
	return self;
}
-(void)setHasALS:(BOOL)hasALS
{
	if(hasALS && !_hasALS){
		
		logAxis = [[SChartLogarithmicAxis alloc]init];
		logAxis.axisPosition = SChartAxisPositionReverse;
		//		logAxis.labelFormatString = [LuxTypeTranslator.instance labelFormat];
		logAxis.style.lineWidth=@0;
		logAxis.style.majorTickStyle.tickGap=@-3;
		logAxis.style.interSeriesSetPadding=@0;
		logAxis.style.majorTickStyle.labelFont= [self.titleLabel.font fontWithSize:10.0];
		logAxis.style.majorTickStyle.labelColor=[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
		logAxis.enableGesturePanning=YES;
		logAxis.enableGestureZooming=YES;
		//logAxis.width=@30;

		logAxis.labelFormatter = [LuxTickFormatter instance];
//		logAxis.axisLabelsAreFixed=YES;
		logAxis.width=@30;
		if(self.allYAxes.count==1){
			[self addYAxis:_useLogScaleForLight?logAxis:capAxis];
		}
		capAxis.style.majorGridLineStyle.showMajorGridLines=YES;
		logAxis.style.majorGridLineStyle.showMajorGridLines=YES;
	}
	
	_hasALS=hasALS;
	if(hasALS){
		capAxis.labelFormatter = [LuxTickFormatter instance];
//		capAxis.axisLabelsAreFixed=YES;
		capAxis.width=@30;
	}else{
		capAxis.majorTickFrequency=@20;
		capAxis.labelFormatString =[CapTypeTranslator.instance labelFormat];
		temperatureAxis.style.majorGridLineStyle.showMajorGridLines=YES;
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
}

-(void)resetNormalData{
	[tempSeries removeAllObjects];
	[capSeries removeAllObjects];
	[bandCapSeries removeAllObjects];
	[bandTempSeries removeAllObjects];
	[luxSeries removeAllObjects];
	[bandLuxSeries removeAllObjects];
	//[battSeries removeAllObjects];
}
-(void)initSecondaryAxisMinMax{
	id<StatTypeTranslator> secondaryAxisT;
	if(_hasALS){
		secondaryAxisT = LuxTypeTranslator.instance;
	}else{
		secondaryAxisT = CapTypeTranslator.instance;
	}
	secondaryAxisMax = [secondaryAxisT ymaxInit];
	secondaryAxisMin = [secondaryAxisT yminInit];
}
-(void)finishSecondaryAxisMinMax{
	id<StatTypeTranslator> secondaryAxisT;
	if(_hasALS){
		secondaryAxisT = LuxTypeTranslator.instance;
	}else{
		secondaryAxisT = CapTypeTranslator.instance;
	}
	secondaryAxisMax = [secondaryAxisT ymaxPost:secondaryAxisMax];
	secondaryAxisMin = [secondaryAxisT yminPost:secondaryAxisMin];
	
	capAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:secondaryAxisMin] andMaximum:[NSNumber numberWithFloat:secondaryAxisMax]] autorelease];
	if(self.hasALS)logAxis.defaultRange= capAxis.defaultRange;
}
-(void)setRawDataMultipleDays: (NSArray*) dataDays{
	
	[rawTempSeries removeAllObjects];
	[rawCapSeries removeAllObjects];
	[rawLuxSeries removeAllObjects];

	TemperatureTypeTranslator* tempT =TemperatureTypeTranslator.instance;
	ymax2=[tempT ymaxInit];
	ymin2=[tempT yminInit];
	[self initSecondaryAxisMinMax];
	
	for(NSDictionary* day in dataDays){
		NSLog(@"processOneDay(%@)", [day objectForKey:@"date"]);
		[self processOneDay:day baseDate:[MultiDayAxis dateFromString:[day objectForKey:@"date"]] title:nil];
	}

	if(!self.hasALS){
		if(!self.dewPointMode && rawCapSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if((self.dewPointMode || rawCapSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}

	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];

	[self finishSecondaryAxisMinMax];
	
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
	[self initSecondaryAxisMinMax];
	
	//NSArray* dataDays =[data objectForKey:@"temps"];
	
	NSInteger nDays = dataDays.count;
	for(NSInteger i=1;i<=nDays;i++){
		NSDictionary* day =[dataDays objectAtIndex:(nDays-i)];
		NSDate* baseDate =[MultiDayAxis dateFromString:[day objectForKey:@"date"]];
		
		if(i==1)self.earliestDate=baseDate;
		else if(i==nDays)self.latestDate=baseDate;
		
		[self processOneDay:day baseDate:baseDate title:nil];
	}
	
	if(!self.hasALS){
		if( !self.dewPointMode && capSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if( (self.dewPointMode|| capSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}
	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	//temperatureAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];
	[self finishSecondaryAxisMinMax];
	
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
			if(self.dewPointMode || self.hasALS){
				if(self.capIsChipTemperatureMode)
					val = [TemperatureTypeTranslator.instance preProcess:val];
				else
					val= [TemperatureTypeTranslator.instance preProcess:[NSNumber numberWithFloat:dewPoint([val floatValue], [[temps objectAtIndex:i] floatValue])]];
				
				ymax2=fmax(ymax2, [val floatValue]);
				ymin2=fmin(ymin2, [val floatValue]);
			}else{
				secondaryAxisMax=fmax(secondaryAxisMax, [val floatValue]);
				secondaryAxisMin=fmin(secondaryAxisMin, [val floatValue]);
			}
			SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
			dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
			dataPoint.yValue = val;
			if(tods)
				[rawCapSeries addObject:dataPoint];
			else{
				capMax = fmax(capMax, [val floatValue]); capMin=fmin(capMin, [val floatValue]);
				[capSeries addObject:dataPoint];
			}
		}
		
		if(self.hasALS){
			val = [LuxTypeTranslator.instance preProcess:[lux objectAtIndex:i]];
			if(val){
				SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
				dataPoint.xValue = [NSDate dateWithTimeInterval:(tods? [tods[i] intValue]:3600*i) sinceDate:baseDate];
				dataPoint.yValue = val;

				
				secondaryAxisMax=fmax(secondaryAxisMax, [val floatValue]);
				secondaryAxisMin=fmin(secondaryAxisMin, [val floatValue]);

				if(tods){
					[rawLuxSeries addObject:dataPoint];
					if(i>0){
						int durationSec =[tods[i] intValue]-[tods[i-1] intValue];
						float avg_lux = ([[lux objectAtIndex:i] floatValue]+[[lux objectAtIndex:i-1] floatValue])/2.0f;
						avg += (avg_lux*durationSec)*0.0185f/1e6;
					}
				}else{
					luxMax = fmax(luxMax, [val floatValue]); luxMin=fmin(luxMin, [val floatValue]);
					[luxSeries addObject:dataPoint];
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
				[rawTempSeries addObject:dataPoint];
				//NSLog(@"added %@", dataPoint.xValue);
			}else{
				tempMax = fmax(tempMax, [val floatValue]); tempMin=fmin(tempMin, [val floatValue]);
				[tempSeries addObject:dataPoint];
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
	if(!self.hasALS)avg/=tempSeries.count;
	
	[self.date2DLI setObject:[NSNumber numberWithFloat:avg] forKey:baseDate];
	
	if(tods==nil){
		//NSInteger bandi= [self findBandArrayIndexFor:baseDate];
		if(capSeries.count>1){
			SChartMultiYDataPoint* capBand = [[SChartMultiYDataPoint new] autorelease];
			capBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
			capBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:capMax], SChartBandKeyLow: [NSNumber numberWithFloat:capMin]}];
//			[bandCapSeries insertObject:capBand atIndex:bandi];
			[bandCapSeries addObject:capBand];
		}
		if(luxSeries.count>1){
			SChartMultiYDataPoint* luxBand = [[SChartMultiYDataPoint new] autorelease];
			luxBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
			luxBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:luxMax], SChartBandKeyLow: [NSNumber numberWithFloat:luxMin]}];
//			[bandLuxSeries insertObject:luxBand atIndex:bandi];
			[bandLuxSeries addObject:luxBand];
		}
		SChartMultiYDataPoint* tempBand = [[SChartMultiYDataPoint new] autorelease];
		tempBand.xValue = [baseDate dateByAddingTimeInterval:3600*12];
		tempBand.yValues = [NSMutableDictionary dictionaryWithDictionary:@{SChartBandKeyHigh: [NSNumber numberWithFloat:tempMax], SChartBandKeyLow: [NSNumber numberWithFloat:tempMin]}];
		//[bandTempSeries insertObject:tempBand atIndex:bandi ];
		[bandTempSeries addObject:tempBand];
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
	[self initSecondaryAxisMinMax];
	
	float avg = [self processOneDay:statsEachHour baseDate:[TimeOfDayAxis baseDate] title:nil];
	
	if(self.hasALS){
		NSDate* baseDate = [MultiDayAxis dateFromString:[statsEachHour objectForKey:@"date"]];
		NSNumber* dli = [self.date2DLI objectForKey:baseDate];
		self.title = [[statsEachHour objectForKey:@"date"] stringByAppendingFormat:@" (DLI %.2f mol/m\u00B2/d)", dli!=nil? [dli floatValue] : avg];
	}else
		self.title = [[statsEachHour objectForKey:@"date"] stringByAppendingFormat:@" (Average %.1f°%@)", avg, temp_unit?@"F":@"C" ];
	
	if(!self.hasALS){
		if(!self.dewPointMode && capSeries.count>0 && self.allYAxes.count==1){
			[self addYAxis:capAxis];
		}else if((self.dewPointMode || capSeries.count==0) && self.allYAxes.count==2){
			[self removeYAxis:capAxis];
		}
	}
	ymin2 =[tempT yminPost:ymin2]; ymax2=[tempT ymaxPost:ymax2];
	//temperatureAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
	temperatureAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];
	[self finishSecondaryAxisMinMax];
	
	[self reloadData];
}
-(void)justShownCompleteDay:(NSDate *)date{

	if(self.hasALS){
		NSNumber* dli =self.date2DLI[date];
		if(dli!=nil){
			iToast* toast =[[iToast makeText:[NSString stringWithFormat:@"%@: %.2f mol/m\u00B2", [MultiDayAxis stringFromDate:date],
											  [dli floatValue]]] setDuration:iToastDurationNormal];
			
			toast.theSettings.toastType=iToastTypeInfo;
			[toast show];
		}
	}
}
- (SChartAxis *)sChart:(ShinobiChart *)chart yAxisForSeriesAtIndex:(NSInteger)index {
	
	if(self.hasALS){
		// always has cap.
		if(index==0 || index==1)return temperatureAxis;
		else return _useLogScaleForLight?logAxis:capAxis;
	}else{
		if(index==0 || self.dewPointMode)return temperatureAxis;
		else return capAxis;
	}
}

- (NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
	if(self.hasALS){
		return 3;
	}else{
		return  (capSeries.count>0 || rawCapSeries.count>0)?2:1;
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
		}else if(index==1){
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
		lineSeries.style.pointStyle.radius=@4;
		lineSeries.style.pointStyle.innerRadius=@0.5;

		//lineSeries.style.selectedPointStyle.radius=@8;
		//lineSeries.style.selectedPointStyle.innerRadius=@4;

		//legendItemlineSeries.legendItem
		//lineSeries.style.pointStyle.showPoints=YES;
		if(index==0){
			lineSeries.title=[TemperatureTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(_zoomLevel<ChartZoomLevelNormal);
			
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor = [UIColor redColor];
			/*	}else if(index==1){
			 lineSeries.title=[BattTypeTranslator.instance name];
			 lineSeries.style.lineColor = [UIColor blueColor];
			 */	}
		else if(index==1){
			lineSeries.title = self.capIsChipTemperatureMode?@"Chip Temperature": [CapTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(_zoomLevel<ChartZoomLevelNormal);
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
		}else{
			lineSeries.title = [LuxTypeTranslator.instance name];
			lineSeries.style.pointStyle.showPoints=(_zoomLevel<ChartZoomLevelNormal);
			lineSeries.style.pointStyle.color= lineSeries.style.lineColor =[UIColor colorWithRed:(float)0x60/255.0 green:(float)0xa0/255.0 blue:(float)0xdf/255.0 alpha:1];
		}
		//lineSeries.crosshairEnabled=YES;
		return lineSeries;
	}
}
- (NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)index {
	if(_zoomLevel==ChartZoomLevelRaw){
		if(index==0)return rawTempSeries.count;
		else if(index==1) return rawCapSeries.count;
		else return rawLuxSeries.count;
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		if(index==0)return floor(rawTempSeries.count/2.0);
		else if(index==1) return floor(rawCapSeries.count/2.0);
		else return floor(rawLuxSeries.count/2.0);
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		if(index==0)return floor(rawTempSeries.count/4.0);
		else if(index==1) return floor(rawCapSeries.count/4.0);
		else return floor(rawLuxSeries.count/4.0);
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		if(index==0)return tempSeries.count;
		else if(index==1) return capSeries.count;
		else return luxSeries.count;
	}
	else{
		if(index==0)return bandTempSeries.count;
		else if(index==1) return bandCapSeries.count;
		else return bandLuxSeries.count;
	}
}

- (id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)index {
	if(_zoomLevel==ChartZoomLevelRaw){
		if(index==0)return rawTempSeries[dataIndex];
		else if(index==1) return rawCapSeries[dataIndex];
		else return rawLuxSeries[dataIndex];
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		if(index==0)return rawTempSeries[dataIndex*2];
		else if(index==1) return rawCapSeries[dataIndex*2];
		else return rawLuxSeries[dataIndex*2];
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		if(index==0)return rawTempSeries[dataIndex*4];
		else if(index==1) return rawCapSeries[dataIndex*4];
		else return rawLuxSeries[dataIndex*4];
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		if(index==0)return tempSeries[dataIndex];
		else if(index==1) return capSeries[dataIndex];
		else return luxSeries[dataIndex];
	}else{
		if(index==0)return bandTempSeries[dataIndex];
		else if(index==1) return bandCapSeries[dataIndex];
		else return bandLuxSeries[dataIndex];
	}
}

@end
