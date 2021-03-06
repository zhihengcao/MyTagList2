//
//  MultiTagChart.m
//  MyTagList2
//
//  Created by cao on 1/31/15.
//
//

#import "MultiTagChart.h"

@implementation MultiTagChart
@synthesize type=_type, useLogScaleForLight=_useLogScaleForLight;

-(void)setUseLogScaleForLight:(BOOL)useLogScaleForLight{

	if(_useLogScaleForLight!=useLogScaleForLight){
		self.yAxis = useLogScaleForLight? [[[SChartLogarithmicAxis alloc] init] autorelease] : [[[SChartNumberAxis alloc] init] autorelease];
		[self setupYAxis:self.yAxis];
//		[self redrawChartIncludePlotArea:YES];
	}
	_useLogScaleForLight = useLogScaleForLight;
}

-(void)updateMetadata:(NSDictionary *)d{
	self.id2nameMapping=[[[NSMutableDictionary alloc]init] autorelease];
	for(int i=0;i<[[d objectForKey:@"ids"] count];i++){
		[self.id2nameMapping setObject:[[d objectForKey:@"names"]objectAtIndex:i] forKey:[[d objectForKey:@"ids"]objectAtIndex:i]];
	}
	if(arrayOfIds==nil){
		arrayOfIds=[[NSMutableArray alloc]initWithCapacity:self.id2nameMapping.count];
		for(NSNumber* key in self.id2nameMapping){
			[arrayOfIds addObject:key];
		}
	}
	temp_unit =[[d objectForKey:@"temp_unit"] boolValue];
}

-(id)initWithFrame:(CGRect)frame andType:(id<StatTypeTranslator>)type {
	self=[super initWithFrame:frame];
	if(self){
		
		_useLogScaleForLight = [[NSUserDefaults standardUserDefaults] boolForKey:LogScalePrefKey];
		self.colors = @[
				   [UIColor colorWithRed:(float)0x7c/255.0 green:(float)0xb5/255.0 blue:(float)0xec/255.0 alpha:0.95],    // too cold color
				   [UIColor colorWithRed:(float)0x43/255.0 green:(float)0x43/255.0 blue:(float)0x48/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x90/255.0 green:(float)0xed/255.0 blue:(float)0x7d/255.0 alpha:0.95],
				   	[UIColor colorWithRed:(float)0xf7/255.0 green:(float)0xa3/255.0 blue:(float)0x5c/255.0 alpha:0.95],    // too dry color
				   
				   
				   [UIColor colorWithRed:(float)0x80/255.0 green:(float)0x85/255.0 blue:(float)0xe9/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0xf1/255.0 green:(float)0x5c/255.0 blue:(float)0x80/255.0 alpha:0.95],
				   
				   [UIColor colorWithRed:(float)0xe4/255.0 green:(float)0xd3/255.0 blue:(float)0x54/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x2b/255.0 green:(float)0x90/255.0 blue:(float)0x8f/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0xf4/255.0 green:(float)0x5b/255.0 blue:(float)0x5b/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x91/255.0 green:(float)0xe8/255.0 blue:(float)0xe1/255.0 alpha:0.95]
				   ];

		
		UIFont* labelFont = [UIFont systemFontOfSize:11.0]; //[self.titleLabel.font fontWithSize:10.0];
		self.xAxis =[[[TimeOfDayAxis alloc]initWithFont:labelFont forTrend:NO]autorelease];
		self.xAxis.allowPanningOutOfDefaultRange=self.xAxis.allowPanningOutOfMaxRange= YES;
		
		_type=type;
		if([_type isKindOfClass:[LuxTypeTranslator class]]){
			self.legend.position= SChartLegendPositionTopMiddle;
			self.yAxis = _useLogScaleForLight?[[[SChartLogarithmicAxis alloc] init] autorelease] : [[[SChartNumberAxis alloc] init] autorelease];
		}else
			self.yAxis =[[[SChartNumberAxis alloc] init] autorelease];
	
		[super setupYAxis:self.yAxis];
		
		id2Series= [NSMutableDictionary new];
		id2BandSeries= [NSMutableDictionary new];
		id2RawSeries= [NSMutableDictionary new];
		
		self.datasource=self;
		
		self.date2DLI=[[[NSMutableDictionary alloc]init] autorelease];

	}
	NSLog(@"MultiTagChart::init");
	return self;
}


