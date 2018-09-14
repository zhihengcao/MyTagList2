//
//  IPhone7CameraViewController.h
//  MyTagList2
//
//  Created by cao on 5/4/17.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface IPhone7CameraViewController : UIViewController <AVCapturePhotoCaptureDelegate>
@property(nonatomic, retain)AVCaptureSession* captureSession;


@end
