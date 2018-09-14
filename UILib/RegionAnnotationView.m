
#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"
#import "DraggableCircleView.h"

@implementation RegionAnnotationView

@synthesize map, radiusOverlay=_radiusOverlay;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation {
	self = [super initWithAnnotation:annotation reuseIdentifier:[annotation title]];	
	
	if (self) {		
		self.canShowCallout	= YES;		
		self.multipleTouchEnabled = NO;
		self.draggable = YES;
		self.animatesDrop = YES;
		self.annotation = annotation;
		self.pinColor = MKPinAnnotationColorPurple;

		self.radiusOverlay = [MKMutableCircle mutableCircleWithCenterCoordinate:self.annotation.coordinate radius:((RegionAnnotation*)self.annotation).radius];
		//[map addOverlay:_radiusOverlay];
	}
	
	return self;	
}

- (void)removeRadiusOverlay {
	[map removeOverlay:_radiusOverlay];
}


- (void)updateRadiusOverlay {
	[self removeRadiusOverlay];
		
	self.canShowCallout = NO;
	self.radiusOverlay.coordinate = self.annotation.coordinate;
	self.radiusOverlay.radius = ((RegionAnnotation*)self.annotation).radius;
	[map addOverlay:self.radiusOverlay];
		
	self.canShowCallout = YES;
}

- (void)dealloc {
	self.radiusOverlay=nil;
	[super dealloc];
}


@end
