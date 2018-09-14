
#import <MapKit/MapKit.h>
#import "DraggableCircleView.h"
@class RegionAnnotation;

@interface RegionAnnotationView : MKPinAnnotationView {	
}

@property (nonatomic, assign) MKMapView *map;
@property (nonatomic, retain) MKMutableCircle* radiusOverlay;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation;
- (void)updateRadiusOverlay;
- (void)removeRadiusOverlay;

@end