//
//  MapRegionPicker.m
//  MyTagList2
//
//  Created by cao on 10/9/13.
//
//

#import "MapRegionPicker.h"
#import "RegionAnnotationView.h"
#import "NSTimer+Blocks.h"

@implementation MKMapItem(DetailText)
-(NSString*)detailText{
	if(self.placemark.administrativeArea!=nil)
		return [NSString stringWithFormat:@"%@, %@ %@ %@",self.placemark.thoroughfare, self.placemark.locality, self.placemark.administrativeArea, self.placemark.postalCode,nil ];
	else
		return @"";
}


@end

@implementation CLPlacemark(DetailText)

-(NSString*)detailText{
	if(self.administrativeArea!=nil)
		return [NSString stringWithFormat:@"%@, %@ %@ %@",self.thoroughfare, self.locality, self.administrativeArea,self.postalCode, nil ];
	else
		return @"";
}

@end

@implementation MapRegionPicker
@synthesize region=_region, annotation=_annotation,recentList=_recentList, geocoderList=_geocoderList, currentLocationSelected=_currentLocationSelected;
@synthesize circleView=_circleView, handleView=_handleView, dashedLineView=_dashedLineView, annotationView=_annotationView;
@synthesize updateHandleTimer = _updateHandleTimer;
@synthesize geocoder=_geocoder;
@synthesize regionEntry=_regionEntry;

-(CLGeocoder*)geocoder{
	if(_geocoder==nil){
		_geocoder = [[CLGeocoder alloc]init];
	}
	return _geocoder;
}

