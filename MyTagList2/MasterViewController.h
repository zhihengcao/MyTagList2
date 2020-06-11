//
//  MasterViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TableTBViewController.h"
#import "WebImageOperations.h"

@class TopPagingViewController;
@class MasterViewController;

@protocol MasterViewControllerDelegate <NSObject>
@required
@property (nonatomic, readonly)BOOL useDegF;
//- (void)stopBeepAllBtnPressed:(id)sender;
- (void)helpBtnPressed:(id)sender;
- (void)armAllBtnPressed:(id)sender;
-(void) logoutBtnPressed:(id)sender;
-(void) tagManagerDropdownPressed:(id)sender;
-(void) updateAllBtnPressed:(id)sender;
-(void) multiStatsBtnPressed:(id)sender;
-(void) wirelessConfigBtnPressed:(id)sender;
-(void) associateTagBtnPressed:(id)sender;
-(void) tagSelected: (NSString*) uuid fromCell:(UITableViewCell*) cell;
-(void) tagPictureRequest:(NSString *)uuid fromCell:(UITableViewCell *)cell;

//-(void) swapOrderOf: (NSDictionary*)tag1 and:(NSDictionary*)tag2;
-(void)swapOrderOf:(NSString *)tag1 between:(NSString *)tag_prev and:(NSString*)tag_next;

@end
@interface UILabel(EllipsisFix)
-(void)setTextColorFixed:(NSString *)text;
@end

typedef NS_ENUM(NSInteger, TagCellDisplayMode) {
	DisplayModeTemperature=0,
	DisplayModeHumidity=1,
	DisplayModeUpdatedAgo=2,
	DisplayModeLux=3
};

@interface MasterViewController : TableTBViewController <UISearchResultsUpdating, UISearchBarDelegate, UIGestureRecognizerDelegate>{

	NSMutableArray* _tagList;
	NSMutableArray	*_filteredTagList;	// The content filtered as a result of a search.
	
	// The saved state of the search UI if a memory warning removed the view.
    /*NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
	CGPoint			contentOffsetBeforeSearch;  */
	
	UIBarButtonItem *searchBtn, *reorderDoneBtn;
}

@property(nonatomic) TagCellDisplayMode currentDisplayMode;
@property(nonatomic) BOOL anyLightSensor;
@property (nonatomic, assign)TopPagingViewController* topPVC;

-(NSDictionary*) findTagByUuid:(NSString*) uuid;
-(BOOL)anyV1Tags;
-(BOOL)anyV2Tags;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate: (id<MasterViewControllerDelegate>) delegate;

@property(nonatomic,assign) id<MasterViewControllerDelegate> delegate;


@property (nonatomic, retain) NSMutableArray *tagList;
//@property (retain, nonatomic) IBOutlet UIBarButtonItem *stopBeepAllBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *armAllBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *helpBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *updateAllBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *multiStatsBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *wirelessConfigBtn;
//@property (retain, nonatomic) IBOutlet UIBarButtonItem *associateTagBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *reorderDoneReplacingBtn;
@property(retain, nonatomic) UITableViewCell* associateBtnCell;

-(void) updateTag:(NSMutableDictionary*)tag loadImage:(BOOL)loadimage;
-(void) deleteTagWithUuid:(NSString*)uuid;
-(void) deleteTagWithSlaveId:(int)slaveId;
-(void) addNewTag:(NSMutableDictionary*)tag;
-(void) startReordering;

-(UITableViewCell*)cellForTag:(NSMutableDictionary*)tag;

@end

#import <QuartzCore/CAGradientLayer.h>

@interface TagTableViewCell : UITableViewCell 
{
	NSArray* signalBarsImages;
//	CAGradientLayer *gradient;
	NSMutableDictionary* _tag;
	CALayer* gradient;
}
//@property(nonatomic,assign) id<MasterViewControllerDelegate> delegate;
@property(nonatomic,assign) MasterViewController* mvc;

-(id)initForEventEntryWithID:(NSString*)ID;
-(id)initForShotEntryWithID:(NSString*)ID;

-(void)setEventEntry:(NSDictionary*) entry;
-(void)setShotEntry:(NSString*) entry forTag:(NSMutableDictionary*)tag;
+(NSMutableDictionary*)shotsCache;
+(UIColor*)bgColorForSwatch:(NSString*)color andAlpha:(float)alpha;
+(UIColor*)fgColorForSwatch:(NSString*)color andAlpha:(float)alpha;

- (void) setData:(NSMutableDictionary*) tag loadImage: (BOOL)loadImage animated:(BOOL)animated;
@property(nonatomic,assign) bool useDegF;
@property(nonatomic, retain) UILabel* tempDegView;

//@property(nonatomic, retain) UITextField* commentField;
//@property(nonatomic, assign) BOOL showComment;

@end

@interface UIViewController (Additions)
- (BOOL)isVisible;
@end
