//
//  WebImageOperations.m
//  MyTagList2
//
//  Created by cao on 1/26/14.
//
//

#import "WebImageOperations.h"
#import "AsyncURLConnection.h"
#import <QuartzCore/QuartzCore.h>

@implementation WebImageOperations


+ (void)processImageDataWithURLString:(NSString *)urlString andBlock:(void (^)(NSData *imageData))processImage
{
    //NSURL *url = [NSURL URLWithString:urlString];
	
//    dispatch_queue_t callerQueue = dispatch_get_current_queue();
    dispatch_queue_t downloadQueue = dispatch_queue_create("com.MyTagList.processsmagequeue", NULL);
    dispatch_async(downloadQueue, ^{
		NSError* err;
		NSData * imageData = [AsyncURLConnection syncGetRequest:urlString error:&err]; //[NSData dataWithContentsOfURL:url];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            processImage(imageData);
        });
    });
    dispatch_release(downloadQueue);
}

@end