-(id)initWithRegionEntry:(NSMutableDictionary *)regionEntry RecentList:(NSArray *)recents Done:(doneBlockRegion_t)doneBlock
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		self = [super initWithNibName:@"MapRegionPicker" bundle:nil];
	else
		self = [super initWithNibName:@"MapRegionPicker_iPad" bundle:nil];
		
    if (self) {
		_doneBlock = [doneBlock copy];

		_dropPin = [[UIImage imageNamed:@"droppin.png"] retain];
		_currentPin =[[UIImage imageNamed:@"currentLocation.png"] retain];
		self.recentList = recents;
		if(regionEntry==nil){
			self.currentLocationSelected=YES;
		}else{
			self.regionEntry = regionEntry;
		}
	}
	return self;
}
- (void)dragResize:(UIPanGestureRecognizer *)recognizer {
	
    CGPoint translation = [recognizer translationInView:self.view];
	if(recognizer.state==UIGestureRecognizerStateBegan){
		_rangeDisplay.hidden=NO;
	}else if(recognizer.state==UIGestureRecognizerStateEnded){
		_rangeDisplay.hidden=YES;
		
		CGSize mapSize =self.mapView.bounds.size;
		float inset = mapSize.height >mapSize.width? mapSize.width*0.25 : mapSize.height*0.25;
		[self.mapView setVisibleMapRect:_circleView.circle.boundingMapRect edgePadding:UIEdgeInsetsMake(inset,inset,inset,inset) animated:NO];
		
		NSString* identifier;
		if(_region==nil){
			identifier = [[NSUUID UUID] UUIDString];
		}else{
			identifier = _region.identifier;
		}

		CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:_annotation.coordinate radius:_annotation.radius
																  identifier:identifier];
		[_region autorelease];
		_region = newRegion;
	}
    CGPoint tapPos = CGPointMake(recognizer.view.center.x + translation.x,
								 recognizer.view.center.y + translation.y);
	double radius =[_annotation distanceFromCoordinate:
					[self.mapView convertPoint:tapPos toCoordinateFromView:self.view]];
	_circleView.circle.radius = _annotation.radius =radius;
	
	recognizer.view.center = _newHandlePos = [self.mapView convertCoordinate:_annotation.handleCoordinate toPointToView:self.view];
	//recognizer.view.center = handlePoint;
	_dashedLineView.frame=CGRectMake(_newCenter.x, _newCenter.y, _newHandlePos.x-_newCenter.x, 3);
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	_rangeDisplay.frame=CGRectMake((_newCenter.x+_newHandlePos.x)/2-40, _newCenter.y-18, 80, 14);
	[CATransaction commit];
	
	if(radius>16093.4)
		_rangeDisplay.string=[NSString stringWithFormat:@"%.0f miles", _annotation.radius/1609.34];
	else if(radius>800)
		_rangeDisplay.string=[NSString stringWithFormat:@"%.1f miles", _annotation.radius/1609.34];
	else
		_rangeDisplay.string=[NSString stringWithFormat:@"%.0f ft", _annotation.radius/0.3048];
	
	
	[_circleView invalidatePath];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
	_handleView.hidden=YES;
	_dashedLineView.hidden=YES;
}
-(void)updateDragHandle{

	_handleView.hidden=YES;
	_dashedLineView.hidden=YES;
	
	if(_annotation==nil)return;
	
	_newCenter = [self.mapView convertCoordinate:_annotation.coordinate toPointToView:self.view];
	
	if(isnan(_newCenter.x) || isnan(_newCenter.y)){
		NSLog(@"_annotation.coordinate has NaN (coordinate lat=%f).", _annotation.coordinate.latitude);
		return;
	}

	_newHandlePos = [self.mapView convertCoordinate:_annotation.handleCoordinate toPointToView:self.view];

	if(isnan(_newHandlePos.x) || isnan(_newHandlePos.y)){
		NSLog(@"_annotation.handleCoordinate has NaN.");
		return;
	}

	if(_newHandlePos.x - _newCenter.x < 10){
		
		return;
	}
	
	_dashedLineView.frame=CGRectMake(_newCenter.x, _newCenter.y,  _newHandlePos.x-_newCenter.x, 2);
	_dashedLineView.transform = CGAffineTransformMakeScale(0,0);
	_handleView.center = _newCenter;
	_handleView.hidden=NO;
	_dashedLineView.hidden=NO;
	
	[UIView animateWithDuration:0.4 animations:^{
		_handleView.center=_newHandlePos;
		_dashedLineView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished){
		[UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 _handleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);}
						 completion:^(BOOL finished){if (finished){
			
			[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut
							 animations:^{
								 _handleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);}
							 completion:NULL];}}];
	}];

}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	if(self.updateHandleTimer==nil)
		[self updateDragHandle];
}
-(void)setRegion:(CLRegion *)region{
	if(_annotation!=nil){
		[_mapView removeAnnotation:_annotation];
	}else{
		self.annotation= [[[RegionAnnotation alloc] init] autorelease];
	}
		
	[_region autorelease];
	_region = [region retain];
	_annotation.region = region;

	if (!_annotationView){
		self.annotationView = [[[RegionAnnotationView alloc] initWithAnnotation:self.annotation] autorelease];
		_annotationView.map = _mapView;
	}else{
		_annotationView.annotation = self.annotation;
	}

	[_mapView addAnnotation:self.annotation];

	[self.annotationView updateRadiusOverlay];

	self.updateHandleTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 block:^()
	  {
		  self.updateHandleTimer=nil;
		  [self updateDragHandle];
	  } repeats:NO];
	
	CGSize mapSize =self.mapView.bounds.size;
	float inset = mapSize.height >mapSize.width? mapSize.width*0.25 : mapSize.height*0.25;
	[self.mapView setVisibleMapRect:self.annotationView.radiusOverlay.boundingMapRect edgePadding:UIEdgeInsetsMake(inset,inset,inset,inset) animated:NO];

}

- (void)doneBtnPressed:(id)sender{
	self.regionEntry.circularRegion = _region;
	[self.regionEntry setObject:_annotation.title forKey:@"title"];
	[self.regionEntry setObject:_annotation.subtitle forKey:@"detail"];
	_doneBlock(_regionEntry);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	if(self.updateHandleTimer==nil)
		[self updateDragHandle];	
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
		return NO;
	else
		return YES;
}
-(BOOL)shouldAutorotate
{
    return NO;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait; // etc
}