-(void)dealloc{
	NSLog(@"MultiTagChart::dealloc");
	self.colors=nil;
	[id2Series release]; id2Series=nil;
	[id2BandSeries release]; id2BandSeries=nil;
	[id2RawSeries release]; id2RawSeries=nil;
	[arrayOfIds release]; arrayOfIds=nil;
	self.id2nameMapping=nil;
	self.date2DLI=nil;
	[super dealloc];
}
-(void)resetNormalData{
	[id2Series removeAllObjects];
	[id2BandSeries removeAllObjects];
	[_date2DLI removeAllObjects];
}

// must be called from earliest date
-(float)processOneDay:(NSDictionary *)hourlyStatDay baseDate:(NSDate*)baseDate title:(NSMutableString*)title{
	float avg2=0;
	NSMutableDictionary* id2DLI=nil;
	if(![_type isKindOfClass:[MotionTypeTranslator class]])id2DLI = [[NSMutableDictionary new] autorelease];

	NSInteger tagCount = [[hourlyStatDay objectForKey:@"ids"] count];
	NSArray* values =[hourlyStatDay objectForKey:@"values_base64"], *tods=[hourlyStatDay objectForKey:@"tods_base64"], *ids=[hourlyStatDay objectForKey:@"ids"];
	
	for(int tagi=0;tagi<tagCount;tagi++){
		
		NSData* tagv =[NSData dataFromBase64String: [values objectAtIndex:tagi]];
		
		NSNumber* tagId =[ids objectAtIndex:tagi ];
		
		if(![arrayOfIds containsObject:tagId])
			[arrayOfIds addObject:tagId];
		
		NSMutableArray* series=nil;
		NSMutableArray* rawSeries=nil;
		NSData* tod=nil;
		if(tods){
			tod=[NSData dataFromBase64String: [tods objectAtIndex:tagi]];
			rawSeries=[id2RawSeries objectForKey:tagId];
			if(rawSeries==nil){
				rawSeries = [[[NSMutableArray alloc]initWithCapacity:tagv.length/sizeof(double)] autorelease];
				[id2RawSeries setObject:rawSeries forKey:tagId];
			}
		}else{
			series =[id2Series objectForKey:tagId];
			if(series==nil){
				series = [[[NSMutableArray alloc]initWithCapacity:tagv.length/sizeof(double)] autorelease];
				[id2Series setObject:series forKey:tagId];
			}
		}
		
		float ymin=[_type yminInit], ymax =[_type ymaxInit];
		float avg =0;

		double *raw, *prev_raw;
		UInt32 *raw_tod, *prev_raw_tod;
		for(int j=0;j<tagv.length/sizeof(double);j++){
			prev_raw = raw;
			//memcpy(&raw, [tagv bytes]+j*sizeof(double), sizeof(double));
			raw = (double*)((char*)[tagv bytes]+j*8);
			NSNumber* val = [_type preProcess:[NSNumber numberWithDouble:*raw]];
			
			if(tod){
				prev_raw_tod = raw_tod;
				//memcpy(&raw_tod, [tod bytes]+j*sizeof(raw_tod), sizeof(raw_tod));
				raw_tod = (UInt32*)((char*)[tod bytes]+j*4);
			}
			
			if(val){
				SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
				dataPoint.xValue = [NSDate dateWithTimeInterval:(tod? *raw_tod:3600*j) sinceDate:baseDate];
				dataPoint.yValue = val;
				
				
				if(tod){
					[rawSeries addDataPoint:dataPoint];

					if([self.latestDate timeIntervalSinceDate:dataPoint.xValue]<0)
						self.latestDate = dataPoint.xValue;

					if([_type isKindOfClass:[LuxTypeTranslator class]]){
						if(j>0){
							int durationSec = *raw_tod- *prev_raw_tod;
							float avg_lux = (*raw+*prev_raw)/2.0f;
							avg += (avg_lux*durationSec)*0.0185f/1e6;
						}
					}else{
						/*if(j>0){
							int durationSec =[tod[j] intValue]-[tod[j-1] intValue];
							float avg_val = ([[_type preProcess:[tagv objectAtIndex:j]] floatValue]+[[_type preProcess:[tagv objectAtIndex:j-1]] floatValue])/2.0f;
							avg += (avg_val*durationSec)/3600.0/24.0;
						}*/
						avg+=[val floatValue];
					}

					//NSLog(@"added %@", dataPoint.xValue);
				}else{
					ymax = fmax(ymax, [val floatValue]); ymin=fmin(ymin, [val floatValue]);
					[series addDataPoint:dataPoint];

					if([_type isKindOfClass:[LuxTypeTranslator class]]){
						avg+=[val floatValue]*3600*0.0185/1e6;
					}else{
						avg+=[val floatValue];
					}
				}
				ymax2 = fmax([val floatValue], ymax2);
				ymin2 = fmin([val floatValue], ymin2);
			}
		}
		if(![_type isKindOfClass:[LuxTypeTranslator class]])
			avg/=(tagv.length/sizeof(double));

		if(tod==nil){
			NSMutableArray* bandSeries =[id2BandSeries objectForKey:tagId];
			if(bandSeries==nil){
				bandSeries = [[[NSMutableArray alloc]init] autorelease];
				[id2BandSeries setObject:bandSeries forKey:tagId];
			}
			
			//int bandi= [self findBandArrayIndexFor:baseDate fromSeries:bandSeries];
			
			if([_type isKindOfClass:[MotionTypeTranslator class]]){
				SChartDataPoint* band = [[SChartDataPoint new] autorelease];
				band.xValue = [baseDate dateByAddingTimeInterval:3600*12];
				band.yValue = [NSNumber numberWithInteger:avg];
				//[bandSeries insertObject:band atIndex:bandi];
				[bandSeries addObject:band];
			}else{
				SChartMultiYDataPoint* band = [[SChartMultiYDataPoint new] autorelease];
				band.xValue = [baseDate dateByAddingTimeInterval:3600*12];
				band.yValues = [NSMutableDictionary dictionaryWithDictionary:
								@{SChartBandKeyHigh: [NSNumber numberWithFloat:ymax], SChartBandKeyLow: [NSNumber numberWithFloat:ymin]}];
				//[bandSeries insertObject:band atIndex:bandi];
				[bandSeries addDailyDataPoint:band];
			}
		}
		
		
		if(![_type isKindOfClass:[MotionTypeTranslator class]])
			[id2DLI setObject:[NSNumber numberWithFloat:avg] forKey:tagId];

		if(title){
			[title appendFormat:[_type labelFormat], avg];
			if(tagi<tagCount-1)
				[title appendString:@","];
		}
		avg2+=avg;
	}
	if(id2DLI!=nil){
		if(id2DLI.count>0)
		   [self.date2DLI setObject:id2DLI forKey:baseDate];
	}
		
	return avg2/tagCount;
}
-(void)justShownCompleteDay:(NSDate *)date{
	if([_type isKindOfClass:[MotionTypeTranslator class]])return;
	NSMutableDictionary* id2DLI =self.date2DLI[date];
	if(id2DLI==nil)return;
	NSUInteger count = id2DLI.count;
	iToast* toast;
	if(count>1){
		NSMutableArray* a = [[[NSMutableArray alloc]initWithCapacity:count]autorelease];

		if([_type isKindOfClass:[LuxTypeTranslator class]]){
			for(NSNumber* tagId in id2DLI.allKeys){
				[a addObject:[NSString stringWithFormat:@"%@: %.2f mol/m\u00B2", [_id2nameMapping objectForKey:tagId], [[id2DLI objectForKey:tagId] floatValue] ]];
			}
			toast=[[iToast makeText:[NSString stringWithFormat:@"%@ DLI: \n%@", [MultiDayAxis stringFromDate:date], [a componentsJoinedByString:@"\n"]]] setDuration:4500];
		}else{
			for(NSNumber* tagId in id2DLI.allKeys){
				[a addObject:[NSString stringWithFormat:@"%@: %@", [_id2nameMapping objectForKey:tagId],
							  [NSString stringWithFormat:_type.labelFormat,  [[id2DLI objectForKey:tagId] floatValue] ] ]];
			}
			toast=[[iToast makeText:[NSString stringWithFormat:@"%@ Averages: \n%@", [MultiDayAxis stringFromDate:date], [a componentsJoinedByString:@"\n"]]] setDuration:4500];
		}
	}else{
		NSNumber* dli = [id2DLI.allValues objectAtIndex:0];
		if([_type isKindOfClass:[LuxTypeTranslator class]]){
			toast=[[iToast makeText:[NSString stringWithFormat:@"%@ DLI: %.2f mol/m\u00B2", [MultiDayAxis stringFromDate:date], [dli floatValue] ]] setDuration:2000];
		}else{
			toast =[[iToast makeText:[NSString stringWithFormat:@"%@ Average: %@",  [MultiDayAxis stringFromDate:date],
											  [NSString stringWithFormat:_type.labelFormat, [dli floatValue]] ]] setDuration:2000];
		}
	}
	
	toast.theSettings.toastType=iToastTypeInfo;
	[toast show];
}

