#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Tag.h"

@interface NotificationJSQueue : NSObject <AVAudioPlayerDelegate>
{
	NSMutableArray* queue;
	AVAudioPlayer* au_beep, *au_suffix, *au_tagname;
	int loop_beep_count;
}

//@property (nonatomic, readonly) AVAudioPlayer* au_beep;

- (void) enqueue:(NSDictionary*)tag;

@end
