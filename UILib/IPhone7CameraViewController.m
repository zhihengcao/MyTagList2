#import "IPhone7CameraViewController.h"

@interface IPhone7CameraViewController ()

@end

@implementation IPhone7CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	AVCapturePhotoOutput* output = [[[AVCapturePhotoOutput alloc]init] autorelease];
	AVCapturePhotoSettings* settings = [AVCapturePhotoSettings photoSettings];

	self.captureSession = [[[AVCaptureSession alloc]init] autorelease];
	
	//self.stillImageOutput = [[AVCaptureStillImageOutput new]autorelease];
	//_stillImageOutput.outputSettings=@{AVVideoCodecKey:AVVideoCodecJPEG};
	
	for(AVCaptureDevice* device in AVCaptureDevice.devices){
		if(device.position==AVCaptureDevicePositionBack){
			
			NSError* err;
			[_captureSession addInput: [AVCaptureDeviceInput deviceInputWithDevice:device error:&err]];
			[_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
			[_captureSession startRunning];
			
			[output capturePhotoWithSettings:settings delegate:self];
			
			[_captureSession addOutput:output];
			
			AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
			previewLayer.bounds=self.view.bounds;
			previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
			[self.view.layer addSublayer:previewLayer];
			[self.view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureButtonPressed)] autorelease]];
		}
	}
}
-(void)captureButtonPressed{
//	_stillImageOutput connectionWithMediaType:<#(NSString *)#>
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
