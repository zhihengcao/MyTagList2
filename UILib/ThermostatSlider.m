//
//  RangeSlider.m
//  RangeSlider
//
//  Created by Mal Curtis on 5/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ThermostatSlider.h"
#define barberPoleStripWidth 32

@interface ThermostatSlider (PrivateMethods)
-(float)xForValue:(float)value;
-(float)valueForX:(float)x;
@end

@implementation ThermostatSlider

@synthesize minimumValue, maximumValue, minimumRange, currentValue, setValueHigh=_setValueHigh, setValueLow=_setValueLow, deadZone, stepSize;
//@synthesize barberPoleView=_barberPoleView, replicatorLayer=_replicatorLayer;  // always in degC

-(void)setSetValueHigh:(float)rawValue
{
	_setValueHigh = round((rawValue-minimumValue)/stepSize)*stepSize+minimumValue;
	if(_setValueLow>_setValueHigh-minimumRange)_setValueHigh=_setValueLow+minimumRange;
	
}
-(void)setSetValueLow:(float)rawValue{
	
	_setValueLow = round((rawValue-minimumValue)/stepSize)*stepSize+minimumValue;
	if(_setValueLow>_setValueHigh-minimumRange)_setValueLow=_setValueHigh-minimumRange;
	
}

-(void)showLoading{
	_maxThumb.alpha=0.7;
	_minThumb.alpha=0.7;
}
-(void)revertLoading{
	_maxThumb.alpha=1;
	_minThumb.alpha=1;
}
-(void)customInit{
	_padding = 4;
	minimumRange = 2;
	_minThumbOn = false;
	_maxThumbOn = false;
	
	_trackBackground = [[ [UIImageView alloc] initWithImage:
						 [[UIImage imageNamed:@"bar-background.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:11]] autorelease];
	[self addSubview:_trackBackground];
	_trackBackground.autoresizingMask=UIViewAutoresizingFlexibleWidth;


	grayBar = [[[UIImage imageNamed:@"bar-highlight-bw.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:11] retain];
	blueBar = [[[UIImage imageNamed:@"bar-highlight.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:11] retain];
	orangeBar = [[[UIImage imageNamed:@"bar-highlight-orange.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:11] retain];
	blueBarMid = [[UIImage imageNamed:@"bar-highlight-mid.png"] retain];
	orangeBarMid = [[UIImage imageNamed:@"bar-highlight-orange-mid.png"] retain];
	_track = [[[UIImageView alloc] initWithImage:grayBar] autorelease];
	_track.contentMode = UIViewContentModeScaleToFill;
	[_track setClipsToBounds:YES];
	[self addSubview:_track];

	_activeTrack = [[[UIImageView alloc] initWithImage:blueBarMid] autorelease];
	
	_activeTrack.contentMode = UIViewContentModeScaleToFill;
	[_activeTrack setClipsToBounds:YES];
	[self addSubview:_activeTrack];

	_minThumb = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle_left.png"] /*highlightedImage:[UIImage imageNamed:@"handle-hover.png"]*/] autorelease];
	_minThumb.contentMode = UIViewContentModeCenter;
	[self addSubview:_minThumb];
	_minThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);

	_maxThumb = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle_right.png"] /*highlightedImage:[UIImage imageNamed:@"handle-hover.png"]*/] autorelease];
	_maxThumb.contentMode = UIViewContentModeCenter;
	[self addSubview:_maxThumb];
	_maxThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);

/*	self.barberPoleView = [[UIView alloc] init];
    self.barberPoleView.autoresizesSubviews = YES;
	float progressViewInnerHeight=9;
    UIColor* barColor = nil;	
	_barberPoleView.frame = CGRectMake(0, self.frame.size.height/2 - progressViewInnerHeight/2, self.frame.size.width, progressViewInnerHeight);
	barColor = [UIColor colorWithRed:30.0f/256.0f green:104.0f/256.0f blue:209.0f/256.0f alpha:1];
    
	CALayer* barberPoleLayer = [CALayer layer];
    barberPoleLayer.frame = self.barberPoleView.frame;
    CALayer* barberPoleMaskLayer = [CALayer layer];
    barberPoleMaskLayer.frame = self.barberPoleView.frame;
    barberPoleMaskLayer.cornerRadius = progressViewInnerHeight / 2;
    // mask doesnt work without a solid background
    barberPoleMaskLayer.backgroundColor = [UIColor whiteColor].CGColor;
    barberPoleLayer.mask = barberPoleMaskLayer;
	
    CALayer* barberStrip = [CALayer layer];
    barberStrip.frame = CGRectMake(0,0,barberPoleStripWidth * 2,self.frame.size.height);
	
    CGMutablePathRef stripPath = CGPathCreateMutable();
    CGPathMoveToPoint(stripPath, nil, 0, 0);
    CGPathAddLineToPoint(stripPath, nil, barberPoleStripWidth, 0);
    CGPathAddLineToPoint(stripPath, nil, barberPoleStripWidth * 2, barberStrip.frame.size.height);
    CGPathAddLineToPoint(stripPath, nil, barberPoleStripWidth, barberStrip.frame.size.height);
	
    CAShapeLayer* stripShape = [CAShapeLayer layer];
    stripShape.fillColor = barColor.CGColor;
    stripShape.path = stripPath;
	
    [barberStrip addSublayer:stripShape];
    CGPathRelease(stripPath);
	
    self.replicatorLayer= [CAReplicatorLayer layer];
    self.replicatorLayer.bounds = barberPoleLayer.bounds;
    self.replicatorLayer.position = CGPointMake(- barberStrip.frame.size.width * 4, barberPoleLayer.frame.size.height / 2);
    self.replicatorLayer.instanceCount = (NSInteger)roundf(self.frame.size.width / barberStrip.frame.size.width * 2) + 1;
    CATransform3D finalTransform = CATransform3DMakeTranslation(barberStrip.frame.size.width, 0, 0);
    [self.replicatorLayer setInstanceTransform:finalTransform];
    [self.replicatorLayer addSublayer:barberStrip];
    [barberPoleLayer addSublayer:self.replicatorLayer];
    [self.barberPoleView.layer addSublayer:barberPoleLayer];
    self.barberPoleView.alpha = 0.65f;
	
    [self addSubview:self.barberPoleView];
	
    if ( self.progress != 0 ) {
        [self stopBarberPole];
    }
    else {
        [self startBarberPole];
    }*/
	
	[self startAnimation];
}
-(void)awakeFromNib
{
	[self customInit];
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self customInit];
    }
    
    return self;
}
- (void)dealloc
{
	[blueBar release];
	[orangeBar release];
	[blueBarMid release];
	[orangeBarMid release];
	[grayBar release];
	[super dealloc];
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	
	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height-_trackBackground.bounds.size.height);
//	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
	_trackBackground.center = center;
	_track.center = center;

	//_minThumb.center = CGPointMake([self xForValue:_setValueLow], center.y);
    //_maxThumb.center = CGPointMake([self xForValue:_setValueHigh], center.y);
	
	_minThumb.center = CGPointMake([self xForValue:_setValueLow]-_minThumb.bounds.size.width/2.9, self.bounds.size.height-_minThumb.bounds.size.height/2.4);
	_maxThumb.center = CGPointMake([self xForValue:_setValueHigh]+_maxThumb.bounds.size.width/2.9, self.bounds.size.height-_maxThumb.bounds.size.height/2.4);

	
	float currentX =[self xForValue:self.currentValue];
	float setXL = [self xForValue:self.setValueLow];
	float setXH = [self xForValue:self.setValueHigh];

	_track.frame = CGRectMake(
                              _trackBackground.frame.origin.x,
                              _track.center.y - (_track.frame.size.height/2),
							  MIN(setXH, currentX) - _trackBackground.frame.origin.x,
                              _track.frame.size.height
                              );
	if(currentX<setXL){
		_activeTrack.frame=CGRectMake(
								  currentX,
								  _track.center.y - (_track.frame.size.height/2),
								  setXL-currentX,
								  _track.frame.size.height
								  );
	}else if(currentX > setXH){
		_activeTrack.frame=CGRectMake(
									  setXH,
									  _track.center.y - (_track.frame.size.height/2),
									  currentX-setXH,
									  _track.frame.size.height
									  );
	}
}
- (void)startAnimation{
	int direction=0;
	if(currentValue<_setValueLow)direction=1;
	else if(currentValue>_setValueHigh)direction=-1;
	
	_activeTrack.hidden=direction==0?YES:NO;
	_activeTrack.alpha=direction>0?0:1;
	[UIView animateWithDuration:1.0
                          delay:0
                        options: UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
						 if(direction>0){
							 _track.image = orangeBar;
							 _activeTrack.image = orangeBarMid;
						 }else if(direction<0){
							 _track.image = blueBar;
							 _activeTrack.image = blueBarMid;
						 }else
							 _track.image = grayBar;
						 
						 _activeTrack.alpha=0.4;
                     }
                     completion:^(BOOL finished){
                     }];
}
-(float)xForValue:(float)value{
	float x = (_trackBackground.bounds.size.width-(_padding*2))*((value - minimumValue) / (maximumValue - minimumValue))+_padding+_trackBackground.frame.origin.x;
	float maxX =_trackBackground.frame.origin.x+_trackBackground.bounds.size.width-_padding;
	if(x>maxX)return maxX;
	float minX = _trackBackground.frame.origin.x+_padding;
	if(x<minX)return minX;
	return x;
}

-(float) valueForX:(float)x{
    return minimumValue + (x-_padding-_trackBackground
						   .frame.origin.x) / (_trackBackground.bounds.size.width-(_padding*2)) * (maximumValue - minimumValue);
}
- (void)updateHandleImages
{
	_minThumb.highlighted = _minThumbOn;
	_maxThumb.highlighted=_maxThumbOn;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
  
	if(!_minThumbOn && !_maxThumbOn){
        return YES;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    if(_minThumbOn){
		
		double rawValue =[self valueForX:MAX([self xForValue:minimumValue], touchPoint.x - distanceFromCenter)];
		self.setValueLow=rawValue;
		_minThumb.center = CGPointMake([self xForValue:_setValueLow]-_minThumb.bounds.size.width/2.9, _minThumb.center.y);
		
    }
    if(_maxThumbOn){
		
		double rawValue =[self valueForX:MIN([self xForValue:maximumValue], touchPoint.x - distanceFromCenter)];
		self.setValueHigh = rawValue;
		_maxThumb.center = CGPointMake([self xForValue:_setValueHigh]+_maxThumb.bounds.size.width/2.9, _maxThumb.center.y);

    }
	//    [self updateTrackHighlight];
    //[self setNeedsLayout];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    CGPoint touchPoint = [touch locationInView:self];
    
    if(CGRectContainsPoint(_minThumb.frame, touchPoint)){
        _minThumbOn = true;
        distanceFromCenter = touchPoint.x - _minThumb.center.x-_minThumb.bounds.size.width/2.9;
    }
    else if(CGRectContainsPoint(_maxThumb.frame, touchPoint)){
        _maxThumbOn = true;
        distanceFromCenter = touchPoint.x - _maxThumb.center.x +_maxThumb.bounds.size.width/2.9;
        
    }
    [self updateHandleImages];
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    _minThumbOn = false;
    _maxThumbOn = false;
	[self updateHandleImages];
	[self sendActionsForControlEvents:UIControlEventEditingDidEnd];
	[self setNeedsLayout];
	[self startAnimation];
}

@end
