//
//  DetailViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "TableTBViewController.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKPSToggleSwitchSpecifierViewCell.h"
#import "IASKPSThermostatViewCell.h"
#import "GHCollapsingAndSpinningTableViewCell.h"
#import "IASKPSSliderSpecifierViewCell.h"
#import "DropcamViewController.h"
#import "AsyncURLConnection.h"
#import "UIAlertView+Blocks.h"
#import "OptionPicker.h"
#import "SnippetCategoryCollectionViewController.h"

#import "DBCameraView.h"
#import "DBCameraViewController.h"
#import "DBCameraContainerViewController.h"
#import "DBCameraSegueViewController.h"

@interface UIPopoverController(UniversalPresent)
-(void)presentPopoverFromAnything:(id)sender;
@end

@protocol DetailViewControllerDelegate <NSObject>
@required
@property (nonatomic, readonly)BOOL useDegF;
- (void)stopBeepBtnPressed:(id)sender;
- (void)beepBtnPressed:(id)sender;
- (void)armBtnPressed:(id)sender;
- (void)disarmBtnPressed:(id)sender;
-(void) updateBtnPressed:(id)sender;
-(void) optionsBtnPressed:(id)sender;

-(void) lbOptionsBtnPressed:(id)sender;

-(void) msOptionsBtnPressed:(id)sender;
-(void) tempOptionsBtnPressed:(id)sender;
-(void) oorOptionsBtnPressed:(id)sender;
-(void) specialOptionsBtnPressed: (id)sender;

-(void) capOptionsBtnPressed:(id)sender;
-(void) lightOptionsBtnPressed:(id)sender;

-(void) updateNowBtnPressed:(id)sender;

-(void) unassociateBtnPressed:(id)sender;
-(void) resetStatesBtnPressed:(id)sender;
-(void) resetEventBtnPressed:(id)sender;
-(void) doorStatsBtnPressed:(id)sender;
-(void) tempStatsBtnPressed:(id)sender withLux:(BOOL) withLux;
-(void)lightOnBtnPressed:(id)sender;
-(void)lightOffBtnPressed:(id)sender;
-(void) tagUpdated;
-(void)tagImageUpdated:(UIImage*)image;
-(void)tagImageDeleted;
-(void) calibrateRadioBtnPressed:(id)sender;
-(void) thermostatChoiceBtnPressed:(id)sender;

-(void) addScriptBtnPressed:(id)sender;

-(void) reconfigureScriptBtnPressed:(int)index;
-(void) deleteScriptBtnPressed:(int)index;
-(void) thermostatSet:(id)sender;
-(void) thermostatFanOnOff:(id)sender fanOn:(BOOL)on;
-(void) thermostatTurnOnOff:(id)sender turnOn:(BOOL)on;
-(void) thermostatDisableLocal:(id)sender disable:(BOOL)on;

-(void)enableKumoApp:(NSMutableDictionary*)script enable:(BOOL)on from:(id)sender;
-(void)enableDS18:(id)sender enable:(BOOL)on useSHT20:(BOOL)sht20;
-(void)dimLED:(id)sender dimTo:(float)dimTo speed:(NSInteger)speed;

-(void) showUpdateOptionPicker:(OptionPicker*)picker From:(id)sender;
-(void) showMultiStatsForIds:(NSArray*)ids Uuids:(NSArray*)uuids Type:(NSString*)type;

@end

// (image - reset event(moved)/name/comment/motion:/battery/updated/signal/temperature(non zero))
// (ping options/light on/light off/temp stats/door stats(ms))
// (reset states/unassociate)
@interface DetailViewController : TableTBViewController <UISplitViewControllerDelegate, DBCameraViewControllerDelegate, 
UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIPopoverControllerDelegate, IEditableTableViewCellDelegate>
{
	UIPopoverController *beepOptionPopover;
//    UIPopoverController *imagePickerPopover;
	UIImageView* imageView;
	UIView* headerView;
	NSMutableArray* cellArray;
	
	int* beep_option_choices_val;
	IASKPSTextFieldSpecifierViewCell* nameCell, *commentCell, *motionCell,
	*batteryCell, *updatedCell, *temperatureCell, *capCell, *beepOptionCell, *signalCell, *managerCell, *dimSpeedCell, *lightCell;
	IASKPSTextFieldSpecifierViewCell* camDetailCell;
	
	TableLoadingButtonCell* resetStatesCell, *specialOptionsCell, *unassociateCell, *doorStatsCell, *resetEventCell; //, *armBtnCell, *disarmBtnCell;
	TableLoadingButtonCell* lightOnCell, *lightOffCell, *tempStatsCell, *tempALSStatsCell, *calibrateRadioCell, *addScriptCell;

	IASKPSSliderSpecifierViewCell *dimCell;

	IASKPSToggleSwitchSpecifierViewCell* allowLocalCell; //, *ds18Cell;
	IASKPSTextFieldSpecifierViewCell* ds18Cell;
	
	GHCollapsingAndSpinningTableViewCell *moreCell1, *moreCell2;
	IASKPSTextFieldSpecifierViewCell* thermostatChoiceCell;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@property (nonatomic, retain) NSArray* beep_option_choices, *dim_speed_choices;

@property (nonatomic, readonly) NSString* doorCellName;
@property (nonatomic, retain) IASKPSThermostatViewCell* thermostatCell;
@property(nonatomic,assign) id<DetailViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableDictionary* tag;
@property (nonatomic, readonly) NSString* xSetMac;

//@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *pictureBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *stopBeepBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *beepBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *armBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *pingBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *optionsBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *pingNowBtn;

-(void)pictureBtnPressed:(id)sender;
-(void)doPickImage:(id)sender fromLibrary:(BOOL)fromLibrary;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<DetailViewControllerDelegate>) delegate;
-(void)updateTag:(NSMutableDictionary*)newTag loadThermostatSlider:(BOOL)loadThermSlider animated:(BOOL)animated;
-(void)updateScripts:(NSMutableArray*) scripts;
-(void)updateAgo;
-(void)updateImage:(UIImage*)image;
@end
