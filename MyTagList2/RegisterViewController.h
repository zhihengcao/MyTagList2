#import <UIKit/UIKit.h>
#import "TableTBViewController.h"
#import "IASKPSTextFieldSpecifierViewCell.h"

extern NSString* allowmoreText;

@class RegisterViewController;
@protocol RegisterViewControllerDelegate <NSObject>
@required
- (void)registerViewDone:(RegisterViewController*)regvc;
- (void)registerViewDone:(RegisterViewController*)regvc withNewWsRoot:(NSString*)wsRoot;
@end

@interface RegisterViewController : TableTBViewController <IEditableTableViewCellDelegate>
{
	int validFields;
}

- (id)initWithDelegate:(id<RegisterViewControllerDelegate>)delegate;
+(BOOL) IsValidEmail:(NSString *)checkString;

@property (nonatomic, assign) id<RegisterViewControllerDelegate> delegate;
@property (nonatomic, retain) IASKPSTextFieldSpecifierViewCell* macCell, *emailCell, *pwd1Cell, *pwd2Cell, *managerNameCell;
@property (nonatomic, retain) UITableViewCell* allowMoreCell;
@property (nonatomic, retain) UIBarButtonItem* createBtn;
@end
