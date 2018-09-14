//
//  WebImageOperations.h
//  MyTagList2
//
//  Created by cao on 1/26/14.
//
//

#import <Foundation/Foundation.h>

@interface WebImageOperations : NSObject {
}

// This takes in a string and imagedata object and returns imagedata processed on a background thread
+ (void)processImageDataWithURLString:(NSString *)urlString andBlock:(void (^)(NSData *imageData))processImage;
@end