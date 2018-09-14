//
//  NotificationJSQueue.m
//  MyTagList2
//
//  Created by Pei Chang on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NotificationJSQueue.h"
#import "NSTimer+Blocks.h"
#import "AsyncURLConnection.h"
#import "iToast.h"

@implementation NotificationJSQueue
-(id)init{
	self=[super init];
	if(self){
		queue = [NSMutableArray new];
		loop_beep_count=0;
	}
	return self;
}
- (NSDictionary*) peekQueue {
    if ([queue count] == 0) return nil; // to avoid raising exception (Quinn)
    return [queue objectAtIndex:0];
}
-(NSDictionary*) peekLastObject{
	int count = (int)[queue count];
    if (count == 0) return nil; // to avoid raising exception (Quinn)
    return [queue objectAtIndex:count-1];
}
- (NSDictionary*) dequeue {
    // if ([self count] == 0) return nil; // to avoid raising exception (Quinn)
    NSDictionary* headObject = [queue objectAtIndex:0];
    if (headObject != nil) {
        [[headObject retain] autorelease]; // so it isn't dealloc'ed on remove
        [queue removeObjectAtIndex:0];
    }
    return headObject;
}
-(void)dealloc{
	[au_beep release];
	[au_tagname release];
	[au_suffix release];
	[queue release];
	[super dealloc];
}
-(AVAudioPlayer*)loadAudio:(NSString*)relativeURL
{
	NSError* err;
	AVAudioPlayer* player =
	[[AVAudioPlayer alloc] initWithData:[AsyncURLConnection syncGetRequest:[WSROOT stringByAppendingString:relativeURL] error:&err]
	 //[NSData dataWithContentsOfURL:[NSURL URLWithString:[WSROOT stringByAppendingString:relativeURL]]]
								  error:nil];
	player.delegate = self;
	return player;
}
-(AVAudioPlayer*)au_beep
{
	if(!au_beep){
		au_beep = [self loadAudio:@"eth/styles/beep.wav"];
		[au_beep prepareToPlay];
		[au_beep setDelegate:self];
	}
	return au_beep;
}

-(void)dequeueAndPlay
{
	NSDictionary* tag = [self peekQueue];
	if(!tag)return;

	//NSLog(@"starting to play %@, count=%lu", tag.name, queue.count);

	NSString* js = tag.notificationJS;

	if(NSNotFound != [js rangeOfString:@"beep_once"].location || 
	   NSNotFound != [js rangeOfString:@"beep_oor"].location){		
		if(NSNotFound == [js rangeOfString:@"true"].location){
			[self.au_beep play];
		}else{
			[self dequeue];
			[self dequeueAndPlay];
		}
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
	else if(NSNotFound != [js rangeOfString:@"start_beep"].location){
		
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
		loop_beep_count=1;
		if(NSNotFound != [js rangeOfString:@"true"].location){
			self.au_beep.volume=0;
		}
		[self.au_beep play];
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
	else if(NSNotFound != [js rangeOfString:@"stop_beep"].location){
		loop_beep_count=0;
		[self.au_beep stop];
		[self dequeue];
		[self dequeueAndPlay];
	}
	else if(NSNotFound != [js rangeOfString:@"play_tagname"].location){
		if(au_tagname){
			[au_tagname release];
		}
		au_tagname=[self loadAudio:[NSString stringWithFormat:@"eth/audio/%@.mp3",tag.uuid]];
		if(au_suffix){
			[au_suffix release];
		}
		if(NSNotFound != [js rangeOfString:@"is_open"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_open.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_closed"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_closed.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_open_for_too_long"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_open_for_too_long.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"has_moved"].location){
			au_suffix=[self loadAudio:@"eth/styles/has_moved.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_out_of_range"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_out_of_range.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_back_in_range"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_back_in_range.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"temp_normal"].location){
			au_suffix=[self loadAudio:@"eth/styles/returned_to_normal_temperature.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"temp_toohigh"].location){
			au_suffix=[self loadAudio:@"eth/styles/exceeded_upper_temp_limit.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"temp_toolow"].location){
			au_suffix=[self loadAudio:@"eth/styles/exceeded_lower_temp_limit.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"too_dry"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_too_dry.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"too_humid"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_too_humid.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"cap_normal"].location){
			au_suffix=[self loadAudio:@"eth/styles/returned_to_normal_humidity.mp3"];
		}
		else if(NSNotFound != [js rangeOfString:@"light_normal"].location){
			au_suffix=[self loadAudio:@"eth/styles/returned_to_normal_brightness.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"light_toobright"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_too_bright.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"light_toodark"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_too_dark.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"carried_away"].location){
			au_suffix=[self loadAudio:@"eth/styles/carried_away.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"in_free_fall"].location){
			au_suffix=[self loadAudio:@"eth/styles/in_free_fall.mp3"];
		}
		
		else if(NSNotFound != [js rangeOfString:@"detected_water"].location){
			au_suffix=[self loadAudio:@"eth/styles/detected_water.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"detected_movement"].location){
			au_suffix=[self loadAudio:@"eth/styles/detected_movement.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"timed_out"].location){
			au_suffix=[self loadAudio:@"eth/styles/timed_out.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_disconnected"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_disconnected.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_offline"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_offline.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"is_online"].location){
			au_suffix=[self loadAudio:@"eth/styles/is_online.mp3"];
		}else if(NSNotFound != [js rangeOfString:@"silence"].location){
			au_suffix=[self loadAudio:@"eth/styles/silence.mp3"];
		}else{
			au_suffix=nil;
		}
		
		[au_tagname play];
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		[au_suffix prepareToPlay];
	}
	else if(NSNotFound != [js rangeOfString:@"popup("].location){
		
		NSRange openB = [js rangeOfString:@"(\""]; NSRange closeB = [js rangeOfString:@"\","];
		iToast* toast =[[iToast makeText:[js substringWithRange:NSMakeRange(openB.location+2,closeB.location-openB.location-2)]
					 ] setDuration:iToastDurationNormal];
		[toast show];
		
		[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ClearNotificationJSFor"]
						 jsonString:[NSString stringWithFormat:@"{slaveid:%d}", tag.slaveId]
					  completeBlock:nil errorBlock:nil setMac:tag.mac];

		[self dequeue];
		[self dequeueAndPlay];
	}
	else{
		[self dequeue];
		[self dequeueAndPlay];
	}
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag
{
	if(player==au_tagname){
		[au_suffix play];
		[au_tagname release]; au_tagname=nil;
	}else{
		if(queue.count>0){
			[au_suffix release]; au_suffix=nil;
			
			NSDictionary* tag = [self dequeue];
			//NSLog(@"clearing %@, count=%d", tag.name, queue.count);

			if(tag.slaveId!=255)
				[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/ClearNotificationJSFor"]
						 jsonString:[NSString stringWithFormat:@"{slaveid:%d}", tag.slaveId]
					  completeBlock:nil errorBlock:nil setMac:tag.mac];

			[self dequeueAndPlay];
		}
		if(queue.count==0)
		{
			if(loop_beep_count>0){
				if(player==au_beep)
					[player play];
				
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			}
		}
	}
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    [player play];
}

- (void) enqueue:(NSDictionary*)tag {
	NSDictionary* lastItem = [self peekLastObject];
	if(lastItem!=nil){
		if([tag.uuid isEqualToString:lastItem.uuid] && [tag.notificationJS isEqualToString:lastItem.notificationJS])
			return;
	}
    [queue addObject:tag];
	//NSLog(@"queued %@, count=%d", tag.name, queue.count);
	if([queue count]==1)
		[self dequeueAndPlay];
}

@end
