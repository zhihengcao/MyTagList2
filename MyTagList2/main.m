//
//  main.m
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#ifdef DEBUG_DEMO
#import "QTouchposeApplication.h"
#endif

int main(int argc, char *argv[])
{
	@autoreleasepool {
		
		NSString* language =[[NSUserDefaults standardUserDefaults] stringForKey:@"app_language"];
		if(language!=nil &&  ![language isEqualToString:@"system"]){
			[[NSUserDefaults standardUserDefaults]setObject:@[language] forKey:@"AppleLanguages"];
			[NSBundle setLanguage:language];
		}
		else{
			language = [[NSLocale preferredLanguages] firstObject];
			[[NSUserDefaults standardUserDefaults] setObject:language forKey:@"app_language"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}

/*#ifdef DEBUG_DEMO
		return UIApplicationMain(argc, argv, NSStringFromClass([QTouchposeApplication class]), NSStringFromClass([AppDelegate class]));
		
#else*/
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//#endif
		
	}
}