- (void) setDataSingleDay:(NSDictionary*) hourlyStatDay andMapping:(NSMutableDictionary*)mapping{
	self.id2nameMapping = mapping;
	
	NSInteger tagCount =[[hourlyStatDay objectForKey:@"values"] count];
	
	[self resetNormalData];
	[arrayOfIds release]; arrayOfIds=[[NSMutableArray alloc]initWithCapacity:tagCount];
	
	NSMutableString* title=[[[[hourlyStatDay objectForKey:@"date"] stringByAppendingString:@" - Average: "] mutableCopy] autorelease];
	
	ymax2=[_type ymaxInit];
	ymin2=[_type yminInit];
	[self processOneDay:hourlyStatDay baseDate:[TimeOfDayAxis baseDate] title:title ];
	self.title = title;
	ymin2 =[_type yminPost:ymin2]; ymax2=[_type ymaxPost:ymax2];
	//self.yAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
	self.yAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];
	
	NSLog(@"setDataSingleDay reload data");
	[self reloadData];
//	[self redrawChartIncludePlotArea:YES];
}
-(void)setRawDataMultipleDays: (NSArray*) dataDays{
	
	[id2RawSeries removeAllObjects];
/*	if(arrayOfIds==nil){
		arrayOfIds=[[NSMutableArray alloc]initWithCapacity:self.id2nameMapping.count];
		for(NSNumber* key in self.id2nameMapping){
			[arrayOfIds addObject:key];
		}
	}*/  // done by updateMetadata
	
	ymax2=[_type ymaxInit]; ymin2=[_type yminInit];

	for(NSDictionary* day in dataDays){
		[self processOneDay:day baseDate:[MultiDayAxis dateFromString:[day objectForKey:@"date"]] title:nil];
	}
	
	ymin2 =[_type yminPost:ymin2]; ymax2=[_type ymaxPost:ymax2];

	self.yAxis.defaultRange =
	[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];

	NSLog(@"setRawDataMultipleDays reload data");
	[self reloadData];
	[self redrawChartIncludePlotArea:YES];
}

