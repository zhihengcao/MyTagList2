//
//  Tag.h
//  MyTagList
//
//  Created by Pei Chang on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const WsRootPrefKey;
extern NSString* WSROOT;
extern NSMutableArray* tagManagerNameList;
extern NSMutableArray* tagManagerMacList;
extern NSInteger currentTagManagerIndex;
extern NSString * const TagManagerChooseAllPrefKey;
extern int maxFreqOffset;
extern BOOL optimizeForV2Tag, isTagListEmpty;
extern NSMutableSet* selectedTags;

typedef enum{
	BasicTag=2, MotionSensor=12, MotionRH=13, TagPro=21, ALS8k=26, TCProbe=42, 
	SolarTag=22, CapSensor=32, ExtResSensor=33, CurrentSensor=42, ReedSensor=52, ReedSensor_noHTU=53, Thermostat=62, PIR = 72, WeMo=82, DropCam=92
} TagType;
typedef enum{
	Disarmed=0, Armed=1, Moved=2, Opened=3, Closed=4, DetectedMovement=5, TimedOut=6, Stabilizing=7
}EventState;
typedef enum{
	TempDisarmed=0, Normal=1, TooHigh=2, TooLow=3
}TempEventState;
typedef enum{
	NotAvailable=0, CapDisarmed=1, CapNormal=2, TooDry=3, TooWet=4
}CapEventState;

typedef enum{
	LightNotAvailable=0, LightDisarmed=1, LightNormal=2, TooDark=3, TooBright=4
}LightEventState;

typedef enum{
	OFF=0, Cool1=1, Cool2=2, Heat1=3, Heat2=4
}ThermostatState;

extern NSTimeInterval serverTime2LocalTime;
@interface NSString(Tag)
@property (nonatomic, readonly) BOOL isEmpty;
@end

@interface NSDictionary (Tag)

@property (nonatomic, readonly) BOOL needCapCal;
@property (nonatomic, readonly) BOOL hasBeeper;
@property (nonatomic, readonly) BOOL hasDS18;
@property (nonatomic, readonly) BOOL hasMotion;
@property (nonatomic, readonly) BOOL has3DCompass;
@property (nonatomic, readonly) BOOL hasLogger;
@property (nonatomic, readonly) BOOL hasPIR;
@property (nonatomic, readonly) BOOL has13bit;
@property (nonatomic, readonly) BOOL hasTemperatureSensor;
@property (nonatomic, readonly) BOOL hasCap;
@property (nonatomic, readonly) BOOL hasALS;
@property (nonatomic, readonly) BOOL hasProtimeter;
@property (nonatomic, readonly) BOOL hasThermocouple;
@property (nonatomic, readonly) BOOL hasThermostat;
@property (nonatomic, readonly) BOOL isKumostat;
@property (nonatomic, readonly) BOOL isNest;
@property (nonatomic, readonly) BOOL supportsHomeAway;
@property (nonatomic, readonly) BOOL isWeMo;
@property (nonatomic, readonly) BOOL isCam;
@property (nonatomic, readonly) BOOL isWeMoLED;
@property (nonatomic, readonly) BOOL isVirtualTag;

@property (nonatomic, readonly) BOOL disabled;
@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, readonly) NSString *notificationJS;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *lastError;

@property (nonatomic, readonly) NSString *uuidFromEventEntry;


@property (nonatomic, readonly) NSString *comment;
@property (nonatomic, readonly) NSString *image_md5;
@property (nonatomic, readonly) int slaveId;
@property (nonatomic, readonly) int oorGrace;

//@property (nonatomic, readonly) int postBackInterval;

@property (nonatomic, readonly) NSString* mac;
@property (nonatomic, readonly) NSString* xSetMac;
@property (nonatomic, readonly) NSString* managerName;
@property (nonatomic, readonly) BOOL online;

@property (nonatomic, readonly) long long lastComm;
@property (nonatomic, readonly) BOOL alive;
@property (nonatomic, readonly) float signaldBm;
@property (nonatomic, readonly) float txpwr;
@property (nonatomic, readonly) BOOL OutOfRange;

@property (nonatomic, readonly) TagType tagType;
@property (nonatomic, readonly) TagType tagType1;
@property (nonatomic, readonly) float batteryVolt;
@property (nonatomic, readonly) float LBTh;

@property (nonatomic, readonly) BOOL beeping;
@property (nonatomic, readonly) BOOL lit;
@property (nonatomic, readonly) BOOL migrationPending;
@property (nonatomic, readonly) BOOL ds18;
@property (nonatomic, readonly) int beepDurationDefault;
@property (nonatomic, readonly) EventState eventState;
@property(nonatomic, readonly) NSString* eventStateSwatch;

