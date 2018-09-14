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
				   [UIColor colorWithRed:(float)0x7c/255.0 green:(float)0xb5/255.0 blue:(float)0xec/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x43/255.0 green:(float)0x43/255.0 blue:(float)0x48/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x90/255.0 green:(float)0xed/255.0 blue:(float)0x7d/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0xf7/255.0 green:(float)0xa3/255.0 blue:(float)0x5c/255.0 alpha:0.95],
				   
				   
				   [UIColor colorWithRed:(float)0x80/255.0 green:(float)0x85/255.0 blue:(float)0xe9/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0xf1/255.0 green:(float)0x5c/255.0 blue:(float)0x80/255.0 alpha:0.95],
				   
				   [UIColor colorWithRed:(float)0xe4/255.0 green:(float)0xd3/255.0 blue:(float)0x54/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x2b/255.0 green:(float)0x90/255.0 blue:(float)0x8f/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0xf4/255.0 green:(float)0x5b/255.0 blue:(float)0x5b/255.0 alpha:0.95],
				   [UIColor colorWithRed:(float)0x91/255.0 green:(float)0xe8/255.0 blue:(float)0xe1/255.0 alpha:0.95]
				   ];

		
		UIFont* labelFont = [self.titleLabel.font fontWithSize:10.0];
		self.xAxis =[[[TimeOfDayAxis alloc]initWithFont:labelFont]autorelease];
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
	[super dealloc];
}
/*-(void)zoomLevelChanged{
	if([_type isKindOfClass:[MotionTypeTranslator class]]){
 if(zoomLevel<ChartZoomLevelNormal){
 org_formatter=self.yAxis.labelFormatter.formatter;
 self.yAxis.labelFormatter.formatter=EventTypeFormatter.instance;
 }else{
 if(org_formatter)
 self.yAxis.labelFormatter.formatter=org_formatter;
 }
	}
	[super zoomLevelChanged];
 }*/
-(void)resetNormalData{
	[id2Series removeAllObjects];
	[id2BandSeries removeAllObjects];
}

// must be called from earliest date
-(float)processOneDay:(NSDictionary *)hourlyStatDay baseDate:(NSDate*)baseDate title:(NSMutableString*)title{
	float avg2=0;
	NSInteger tagCount = [[hourlyStatDay objectForKey:@"ids"] count];
	NSArray* values =[hourlyStatDay objectForKey:@"values"], *tods=[hourlyStatDay objectForKey:@"tods"], *ids=[hourlyStatDay objectForKey:@"ids"];
	for(int tagi=0;tagi<tagCount;tagi++){
		
		NSArray* tagv =[values objectAtIndex:tagi];
		NSNumber* tagId =[ids objectAtIndex:tagi ];
		
		if(![arrayOfIds containsObject:tagId])
			[arrayOfIds addObject:tagId];
		
		NSMutableArray* series=nil;
		NSMutableArray* rawSeries=nil;
		NSArray* tod=nil;
		if(tods){
			tod=[tods objectAtIndex:tagi];
			rawSeries=[id2RawSeries objectForKey:tagId];
			if(rawSeries==nil){
				rawSeries = [[NSMutableArray alloc]initWithCapacity:[tagv count]];
				[id2RawSeries setObject:rawSeries forKey:tagId];
			}
		}else{
			series =[id2Series objectForKey:tagId];
			if(series==nil){
				series = [[[NSMutableArray alloc]initWithCapacity:[tagv count]] autorelease];
				[id2Series setObject:series forKey:tagId];
			}
		}
		
		float ymin=[_type yminInit], ymax =[_type ymaxInit];
		float avg =0;
		
		for(int j=0;j<[tagv count];j++){
			NSNumber* val = [_type preProcess:[tagv objectAtIndex:j]];
			if(val){
				SChartDataPoint* dataPoint = [[SChartDataPoint new] autorelease];
				dataPoint.xValue = [NSDate dateWithTimeInterval:(tod? [tod[j] intValue]:3600*j) sinceDate:baseDate];
				dataPoint.yValue = val;
				
				
				if(tod){
					[rawSeries addObject:dataPoint];

					if([self.latestDate timeIntervalSinceDate:dataPoint.xValue]<0)
						self.latestDate = dataPoint.xValue;

					//NSLog(@"added %@", dataPoint.xValue);
				}else{
					ymax = fmax(ymax, [val floatValue]); ymin=fmin(ymin, [val floatValue]);
					[series addObject:dataPoint];
				}
				ymax2 = fmax([val floatValue], ymax2);
				ymin2 = fmin([val floatValue], ymin2);
				avg+=[val floatValue];
			}
		}
		
		if(tod==nil){
			NSMutableArray* bandSeries =[id2BandSeries objectForKey:tagId];
			if(bandSeries==nil){
				bandSeries = [[[NSMutableArray alloc]init] autorelease];
				[id2BandSeries setObject:bandSeries forKey:tagId];
			}
			
			int bandi= [self findBandArrayIndexFor:baseDate fromSeries:bandSeries];
			
			if([_type isKindOfClass:[MotionTypeTranslator class]]){
				SChartDataPoint* band = [[SChartDataPoint new] autorelease];
				band.xValue = [baseDate dateByAddingTimeInterval:3600*12];
				band.yValue = [NSNumber numberWithInteger:avg];
				[bandSeries insertObject:band atIndex:bandi];
			}else{
				SChartMultiYDataPoint* band = [[SChartMultiYDataPoint new] autorelease];
				band.xValue = [baseDate dateByAddingTimeInterval:3600*12];
				band.yValues = [NSMutableDictionary dictionaryWithDictionary:
								@{SChartBandKeyHigh: [NSNumber numberWithFloat:ymax], SChartBandKeyLow: [NSNumber numberWithFloat:ymin]}];
				[bandSeries insertObject:band atIndex:bandi];
			}
		}
		
		avg/=series.count;
		
		if(title){
			[title appendFormat:[_type labelFormat], avg];
			if(tagi<tagCount-1)
				[title appendString:@","];
		}
		avg2+=avg;
	}
	return avg2/tagCount;
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
			bandSeries.style.lineWidth=@2;
			bandSeries.style.lineColorHigh = bandSeries.style.lineColorLow =color;
			bandSeries.style.areaColorNormal = bandSeries.style.areaColorInverted = [color colorWithAlphaComponent:0.65];
			bandSeries.title=[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			return bandSeries;
		}else{
			SChartLineSeries* lineSeries = [[[SChartLineSeries alloc] init] autorelease];
			lineSeries.title=[self.id2nameMapping objectForKey:[arrayOfIds objectAtIndex:index]];
			lineSeries.style.lineWidth=@2;
			lineSeries.style.pointStyle.radius=@4;
			lineSeries.style.pointStyle.innerRadius=@0.5;
			lineSeries.style.pointStyle.showPoints=(_zoomLevel<ChartZoomLevelNormal);
			lineSeries.style.lineColor = color;
			lineSeries.style.pointStyle.color = lineSeries.style.pointStyle.innerColor = color;
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
