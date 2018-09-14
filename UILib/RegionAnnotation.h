

#import <MapKit/MapKit.h>

@interface RegionAnnotation : NSObject <MKAnnotation> {
}

@property (nonatomic, retain) CLLocation* centerLocation;
@property (nonatomic, retain) CLRegion *region;
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D handleCoordinate;
@property (nonatomic, readwrite) CLLocationDistance radius;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;

-(double) distanceFromCoordinate:(CLLocationCoordinate2D)coord;

@end