- (void)viewDidLoad {
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.title=@"Pick a Region";
	self.navigationItem.rightBarButtonItem  =
	[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBtnPressed:)] autorelease];

	if([self.mapView respondsToSelector:@selector(setRotateEnabled:)])
		self.mapView.rotateEnabled=NO;
	
	self.circleView = [[[DraggableCircleView alloc] init] autorelease];
	_circleView.strokeColor = [UIColor purpleColor];
	_circleView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.2];
	
	
	self.handleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handleMap.png"]] autorelease];
	[_handleView sizeToFit];
	_handleView.layer.zPosition = 999;
	_handleView.userInteractionEnabled = YES;
	_handleView.contentMode = UIViewContentModeCenter;
	_handleView.center = [self.mapView convertCoordinate:_annotation.handleCoordinate toPointToView:self.view];
	
	self.dashedLineView = [[[DashedLineView alloc]initWithFrame:CGRectMake(0,0,0,0)] autorelease];
	_dashedLineView.layer.anchorPoint=CGPointMake(0,0);
	[self.view addSubview:_dashedLineView];
	
	UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragResize:)];
	[panRecognizer setMinimumNumberOfTouches:1];
	[panRecognizer setMaximumNumberOfTouches:1];
	[_handleView addGestureRecognizer:panRecognizer];
	[panRecognizer release];
	[self.view addSubview:_handleView];
	
	_rangeDisplay = [[CATextLayer alloc] init];
	[_rangeDisplay setFont:@"Helvetica"];
	[_rangeDisplay setFontSize:12];
	//_rangeDisplay.cornerRadius=5;
	_rangeDisplay.contentsScale = [[UIScreen mainScreen] scale];
	_rangeDisplay.alignmentMode = kCAAlignmentCenter;
	_rangeDisplay.foregroundColor =[[UIColor purpleColor] CGColor];
	//_rangeDisplay.backgroundColor =[[UIColor grayColor] CGColor];
	//_rangeDisplay.shadowRadius=5;
	//_rangeDisplay.shadowOpacity=0.5;
	//_rangeDisplay.shadowColor=[[UIColor blackColor] CGColor];
	//_rangeDisplay.shadowOffset=CGSizeMake(3, -4);
	_rangeDisplay.hidden=YES;
	[self.view.layer addSublayer:_rangeDisplay];
	
	if(_regionEntry!=nil){
		self.region = _regionEntry.circularRegion;
		_annotation.title = [_regionEntry objectForKey:@"title"];
		_annotation.subtitle = [_regionEntry objectForKey:@"detail"];
	}
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// release views created at viewDidLoad.
-(void)releaseViews{
	self.dashedLineView=nil;
	self.handleView=nil;
	self.circleView=nil;
	self.annotation=nil;
	self.annotationView=nil;
	[_rangeDisplay release]; _rangeDisplay=nil;
    [self setMapView:nil];
	[self setTableView:nil];
}
- (void)dealloc {
	self.regionEntry=nil;
	self.updateHandleTimer = nil;
	[_doneBlock release];
	[self  releaseViews];

	[locationManager release];
	self.region=nil;
	[_dropPin release];
	[_currentPin release];
	[_searchBar release];
	self.geocoder=nil;
    [super dealloc];
}

