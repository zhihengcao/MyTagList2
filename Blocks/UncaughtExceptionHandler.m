//
//  UncaughtExceptionHandler.m
//  UncaughtExceptions
//
//  Created by Matt Gallagher on 2010/05/25.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "UncaughtExceptionHandler.h"
#import "AsyncURLConnection.h"
#import "Tag.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const ConsoleLogFile = @"console.log";
NSString * const UncaughtExceptionHandlerSignalExceptionName = @"name";
NSString * const UncaughtExceptionHandlerSignalKey = @"signal";
NSString * const UncaughtExceptionHandlerAddressesKey = @"stack";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation UncaughtExceptionHandler

+ (NSArray *)backtrace
{
	 void* callstack[128];
	 int frames = backtrace(callstack, 128);
	 char **strs = backtrace_symbols(callstack, frames);
	 
	 int i;
	 NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
	 for (
	 	i = UncaughtExceptionHandlerSkipAddressCount;
	 	i < UncaughtExceptionHandlerSkipAddressCount +
			UncaughtExceptionHandlerReportAddressCount;
		i++)
	 {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	 }
	 free(strs);
	 
	 return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
{
	if (anIndex == 0)
	{
		dismissed = YES;
	}
}

- (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

static NSUUID *ExecutableUUID(void)
{
    const struct mach_header *executableHeader = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++)
    {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE)
        {
            executableHeader = header;
            break;
        }
    }
	
    if (!executableHeader)
        return nil;
	
    BOOL is64bit = executableHeader->magic == MH_MAGIC_64 || executableHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)executableHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (uint32_t i = 0; i < executableHeader->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        if (segmentCommand->cmd == LC_UUID)
        {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            return [[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid];
        }
    }
	
    return nil;
}
- (void)handleException:(NSException *)exception
{
	fclose(stderr);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *logPath = [documentsDirectory stringByAppendingPathComponent:ConsoleLogFile];
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/ReportCrash2"]
						jsonObj:@{
								  @"reason": [exception reason],
								  @"stack":[[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey],
								  @"log":
									  [NSString stringWithContentsOfFile:logPath encoding:NSASCIIStringEncoding error:nil],
								  @"version": [[NSBundle mainBundle]infoDictionary][(NSString*)kCFBundleVersionKey],
								  @"hardware": [self platform],
								  @"os_version": [[UIDevice currentDevice] systemVersion],
								  @"build_id" : [ExecutableUUID() UUIDString]
									} completeBlock:^(NSDictionary* retval){
					 }errorBlock:^(NSError* e, id* showFrom){
						 return NO;// do not display error
					 } setMac:nil];
	
	freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"w",stderr);
	
	UIAlertView *alert =
		[[[UIAlertView alloc]
			initWithTitle:NSLocalizedString(@"Unhandled exception", nil)
			message:[NSString stringWithFormat:NSLocalizedString(
				@"You can try to continue but the application may be unstable.\n\n"
				@"Debug details follow:\n%@\n%@", nil),
				[exception reason],
				[[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
			delegate:self
			cancelButtonTitle:NSLocalizedString(@"Quit", nil)
			otherButtonTitles:NSLocalizedString(@"Continue", nil), nil]
		autorelease];
	[alert show];
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
	
	while (!dismissed)
	{
		for (NSString *mode in (__bridge NSArray *)allModes)
		{
			CFRunLoopRunInMode((CFStringRef)CFBridgingRetain(mode), 0.001, false);
		}
	}
	
	CFRelease(allModes);

	NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
	
	if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
	{
		kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
	}
	else
	{
		[exception raise];
	}
}

@end

void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
		NSMutableDictionary *userInfo =
		[NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
		setObject:[exception callStackSymbols]
		forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[[UncaughtExceptionHandler alloc] init] autorelease]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:[exception name]
				reason:[exception reason]
				userInfo:userInfo]
		waitUntilDone:YES];
}

void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	[[[[UncaughtExceptionHandler alloc] init] autorelease]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
				reason:
					[NSString stringWithFormat:
						NSLocalizedString(@"Signal %d was raised.", nil),
						signal]
				userInfo: @{UncaughtExceptionHandlerAddressesKey: [UncaughtExceptionHandler backtrace]}]
		waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler()
{
#ifndef DEBUG
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *logPath = [documentsDirectory stringByAppendingPathComponent:ConsoleLogFile];
	freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"w",stderr);
	
	NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
#endif
}

