#import <UIKit/UIKit.h>
#import "IASKSettingsReader.h"

@interface IASKPSToggleSwitchSpecifierViewCell : UITableViewCell {
    UILabel *_label;
    UISwitch *_toggle;
	NSString* _progressTitle;
	CGFloat helpTextHeight;
	BOOL hideHelp;
	BOOL firstTimeHelp;
}
@property(nonatomic, retain)NSMutableDictionary* script;
@property (nonatomic, retain) NSString* progressTitle;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, assign) IBOutlet UILabel *label;
@property (nonatomic, assign) IBOutlet UILabel *helpText;
@property (nonatomic, assign) IBOutlet UILabel *toggleState;
@property (nonatomic, assign) IBOutlet UISwitch *toggle;
@property(nonatomic)BOOL toggleOn;
-(void)updateToggleOn;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
- (IBAction)valueChanged:(id)sender;

+(IASKPSToggleSwitchSpecifierViewCell*) newLoadingWithTitle:(NSString*)title Progress:(NSString*)progressTitle helpText:(NSString*)help delegate:(id<IEditableTableViewCellDelegate>)delegate;

+ (IASKPSToggleSwitchSpecifierViewCell*) newWithTitle:(NSString*)title helpText:(NSString*)help delegate:(id<IEditableTableViewCellDelegate>)delegate;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
-(void)revertLoading;
-(void)showLoading;
-(void)toggleHelp;
-(CGFloat)getHeight;

@property (nonatomic, assign) NSString *detailText;

@end
