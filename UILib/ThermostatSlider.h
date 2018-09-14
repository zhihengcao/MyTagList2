//
//  RangeSlider.h
//  RangeSlider
//
//  Created by Mal Curtis on 5/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ThermostatSlider : UIControl{
    float currentValue;
    float minimumRange;

    float minimumValue;
    float maximumValue;
    float _padding;
	float distanceFromCenter;

	BOOL _minThumbOn, _maxThumbOn;
    
    UIImageView * _minThumb;
    UIImageView * _maxThumb;
    UIImageView * _track, *_activeTrack;
    UIImageView * _trackBackground;
	UIImage* grayBar, *orangeBar, *blueBar, *orangeBarMid, *blueBarMid;
}

- (void)updateHandleImages;
-(void)showLoading;
-(void)revertLoading;

@property(nonatomic) float minimumValue;
@property(nonatomic) float maximumValue;
@property(nonatomic) float minimumRange;
@property(nonatomic) float setValueHigh;   // always in degC. degF mode only changes textLabel in tablecell
@property(nonatomic) float setValueLow;   // always in degC. degF mode only changes textLabel in tablecell
@property(nonatomic) float currentValue;
@property(nonatomic) float deadZone;
@property(nonatomic) float stepSize;
- (void)startAnimation;

//@property (nonatomic, strong) UIView* barberPoleView;
//@property (nonatomic, strong) CAReplicatorLayer* replicatorLayer;

@end
