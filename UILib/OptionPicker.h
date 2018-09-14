#import <UIKit/UIKit.h>
#import "TableTBViewController.h"

@class OptionPicker;

typedef void (^doneBlock_t)(NSInteger selected, BOOL nowPicked);
typedef void (^doneBlockMulti_t)(NSSet* selected, OptionPicker* picker);
typedef void (^dismissUIBlock_t)(BOOL animated);
typedef NSArray* (^generateChoicesBlock_t)();

@interface OptionPicker : TableTBViewController<UITableViewDataSource> {
    NSArray* _options;
	NSInteger _selected;
	NSMutableSet* _selectedMult;
	doneBlock_t _done;
	doneBlockMulti_t _doneMulti;
	generateChoicesBlock_t _optionGen;
}
@property (nonatomic, retain) NSString *helpText;
//@property(nonatomic,retain)OptionPicker* secondaryPicker;

@property (nonatomic, retain) NSString *nowOption;
@property (nonatomic, retain) NSArray *options, *nowOptions;
@property (nonatomic, retain) NSMutableSet *selectedMulti;
@property (nonatomic, assign) int selected;
@property (nonatomic, copy) dismissUIBlock_t dismissUI;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *doneBtn;

- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Done:(doneBlock_t) done;
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Done:(doneBlock_t) done helpText:(NSString*)helpText;
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now Done:(doneBlock_t) done;
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now Done:(doneBlock_t) done helpText:(NSString*)helpText;
- (id)initWithOptions:(NSArray*) options selectedMulti:(NSMutableSet*) s doneMulti:(doneBlockMulti_t)done;
- (id)initWithOptions:(NSArray*) options selectedMulti:(NSMutableSet*) s doneMulti:(doneBlockMulti_t)done helpText:(NSString*)helpText;
- (id)initWithOptionGen:(generateChoicesBlock_t) optionGen Selected:(NSInteger) s Done:(doneBlock_t)done;
- (id)initWithOptionGen:(generateChoicesBlock_t) optionGen Selected:(NSInteger) s Done:(doneBlock_t)done helpText:(NSString*)helpText;
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now nowOptions:(NSArray*) nowOptions Done:(doneBlock_t)done;
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now nowOptions:(NSArray*) nowOptions Done:(doneBlock_t)done helpText:(NSString*)helpText;

@end
