//
//  DraggableCircleView.h
//  Regions
//
//  Created by cao on 10/12/13.
//  Copyright (c) 2013 Apple Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMutableCircle : NSObject<MKOverlay>{
	
}
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign, nonatomic)  CLLocationDistance  radius;
@property (nonatomic, readonly) MKMapRect boundingMapRect;

+ (MKMutableCircle *)mutableCircleWithCenterCoordinate:(CLLocationCoordinate2D)coord
                                  radius:(CLLocationDistance)radius;

@end

@interface DraggableCircleView : MKOverlayPathView{
}
@property (retain, nonatomic) MKMutableCircle* circle;
-(id)initWithMutableCircle:(MKMutableCircle *)circle;
@end

@interface DashedLineView : UIView{
	CAShapeLayer* _line;
}
-(id)initWithFrame:(CGRect)frame;
@end