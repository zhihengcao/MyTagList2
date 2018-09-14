//
//  AppDelegate.h
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "LoginController.h"
#import "SpinnerView.h"
#import "AsyncURLConnection.h"
#import "OptionsViewController.h"
#import "NotificationJSQueue.h"
#import "AssociationBeginViewController.h"
#import "Reachability.h"
#import "RegisterViewController.h"
#import "TempOptionsViewController.h"
#import "CapOptionsViewController.h"
#import "LightOptionsViewController.h"
#import "AccountOptionsViewController.h"
#import "SSKeychain.h"
#import <Security/Security.h>
#import "SnippetListViewController.h"
#import "KumostatOptionsViewController.h"
#import "LandscapeGraphViewController.h"
#import "EventsViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "WebViewController.h"
//#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MasterViewControllerDelegate, LoginControllerDelegate, DetailViewControllerDelegate, OptionsViewControllerDelegate, TempOptionsViewControllerDelegate, CapOptionsViewControllerDelegate, LightOptionsViewControllerDelegate, AssociationDoneDelegate, RegisterViewControllerDelegate, ScriptConfigViewControllerDelegate, CLLocationManagerDelegate, UIDocumentInteractionControllerDelegate, NSXMLParserDelegate, UIPopoverControllerDelegate>
{
	int _postbackInterval;
	int _rxFilter;
	
	BOOL alreadyLaunched;
	
	NSDictionary* _launchOptions;
	BOOL logged_in;
	NotificationJSQueue* _notificationJS_queue;
	NSMutableArray* comets;
	//AsyncSoapURLConnection* comet;
	NSTimer* updateTimer;
	Reachability* hostReach;
	BOOL opv_apply_all;
	int slaveIdToDisplay;
	
	NSMutableDictionary* _dbidDictonary;
	NSMutableDictionary* tagDictionary;
	NSMutableDictionary* thermostatDictionary;
	NSMutableDictionary* _regionDictionary;

	GCDAsyncUdpSocket *_receiverUdp;
	NSMutableSet* knownWeMo;
	NSMutableString* _saxTempVal;

	TempOptionsViewController* _opv_temp;
	CapOptionsViewController* _opv_cap;
	LightOptionsViewController* _opv_light;
	MSOptionsViewController* _opv_ms;
	LbOptionsViewController* _opv_lb;
	KumostatOptionsViewController* _opv_kumostat;
	AccountOptionsViewController* _opv_ac;
	OorOptionsViewController* _opv_oor;
	PhoneOptionsViewController* _opv_phone;
	BOOL isOS8;
	UIVisualEffectView *bluredEffectView;

//	int num_pending_regions; int num_regions_updated;
}
//@property(nonatomic, copy) void (^fetchCompletionHandler)(UIBackgroundFetchResult);
@property(nonatomic, readonly)NSMutableDictionary* regionDictionary;

@property(nonatomic, retain)	NSMutableDictionary* pendingRegionList;
@property (nonatomic, retain)NSString* uuid_pending_focus;

@property (nonatomic, assign) BOOL useDegF;
@property (nonatomic, assign) BOOL isLimited;

@property (nonatomic, retain) NSString* wemoPhoneID;
@property (nonatomic, retain) NSString* wemoPhoneName;
@property (nonatomic, retain) NSString* wemoPhoneKey;
@property (nonatomic, retain) NSString* wemoHomeID;
@property (nonatomic, assign) BOOL showWeMoButton;
@property(nonatomic, assign) BOOL showDropcam;
@property (nonatomic, retain) NSMutableDictionary* wemoTriedForPhoneID;
@property(nonatomic, retain)NSString* push_token;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property(nonatomic, retain)CLGeocoder* geocoder;

-(void)reloadTagListWithCompletion:(void (^)())completion;
-(void)getNextUpdate;
- (void)stopBeepAllBtnPressed:(id)sender;
- (void)armAllBtnPressed:(id)sender;
-(void) logoutBtnPressed:(id)sender;
-(void) updateAllBtnPressed:(id)sender;
-(void) wirelessConfigBtnPressed:(id)sender;
-(void) associateTagBtnPressed:(id)sender;
-(void) tagSelected: (NSMutableDictionary*) tag fromCell:(UITableViewCell*) cell;
-(void) tagPictureRequest: (NSMutableDictionary*) tag fromCell:(UITableViewCell*) cell;

-(void) resetEventBtnPressed:(id)sender;
-(void)updateTag:(NSMutableDictionary*)tag;
-(void) updatePartialTagList:(NSMutableArray*)list;
-(void) open_opv_accountFromBarItem:(id)sender;
-(void) open_opv_phones:(NSDictionary*)tag BarItem:(id)sender;
-(void) open_opv_ms:(NSDictionary*)tag BarItem:(id)sender;
-(void) open_opv_oor:(NSDictionary*)tag BarItem:(id)sender;
-(void) open_opv_temp:(NSMutableDictionary*)tag BarItem:(id)sender;
-(void) open_opv_cap:(NSMutableDictionary*)tag BarItem:(id)sender;
-(void) unifiedUpdateBtnAction:(id)sender applyAll:(BOOL)applyAll;

-(void)armTempsensorForAllTags;
-(void)disarmTempsensorForAllTags;
-(void)armCapSensorForAllTags;
-(void)disarmCapSensorForAllTags;
-(void)disarmTempsensorForTag:(NSDictionary*)tag;
-(void)armTempsensorForTag:(NSDictionary*)tag;
-(void)disarmCapSensorForTag:(NSDictionary*)tag;
-(void)armCapSensorForTag:(NSDictionary*)tag;

-(void)thermostatSetTarget:(id)sender thermostatTag:(NSDictionary*)thermostatTag
				tempSensor:(NSMutableDictionary*)tempSensor relinquishOwnership:(BOOL)relinquishOwnership;


@property (retain, nonatomic)	NSArray* freqTols;
@property (retain, nonatomic)NSString* loginEmail;
@property (retain, nonatomic) NotificationJSQueue* notificationJS_queue;
@property (nonatomic, retain)	SpinnerView* spinner;
@property (retain, nonatomic) AsyncURLConnection* loginConn;
@property (strong, nonatomic) UIPopoverController* opv_popov;
@property (strong, nonatomic) UIPopoverController* updateOption_popov;
@property (strong, nonatomic) UIPopoverController* associate_popov;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MasterViewController *mvc;
@property (strong, nonatomic) DetailViewController *dvc;
@property(retain, nonatomic) EventsViewController* evc;
@property (strong, nonatomic) UISplitViewController *splitViewController;
-(void) updateTagList:(NSMutableArray*)list;

@end
//@interface AVCaptureDevice (iPhone7BugOverride)
//@property(nonatomic) AVCaptureColorSpace activeColorSpace NS_AVAILABLE_IOS(10_0);
//@end
@interface AVCaptureSession (iPhone7BugOverride)
-(BOOL) automaticallyConfiguresCaptureDeviceForWideColor;
@end

@interface UIFont (SystemFontOverride)
@end
@interface UINavigationController (DoublePushError)
- (void)pushViewController2:(UIViewController *)viewController;
@end
@interface NSNull (JSON)
@end

@interface NSBundle (Language)
+ (void)setLanguage:(NSString *)language;
@end

