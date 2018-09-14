//
//  DraggableCircleView.m
//  Regions
//
//  Created by cao on 10/12/13.
//  Copyright (c) 2013 Apple Inc. All rights reserved.
//

#import "DraggableCircleView.h"

@implementation MKMutableCircle
@synthesize coordinate=_coordinate, radius=_radius;
+ (MKMutableCircle *)mutableCircleWithCenterCoordinate:(CLLocationCoordinate2D)coord
												radius:(CLLocationDistance)radius{
	MKMutableCircle* circle = [[[MKMutableCircle alloc] init] autorelease];
	circle.coordinate = coord;
	circle.radius = radius;
	return circle;
}

-(MKMapRect) boundingMapRect{
	MKMapPoint centerpoint = MKMapPointForCoordinate(_coordinate);
    double mapRadius = _radius * MKMapPointsPerMeterAtLatitude(_coordinate.latitude);
	return MKMapRectMake(centerpoint.x-mapRadius, centerpoint.y-mapRadius, mapRadius*2, mapRadius*2);
}

@end

@implementation DraggableCircleView
@synthesize circle=_circle;

-(id)initWithMutableCircle:(MKMutableCircle *)circle{
    
    self = [super initWithOverlay:circle];
    if(self){
		self.circle=circle;
    }
    return self;
}

- (BOOL)canDrawMapRect:(MKMapRect)mapRect
             zoomScale:(MKZoomScale)zoomScale{
	return YES;
}

-(void)dealloc{
	self.circle=nil;
	[super dealloc];
}
- (void)createPath{
		
	//CGPathRef path = CGPathCreateWithEllipseInRect([self rectForMapRect:_circle.boundingMapRect], nil);
	CGMutablePathRef path = CGPathCreateMutable();
    CLLocationCoordinate2D center = self.circle.coordinate;
    CGPoint centerPoint = [self pointForMapPoint:MKMapPointForCoordinate(center)];
    CGFloat radius = MKMapPointsPerMeterAtLatitude(center.latitude) * self.circle.radius;
    CGPathAddArc(path, NULL, centerPoint.x, centerPoint.y, radius, 0, 2 * M_PI, true);
    
    self.path = path;
    CGPathRelease(path);
}
@end

@implementation DashedLineView

-(id)initWithFrame:(CGRect)frame{
	self=[super initWithFrame:frame];
	if(self){
		_line = [[CAShapeLayer layer] retain];
		_line.strokeColor = [UIColor blackColor].CGColor;
		_line.lineWidth=2;
		_line.fillColor = nil;
		_line.lineDashPattern = @[@3, @2];
		[self.layer addSublayer:_line];
	}
	return self;
}
-(void) dealloc{
	[_line release];
	[super dealloc];
}

-(void)layoutSubviews{
	//CGMutablePathRef path = CGPathCreateMutable();
	//CGPathAddLineToPoint(path, nil, self.bounds.size.width,1);
	UIBezierPath* p = [UIBezierPath bezierPath];
	[p moveToPoint:CGPointMake(0, 0)];
	[p addLineToPoint:CGPointMake(self.bounds.size.width,0)];
	_line.path=p.CGPath;
	_line.frame = self.bounds;
}
@end