-(void)setDataMultipleDays:(NSArray *)dataDays withZoom:(SChartDateRange *)range
{
	[self resetNormalData];

	if([dataDays count]==0){
		iToast* t =[[iToast makeText:@"No data available."] setDuration:iToastDurationNormal];
		[t showFrom:nil];
		return;
	}
	
	/*if(arrayOfIds==nil){
		arrayOfIds=[[NSMutableArray alloc]initWithCapacity:self.id2nameMapping.count];
		//	[arrayOfIds release]; arrayOfIds=[[NSMutableArray alloc]initWithCapacity:self.id2nameMapping.count];
		
		for(NSNumber* key in self.id2nameMapping){
			[arrayOfIds addObject:key];
		}
	}*/
	ymax2=[_type ymaxInit]; ymin2=[_type yminInit];
	
	//NSArray* dataDays =[data objectForKey:@"stats"];
	
	NSInteger nDays = dataDays.count;
	for(int i=1;i<=nDays;i++){
		NSDictionary* day =[dataDays objectAtIndex:(nDays-i)];
		
		NSDate* baseDate =[MultiDayAxis dateFromString:[day objectForKey:@"date"]];
		if(i==1)self.earliestDate=baseDate;
		else if(i==nDays)self.latestDate=baseDate;
		
		[self processOneDay:day baseDate:baseDate title:nil];
	}

	if(range!=nil)nDays = [range.maximumAsDate timeIntervalSinceDate:range.minimumAsDate]/3600.0/24.0;

	if(nDays>24){
		_zoomLevel=ChartZoomLevelBand;
	}else{
		_zoomLevel = ChartZoomLevelNormal;
	}
	
//	if(![_type isKindOfClass:[MotionTypeTranslator class]] || _zoomLevel==ChartZoomLevelNormal){
		ymin2 =[_type yminPost:ymin2]; ymax2=[_type ymaxPost:ymax2];

		//self.yAxis.majorTickFrequency=[NSNumber numberWithFloat:(ymax2-ymin2)/10];
		self.yAxis.defaultRange =
		[[[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:ymin2] andMaximum:[NSNumber numberWithFloat:ymax2]] autorelease];
	//}
	NSLog(@"setDataMultipleDays reload data");
	[self reloadData];
	[self redrawChartIncludePlotArea:YES];
}
-(void)enteredNormalLevelWithRange:(SChartDateRange *)range done:(loadDone_t)done{
	if(id2Series.count==0){
		if(self.hourlyData==nil){
			self.hourlyDataLoader(^(NSMutableDictionary* data){
				self.hourlyData=data;
				[self updateMetadata:data];
				self.onLoadDone=done;
				[self setDataMultipleDays:[data objectForKey:@"stats"] withZoom:range];
				//[self redrawChartIncludePlotArea:YES];
			});
		}else{
			[self updateMetadata:self.hourlyData];
			self.onLoadDone=done;
			[self setDataMultipleDays:[self.hourlyData objectForKey:@"stats"] withZoom:range];
			//[self redrawChartIncludePlotArea:YES];
		}
	}else{
		self.onLoadDone=done;
		[self zoomLevelChanged];
	}
}

