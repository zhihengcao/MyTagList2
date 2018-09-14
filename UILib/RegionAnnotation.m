

#import "RegionAnnotation.h"
#import "MapRegionPicker.h"
@implementation RegionAnnotation

@synthesize region=_region, coordinate=_coordinate, radius, title, subtitle, centerLocation=_centerLocation;


-(void)setCoordinate:(CLLocationCoordinate2D)coordinate{
	
	[self willChangeValueForKey:@"coordinate"];
	
	_coordinate=coordinate;
	self.centerLocation = [[[CLLocation alloc] initWithLatitude:_coordinate.latitude longitude:_coordinate.longitude] autorelease];
		
	[self didChangeValueForKey:@"coordinate"];
}
-(void)setRegion:(CLRegion *)region{
	[_region autorelease];
	_region=[region retain];
	self.coordinate = region.center;
	self.radius = region.radius;
}
-(double) distanceFromCoordinate:(CLLocationCoordinate2D)coord{
	return [_centerLocation distanceFromLocation:[[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]autorelease]];
}
-(CLLocationCoordinate2D)handleCoordinate{
	MKCoordinateRegion r =MKCoordinateRegionMakeWithDistance(self.coordinate, 0, self.radius);
	return CLLocationCoordinate2DMake(self.coordinate.latitude,
									  r.span.longitudeDelta + self.coordinate.longitude);
}

-(id)init{
	self = [super init];
	return self;
}
- (void)dealloc {
	[_region release];
	[title release];
	[subtitle release];
	self.centerLocation = nil;
	[super dealloc];
}


@end
