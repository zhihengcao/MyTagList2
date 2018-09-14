//
//  SpecialOptionsViewController.h
//  MyTagList2
//
//  Created by cao on 4/6/17.
//
//

#import "TableTBViewController.h"
typedef void (^dismissUIBlock_t)(BOOL animated);

@interface SpecialOptionsViewController : TableTBViewController
@property(nonatomic, retain)UITableViewCell* lockFlashCell, *flashLEDCell, *cachePostbackCell;
@property (nonatomic, retain) UIBarButtonItem* writeBtn;
@property (nonatomic, retain) NSMutableDictionary* tag;
@property (nonatomic, copy) dismissUIBlock_t dismissUI;

- (id)initForTag:(NSMutableDictionary*) tag;
-(NSString*) xSetMac;

@end