- (void)viewDidUnload {
	[self  releaseViews];
    [super viewDidUnload];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if([annotation isKindOfClass:[RegionAnnotation class]]) {
		return _annotationView;
	}
	
	return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if([overlay isKindOfClass:[MKMutableCircle class]]) {
		_circleView.circle = overlay;
		
		[_circleView invalidatePath];
		return _circleView;
	}
	return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	if([annotationView isKindOfClass:[RegionAnnotationView class]]) {
				
		if (newState == MKAnnotationViewDragStateStarting) {
			[_annotationView removeRadiusOverlay];
			_handleView.hidden=YES;
			_dashedLineView.hidden=YES;
			
			//[locationManager stopMonitoringForRegion:regionAnnotation.region];
		}
		
		if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling) {
			
			[self.geocoder reverseGeocodeLocation:_annotation.centerLocation
						   completionHandler:^(NSArray* placemarks, NSError* error){
							   if (placemarks && placemarks.count > 0) {
								   CLPlacemark *topResult = [placemarks objectAtIndex:0];
								   _annotation.title = topResult.name;
								   _annotation.subtitle = topResult.detailText;
							   }
						   }
			 ];

			NSString* identifier;
			if(_region==nil){
				identifier = [[NSUUID UUID] UUIDString];
			}else{
				identifier = _region.identifier;
			}

			CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:_annotation.coordinate radius:_annotation.radius
																	  identifier:identifier];
			[_region autorelease];
			_region = newRegion;

			[self.annotationView updateRadiusOverlay];
			//[self.mapView setVisibleMapRect:self.annotationView.radiusOverlay.boundingMapRect edgePadding:UIEdgeInsetsMake(60,60,60,60) animated:NO];

			//[locationManager startMonitoringForRegion:regionAnnotation.region desiredAccuracy:kCLLocationAccuracyBest];
		}
	}	
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
	if (_geocoderList!=nil)
	{
        return [_geocoderList count]+1;
    }
	else
		return [_recentList count]+1;
}
-(void)setCurrentLocationSelected:(BOOL)currentLocationSelected{
	_currentLocationSelected=currentLocationSelected;
	if(currentLocationSelected){
		if(!locationManager){
			locationManager = [[CLLocationManager alloc] init];
			locationManager.delegate = self;
			locationManager.distanceFilter = 10;
			locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
			   [locationManager requestAlwaysAuthorization];
		}
		[locationManager startUpdatingLocation];
	}else{
		[locationManager stopUpdatingLocation];
	}
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
	if(indexPath.row==0){
		self.currentLocationSelected=YES;
	}else{
		if (self.geocoderList)
		{
			self.currentLocationSelected=NO;
			MKMapItem* pm =[_geocoderList objectAtIndex:indexPath.row-1];
			
			NSString* identifier;
			if(_region==nil){
				identifier = [[NSUUID UUID] UUIDString];
			}else{
				identifier = _region.identifier;
			}

			self.region = [[CLRegion alloc] initCircularRegionWithCenter:pm.placemark.location.coordinate radius:1500 identifier:identifier];
			_annotation.title = pm.placemark.name;
			_annotation.subtitle = pm.placemark.detailText;
			
		}else{

			// recall recent list
			
			self.currentLocationSelected=NO;

			NSMutableDictionary* r = [_recentList objectAtIndex:indexPath.row-1];
			
			self.region = r.circularRegion;
			/* =[[CLRegion alloc] initCircularRegionWithCenter:
						   CLLocationCoordinate2DMake([[r objectForKey:@"lat"]doubleValue], [[r objectForKey:@"lon"]doubleValue])														  																  radius:1500 identifier:_region.identifier]; */
			_annotation.title = [r objectForKey:@"title"];
			_annotation.subtitle = [r objectForKey:@"detail"];
			
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if(_currentLocationSelected){

		NSString* identifier;
		if(_region==nil){
			identifier = [[NSUUID UUID] UUIDString];
		}else{
			identifier = _region.identifier;
		}
		self.region = [[CLRegion alloc] initCircularRegionWithCenter:newLocation.coordinate radius:1500 identifier:identifier];

		[self.geocoder reverseGeocodeLocation:_annotation.centerLocation
							completionHandler:^(NSArray* placemarks, NSError* error){
								if (placemarks && placemarks.count > 0) {
									CLPlacemark *topResult = [placemarks objectAtIndex:0];
									_annotation.title = topResult.name;
									_annotation.subtitle = topResult.detailText;
								}
							}
		 ];
		
		[locationManager stopUpdatingLocation];

	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView  dequeueReusableCellWithIdentifier:@"Location"];
    if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Location"] autorelease];
    }

	if(indexPath.row==0){
		cell.imageView.image = _currentPin;
		cell.textLabel.text = @"Current Location";
	}else{
		if (self.geocoderList)
		{
			cell.imageView.image = _dropPin;
			MKMapItem* pm =[_geocoderList objectAtIndex:indexPath.row-1];
			cell.textLabel.text = pm.name;
			cell.detailTextLabel.text = pm.detailText;
		}else{
			cell.imageView.image = _dropPin;
			NSDictionary* r = [_recentList objectAtIndex:indexPath.row-1];
			cell.textLabel.text = [r objectForKey:@"title"];
			cell.detailTextLabel.text = [r objectForKey:@"detail"];
		}
	}
    return cell;
}

/*-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    CGRect rect = searchBar.frame;
    rect.origin.y = MIN(0, scrollView.contentOffset.y);
    searchBar.frame = rect;
}*/

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText   // called when text changes (including clear)
{
	if(searchText==nil || searchText.length==0){
		self.geocoderList=nil;
		[self.tableView reloadData];
	}else if(searchText.length>2){
		[self startSearch:searchText showError:NO];
	}
}

- (void)startSearch:(NSString *)searchString showError:(BOOL)showError
{
    if (self.localSearch.searching)
    {
        [self.localSearch cancel];
    }
    
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = _region.center.latitude;
    newRegion.center.longitude = _region.center.longitude;
    
    // setup the area spanned by the map region:
    // we use the delta values to indicate the desired zoom level of the map,
    //      (smaller delta values corresponding to a higher zoom level)
    //
    newRegion.span.latitudeDelta = 3;
    newRegion.span.longitudeDelta = 3;
    
    MKLocalSearchRequest *request = [[[MKLocalSearchRequest alloc] init] autorelease];
    
    request.naturalLanguageQuery = searchString;
    request.region = newRegion;
    
    MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error)
    {
        if ((error != nil || response==nil)&& showError)
        {
            NSString *errorStr = [[error userInfo] valueForKey:NSLocalizedDescriptionKey];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not find places"
                                                            message:errorStr
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else if(response!=nil)
        {
            self.geocoderList = [response mapItems];
            [self.tableView reloadData];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    };
    
    if (self.localSearch != nil)
    {
        self.localSearch = nil;
    }
    _localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    
    [_localSearch startWithCompletionHandler:completionHandler];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    // check to see if Location Services is enabled, there are two state possibilities:
    // 1) disabled for entire device, 2) disabled just for this app
    //
    NSString *causeStr = nil;
    
    // check whether location services are enabled on the device
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        causeStr = @"device";
    }
    // check the application’s explicit authorization status:
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        causeStr = @"app";
    }
    else
    {
        // we are good to go, start the search
        [self startSearch:searchBar.text showError:YES];
    }
	
    if (causeStr != nil)
    {
        NSString *alertMessage = [NSString stringWithFormat:@"You currently have location services disabled for this %@. Please refer to \"Settings\" app to turn on Location Services.", causeStr];
		
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
																		message:alertMessage
																	   delegate:nil
															  cancelButtonTitle:@"OK"
															  otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
}

@end

@implementation NSMutableDictionary(Region)

-(CLRegion*)circularRegion{
	if([self objectForKey:@"id"]==[NSNull null]){
		return nil;
	}
	return [[[CLRegion alloc] initCircularRegionWithCenter:
			 CLLocationCoordinate2DMake([[self objectForKey:@"centerLat"] doubleValue], [[self objectForKey:@"centerLong"]doubleValue])
													radius:[[self objectForKey:@"radiusMeter"] doubleValue] identifier:[self objectForKey:@"id"]] autorelease];
}

-(void)setCircularRegion:(CLRegion *)circularRegion{
	[self setObject:[NSNumber numberWithDouble:circularRegion.center.latitude] forKey:@"centerLat"];
	[self setObject:[NSNumber numberWithDouble:circularRegion.center.longitude] forKey:@"centerLong"];
	[self setObject:[NSNumber numberWithDouble:circularRegion.radius] forKey:@"radiusMeter"];
	if(circularRegion.identifier)
		[self setObject:circularRegion.identifier forKey:@"id"];
	else
		[self setObject:circularRegion.identifier forKey:@"id"];
		
}

@end

