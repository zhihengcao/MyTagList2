//
//  MapRegionPicker.h
//  MyTagList2
//
//  Created by cao on 10/9/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DraggableCircleView.h"
#import "RegionAnnotation.h"
#import "RegionAnnotationView.h"


@interface NSMutableDictionary(Region)
@property (retain, nonatomic) CLRegion* circularRegion;
@end

typedef void (^doneBlockRegion_t)(NSMutableDictionary* regionEntry);

@interface MapRegionPicker : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>{
	
	CGPoint _newCenter, _newHandlePos;
	CATextLayer* _rangeDisplay;

	UIImage* _dropPin, *_currentPin;
	CLLocationManager* locationManager;
	doneBlockRegion_t _doneBlock;
}
@property (nonatomic, retain)NSMutableDictionary* regionEntry;
@property (nonatomic,retain) CLGeocoder* geocoder;
@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, retain) 	NSTimer* updateHandleTimer;
@property(retain, nonatomic) UIImageView* handleView;
@property (retain, nonatomic) IBOutlet UISearchBar *searchBar;
@property(retain, nonatomic)DashedLineView* dashedLineView;
@property(retain, nonatomic)DraggableCircleView* circleView;
@property(retain, nonatomic)RegionAnnotation* annotation;
@property(retain, nonatomic)RegionAnnotationView* annotationView;

-(id)initWithRegionEntry:(NSMutableDictionary *)regionEntry RecentList:(NSArray *)recents Done:(doneBlockRegion_t)doneBlock;
@property (assign, nonatomic) 	BOOL currentLocationSelected;
@property (retain, nonatomic) NSArray* geocoderList;
@property (retain, nonatomic) NSArray* recentList;

@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property(retain, nonatomic) CLRegion* region;
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@end

@interface MKMapItem(DetailText)
@property (readonly, nonatomic) NSString* detailText;
@end

@interface CLPlacemark(DetailText)
@property (readonly, nonatomic) NSString* detailText;
@end
