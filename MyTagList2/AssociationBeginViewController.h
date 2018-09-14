//
//  AssociationBeginViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableTBViewController.h"
#import "AsyncURLConnection.h"
#import "Tag.h"
#import "NSData+Base64.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "iToast.h"

@protocol AssociationDoneDelegate <NSObject>
@required
- (void)associationDone:(NSMutableDictionary*)newTag;
-(void)deletedTagWithSlaveId:(int)slaveId;
- (void)redirectToURL:(NSURL*)url title:(NSString*)title;
-(void)dismissAssociationScreen;
-(void)tagManagerAdded;

@property (nonatomic, retain) NSString* wemoPhoneID;
@property (nonatomic, retain) NSString* wemoPhoneKey;
@property (nonatomic, retain) NSString* wemoHomeID;
@property (nonatomic, assign) BOOL showWeMoButton;
@property (nonatomic, assign) BOOL showDropcam;
@end


@interface AssociationBeginViewController : TableTBViewController <UITextFieldDelegate, IEditableTableViewCellDelegate, UITextViewDelegate>{
	AsyncURLConnection* searchReq;
	BOOL dropcamLoginMode, honeywellLoginMode;
//	BOOL _showWeMo;
//	NSString* _phoneID, *_phoneKey, *_homeID;
}
@property (nonatomic, retain) TableLoadingButtonCell* searchBtnCell, *undeleteBtnCell;
@property (nonatomic, retain) TableLoadingButtonCell* storeBtnCell, *addManagerCell, *iftttBtnCell, *addDropcamBtnCell, *addHoneywellBtnCell;
@property (nonatomic, retain) TableLoadingButtonCell* addWeMoBtnCell;
@property (nonatomic, retain) TableLoadingButtonCell* addNestBtnCell;
@property (nonatomic, retain) IASKPSTextFieldSpecifierViewCell *emailCell, *pwdCell, *hw_emailCell, *hw_pwdCell;
@property (nonatomic, retain) NSArray* tagsToUndelete;
@property (nonatomic, retain) NSArray* scannedThermostats;
@property (nonatomic, retain) NSArray* scannedWeMo;
@property (nonatomic, retain) NSArray* scannedDropcam, *scannedHoneywell;
@property (nonatomic, assign) id<AssociationDoneDelegate> delegate;

- (id)initWithDelegate:(id<AssociationDoneDelegate>)delegate;

@end

#import "IASKPSTextFieldSpecifierViewCell.h"

@interface AssociationEndViewController : TableTBViewController <IEditableTableViewCellDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) NSDictionary* tagInfo;
@property (nonatomic, retain) NSMutableDictionary* associatedTag;
@property (nonatomic, retain) UIBarButtonItem* associateBtn;
@property (nonatomic, retain) IASKPSTextFieldSpecifierViewCell* nameCell, *commentCell;
@property(nonatomic, retain)UITableViewCell* lockFlashCell, *flashLEDCell, *cachePostbackCell;
@property (nonatomic, assign) id<AssociationDoneDelegate> delegate;
@end
