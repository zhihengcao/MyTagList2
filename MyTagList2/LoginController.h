//
//  LoginController.h
//  newsyc
//
//  Created by Grant Paul on 3/22/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "ActivityIndicatorItem.h"

extern NSString * const TagListRememberLoginPrefKey;
extern NSString * const TagListLoginEmailPrefKey;

extern NSString * const TagListLoginPwdPrefKey;
extern NSString * const TagSelectedToArmPrefKey;

@protocol LoginControllerDelegate;

@interface LoginController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
//    UIImageView *backgroundImageView;
    UITableView *tableView;
//	UITableViewCell *loadingCell;
    UITableViewCell *usernameCell;
    UITextField *usernameField;
    UITableViewCell *passwordCell;
    UITextField *passwordField;
    UIBarButtonItem *cancelItem;
    UIBarButtonItem *completeItem;
    ActivityIndicatorItem *loadingItem;
    id<LoginControllerDelegate> delegate;
	
//	BOOL isAuthenticating;
}
-(void)clearUserInputs;

@property (nonatomic, assign) id<LoginControllerDelegate> delegate;

- (void)notifyLoginFailed;

@end

@protocol LoginControllerDelegate<NSObject>
@required
- (void)loginController:(LoginController*)controller  
		  doLoginWithEmail:(NSString*)email Password:(NSString*)password;
- (void)loginControllerDidCancel:(LoginController *)controller;
- (void)loginControllerRegisterRequest:(LoginController *)controller;

@end
