//
//  AccountOptionsViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptionsViewController.h"

// [Twitter Account  (id, pwd)]
// [mytaglist.com Account (id, pwd, allowmore)]
@interface AccountOptionsViewController : OptionsViewController<IEditableTableViewCellDelegate>
{
	IASKPSTextFieldSpecifierViewCell *email, *pwd;
	TableLoadingButtonCell* twitterLogin, *webappAccount, *referralProgramLink;
	UITableViewCell* allowMore;
}

@property (nonatomic, readonly) BOOL modified;
-(void) editedTableViewCell:(id)cell;

@end