@property (nonatomic, readonly) int freqOffset;
@property (nonatomic, readonly) BOOL needFreqCal;

@property (nonatomic, readonly) TempEventState tempEventState;
@property (nonatomic, readonly) TempEventState tempState;
@property(nonatomic, readonly) NSString* tempEventStateSwatch;

@property (nonatomic, readonly) CapEventState capEventState;
@property (nonatomic, readonly) CapEventState rhState;
@property (nonatomic, readonly) LightEventState lightEventState;
@property (nonatomic, readonly) LightEventState lightState;
@property(nonatomic, readonly) NSString* capEventStateSwatch;
@property(nonatomic, readonly) NSString* lightEventStateSwatch;

@property (nonatomic, readonly) BOOL shorted;
@property (nonatomic, readonly) BOOL rssiMode;

@property (nonatomic, readonly) NSString* eventTypeString;
@property (nonatomic, readonly) NSString* msEventString;
@property (nonatomic, readonly) NSString* tempEventString;
@property (nonatomic, readonly) NSString* capEventString;
@property (nonatomic, readonly) NSString* lightEventString;

@property (nonatomic, readonly) NSString* eventCategoryString;

@property (nonatomic, readonly) int batteryPercent;
@property (nonatomic, readonly) float temperatureDegC;
@property (nonatomic, readonly) float lux;

@property (nonatomic, readonly) NSMutableArray* mirrors;

@property (nonatomic, readonly) int capRaw;
@property (nonatomic, readonly) float cap;
@property (nonatomic, readonly) float capCalOffset;

@property (nonatomic, readonly) int version1;
@property (nonatomic, readonly) int version2;
@property (nonatomic, readonly) int rev;

@property (nonatomic, readonly) NSDictionary *playback;

// artificial
@property (nonatomic, readonly) NSMutableDictionary *thermostatRef;
@property (nonatomic, readonly) NSMutableDictionary *targetRef;
@property (nonatomic, readonly) NSMutableArray *scripts;

// return value of SetThermostatTarget
@property (nonatomic, readonly) NSMutableDictionary* tempSensor;

// only for thermostat tag
@property (nonatomic, readonly) NSMutableDictionary* thermostat;
@property (nonatomic, readonly) NSString* targetUuid;
@property (nonatomic, readonly) float th_low;
@property (nonatomic, readonly) float th_high;
@property (nonatomic, readonly) BOOL turnOff;
@property (nonatomic, readonly) BOOL fanOn;
@property (nonatomic, readonly) BOOL disableLocal;
@property (nonatomic, readonly) ThermostatState issuedState;

@property (nonatomic, readonly) NSDictionary* threshold_q;
@property (nonatomic, readonly) float min;
@property (nonatomic, readonly) float max;
@property (nonatomic, readonly) float step;
@property (nonatomic, readonly) float sample1;
@property (nonatomic, readonly) float sample2;

-(NSDate*) nsdateFor:(NSString*)key;

+(NSString*)UserFriendlyTimeSpanString:(BOOL)abbrev ForInterval:(NSTimeInterval)diff;
-(NSString*) UserFriendlyTimeSpanString:(BOOL)abbrev;
@end

@interface NSMutableDictionary (Tag)

-(NSMutableDictionary*)forUpload;
@property(nonatomic, readonly)NSString* tagTypeText;
@property(nonatomic, readonly)NSString* tagRevisionText;
@property(nonatomic, readonly)NSString* placeHolderImageName;

- (NSString *)description;
-(BOOL)isEqual:(id)object;
@property (nonatomic, weak) NSMutableDictionary *thermostatRef;
@property (nonatomic, weak) NSMutableDictionary *targetRef;
@property (nonatomic, readonly) NSDictionary *lastLog;

@property (nonatomic, retain) NSMutableArray *scripts;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, readonly) BOOL running;

@property (nonatomic, retain) NSMutableArray* mirrors;
@property (nonatomic, retain) NSString* mac;
@property (nonatomic, retain) NSString* managerName;
@property (nonatomic, assign) long long lastComm;
@property (nonatomic, assign) BOOL alive;
@property (nonatomic, assign) BOOL beeping;
@property (nonatomic, assign) float signaldBm;
@property (nonatomic, assign) BOOL OutOfRange;

@property (nonatomic, retain) NSString *notificationJS;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *comment;
@property (nonatomic, retain) NSString *image_md5;
@property (nonatomic, assign) BOOL migrationPending;
@property (nonatomic, assign) int beepDurationDefault;
@property (nonatomic, assign) float tempCalOffset;
@property (nonatomic, assign) float temperatureDegC;

@property (nonatomic, assign) int v2flag;

@end

@interface NSString (NoCrash)
-(NSString*)stringByAppendingString:(NSString*)str;
@end
