//
//  NSTimer+Blocks.h
//
//  Created by Jiva DeVoe on 1/14/11.
//  Copyright 2011 Random Ideas, LLC. All rights reserved.
//
/*
 
 [NSTimer scheduledTimerWithTimeInterval:2.0 block:^
 {
 [someObj doSomething];
 [someOtherObj doSomethingElse];
 // ... etc ...
 } repeats:NO];

 */

#import <Foundation/Foundation.h>

@interface NSTimer (Blocks)
+(NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
+(NSTimer*)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
@end
