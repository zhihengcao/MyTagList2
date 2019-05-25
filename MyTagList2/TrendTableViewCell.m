//
//  TrendTableViewCell.m
//  WirelessTag
//
//  Created by cao on 3/21/19.
//

#import "TrendTableViewCell.h"
#import "Tag.h"
#import "ImageStore.h"

@implementation TrendTableViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
	_chart.useLogScaleForLight = [[NSUserDefaults standardUserDefaults]boolForKey:LogScalePrefKey];	
}
-(void)setTrend:(NSDictionary*)t useDegF: (BOOL)useDegF andFiletimeSpan:(NSArray*)span{
	self.trend=t; self.span=span; self.useDegF=useDegF;
	//if(redrawn==0)return;
	
	self.name.text = [t.name uppercaseString];
	
	NSString* picture = [t objectForKey:@"picture"];
	NSRange dot = [picture rangeOfString:@"."];
	
	if([[picture substringFromIndex:dot.location] isEqualToString:@".jpg"]){
				
		_image.image =		[[ImageStore defaultImageStore] thumbnailForKey:[picture substringToIndex:dot.location] placeHolderNamed:nil loadFromFile:YES] ;

		if([[ImageStore defaultImageStore] base64MD5ForKey:t.uuid].length==0){
			[[ImageStore defaultImageStore] loadImageFromServerAsyncForKey:t.uuid placeHolderNamed:nil ToView:_image];
		}

	}else
		_image.image = [ImageStore placeholderImageNamed:picture];

	NSMutableArray* filetimes =[t objectForKey:@"filetime"];
	if(filetimes.firstObject==nil || filetimes.lastObject==nil)return;

	_timestamp.text = [self UserFriendlyTimeStringFor:[filetimes.lastObject longLongValue]];
	NSMutableArray* temperature = [t objectForKey:@"temperature"];
	if(useDegF){
		_temp_unit.text = @"°F";
		_temp.text = [NSString stringWithFormat:@"%.1f", [temperature.lastObject doubleValue]*9.0/5.0+32.0 ];
	}else{
		_temp_unit.text = @"°C";
		_temp.text = [NSString stringWithFormat:@"%.1f", [temperature.lastObject doubleValue] ];
	}
	NSMutableArray* rh = [t objectForKey:@"rh"];
	if(rh==nil || rh==[NSNull null]){
		_cap.text = @"-";
		rh=nil;
	}else{
		_cap.text = [NSString stringWithFormat:@"%.1f", [rh.lastObject floatValue] ];
	}
	NSMutableArray* lux = [t objectForKey:@"lux"];
	if(lux==[NSNull null] || lux==nil){
		_lux_unit.text=@"";
		_lux.text=@"";
		_chart.hasALS=NO;
		lux=nil;
	}else{
		float luxValue = [[lux lastObject] floatValue];
		_lux.text=[NSString stringWithFormat:luxValue>100?@"%.0f":@"%.1f", luxValue];
		_lux_unit.text = @"lx";
		_chart.hasALS=YES;
	}
	
	
	NSArray* tempRange = nil;
	if(t.tempState>TempDisarmed){
		id th_low = [t objectForKey:@"temp_th_low"];
		id th_high =[t objectForKey:@"temp_th_high"];
		if(th_low!=nil && th_high!=nil)
			tempRange = @[th_low, th_high];
	}
	NSArray* capRange = nil;
	if(t.rhState > CapDisarmed){
		id th_low = [t objectForKey:@"rh_th_low"];
		id th_high =[t objectForKey:@"rh_th_high"];
		if(th_low!=nil && th_high!=nil)
			capRange =  @[th_low, th_high];
	}
	NSArray* luxRange=nil;
	if(t.lightState>LightDisarmed){
		id th_low = [t objectForKey:@"lux_th_low"];
		id th_high =[t objectForKey:@"lux_th_high"];
		if(th_low!=nil && th_high!=nil)
			luxRange =  @[th_low, th_high];
		//luxRange = @[[t objectForKey:@"lux_th_low"], [t objectForKey:@"lux_th_high"]];
	}

/*	if(span){
		_chart.earliestDate=nsdateFromFileTime([span.firstObject longLongValue]);
		_chart.latestDate=nsdateFromFileTime([span.lastObject longLongValue]);
	}else{
		_chart.earliestDate=nsdateFromFileTime([filetimes.firstObject longLongValue]);
		_chart.latestDate=nsdateFromFileTime([filetimes.lastObject longLongValue]);
	}
	[_chart.xAxis setRangeWithMinimum:_chart.earliestDate andMaximum:_chart.latestDate];
*/
	[_chart showRecentTrendFileTimes:filetimes Temperatures:temperature Caps:rh Lux:lux tempRange:tempRange capRange:capRange
							luxRange:luxRange dateRange: span? span: @[filetimes.firstObject, filetimes.lastObject] eventsToAnnotate:[t objectForKey:@"events"]];
}
-(NSString*)UserFriendlyTimeStringFor:(long long)filetime{
	if(filetime==0)return @"(NO DATA)";
	NSDate* lastComm = [NSDate dateWithTimeIntervalSince1970:((	filetime / 10000000) - 11644473600 - serverTime2LocalTime)];
	NSDate* now = [[[NSDate alloc] init] autorelease];
	NSTimeInterval diff = [now timeIntervalSinceDate:lastComm];
	float daysDifference = (float)diff / 60.0 / 60.0 / 24.0;
	if(daysDifference>=3)return  [NSDateFormatter localizedStringFromDate:lastComm dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
	else if(daysDifference<0.5)return [NSDateFormatter localizedStringFromDate:lastComm dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
	else return [NSDateFormatter localizedStringFromDate:lastComm dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
}
- (void)layoutSubviews
{
	[super layoutSubviews];
	if(self.frame.size.width<190)_chart.hidden=YES;
	else {
		_chart.hidden=NO;
		_chart.frame=CGRectMake( 180, 12, self.frame.size.width-185, self.frame.size.height-15);

		//NSLog(@"TrendTableCell layoutSubViews redrawn=%d", redrawn);
		//[self setTrend:self.trend useDegF:self.useDegF andFiletimeSpan:self.span];

		if(redrawn<2){
			NSLog(@"TrendTableCell layoutSubViews redrawn=%d", redrawn);
			/*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
				if(redrawn==1)
					[self setTrend:self.trend useDegF:self.useDegF andFiletimeSpan:self.span];
			}else{
				if(redrawn==1)
					[self setTrend:self.trend useDegF:self.useDegF andFiletimeSpan:self.span];
			}*/
			[self setTrend:self.trend useDegF:self.useDegF andFiletimeSpan:self.span];
			redrawn++;
		}
		/*[NSTimer timerWithTimeInterval:0.5 block:^{
			dispatch_async(dispatch_get_main_queue(), ^{
			});
		} repeats:NO];*/
	}
}

- (void)dealloc {
	self.trend=nil; self.span=nil;
	self.chart=nil;
	self.name=nil;
	self.timestamp=nil;
	self.temp=nil;
	self.cap=nil;
	self.lux=nil;
	self.image=nil;
	self.temp_unit=nil;
	self.lux_unit=nil;
    [super dealloc];
}
@end