-(int) findBandArrayIndexFor:(NSDate*)date fromSeries:(NSArray*)series{
	
	int i=0;
	for(;i<series.count;i++){
		SChartDataPoint* dp =series[i];
		if([(NSDate*)dp.xValue compare:date]==NSOrderedDescending)return i;
	}
	return i;
}

- (NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
	return arrayOfIds.count;
}

-(SChartSeries*)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {

	UIColor* color =[self.colors objectAtIndex:(index%10)];
	
	if([_type isKindOfClass:[MotionTypeTranslator class]]){
		if(_zoomLevel>=ChartZoomLevelNormal){
			self.yAxis.labelFormatter = [SChartTickLabelFormatter numberFormatter];
			self.yAxis.majorTickFrequency=nil;
			SChartColumnSeries* lineSeries = [[[SChartColumnSeries alloc] init] autorelease];
			lineSeries.title=[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			//lineSeries.style.lineWidth=@2;

			lineSeries.style.lineColor = color;
			
			return lineSeries;
		}else{
			self.yAxis.labelFormatter = [MotionEventTickFormatter instance];
			self.yAxis.majorTickFrequency=@1;
			SChartScatterSeries* series = [[[SChartScatterSeries alloc]init]autorelease];

			series.style.pointStyle.innerColor = series.style.pointStyle.color =color;
			
			series.title =[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			return series;
		}
	}else{
		if(_zoomLevel>=ChartZoomLevelBand){
			SChartBandSeries* bandSeries = [[[SChartBandSeries alloc]init]autorelease];
			SChartBandSeriesStyle *bss =bandSeries.style;
			bss.lineWidth=@2;
			bss.lineColorHigh = bss.lineColorLow =color;
			bss.areaColorNormal = bss.areaColorInverted = [color colorWithAlphaComponent:0.65];
			bandSeries.title=[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			return bandSeries;
		}else{
			SChartLineSeries* lineSeries = [[[SChartLineSeries alloc] init] autorelease];
			lineSeries.title=[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			SChartLineSeriesStyle * lss =lineSeries.style;
			lss.lineWidth=@2;
			lss.pointStyle.radius=@4;
			lss.pointStyle.innerRadius=@0.5;
			lss.pointStyle.showPoints=(_zoomLevel<ChartZoomLevelNormal);
			lss.lineColor = color;
			lss.pointStyle.color = lss.pointStyle.innerColor = color;
			return lineSeries;
		}
	}
}

- (NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)index {
	
	if(_zoomLevel==ChartZoomLevelRaw){
		return ((NSArray*)[id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]]).count;
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		return floor(((NSArray*)[id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]]).count/([_type isKindOfClass:[MotionTypeTranslator class]]?1.0:2.0));
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		return floor(((NSArray*)[id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]]).count/([_type isKindOfClass:[MotionTypeTranslator class]]?1.0:4.0));
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		return ((NSArray*)[id2Series objectForKey:[arrayOfIds objectAtIndex:index]]).count;
	}else{
		return ((NSArray*)[id2BandSeries objectForKey:[arrayOfIds objectAtIndex:index]]).count;
	}
}

- (id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)index {
	
	if(_zoomLevel==ChartZoomLevelRaw){
		return [id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]][dataIndex];
	}
	else if(_zoomLevel==ChartZoomLevelRaw2){
		return [id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]][dataIndex*([_type isKindOfClass:[MotionTypeTranslator class]]?1:2)];
	}
	else if(_zoomLevel==ChartZoomLevelRaw3){
		return [id2RawSeries objectForKey:[arrayOfIds objectAtIndex:index]][dataIndex*([_type isKindOfClass:[MotionTypeTranslator class]]?1:4)];
	}
	else if(_zoomLevel==ChartZoomLevelNormal){
		return [id2Series objectForKey:[arrayOfIds objectAtIndex:index]][dataIndex];
	}else{
		return [id2BandSeries objectForKey:[arrayOfIds objectAtIndex:index]][dataIndex];
	}
}

@end
