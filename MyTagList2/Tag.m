//
//  Tag.m
//  MyTagList
//
//  Created by Pei Chang on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Tag.h"

#ifdef DEBUG
//const NSString* WSROOT = @"http://192.168.0.109/";
NSString* WSROOT; // = @"https://www.mytaglist.com/";
#else
NSString* WSROOT;
#endif

NSString * const WsRootPrefKey = @"WsRootPrefKey";

int maxFreqOffset;

//{"notificationJS":null,"name":"Front Door","uuid":"bc137493-2716-4d98-a9d5-e33ceb3794f1","comment":"with hole in enclosure","slaveId":0,"tagType":12,"lastComm":129729336909381614,"alive":false,"signaldBm":-75,"batteryVolt":2.8903226852417,"beeping":false,"lit":false,"migrationPending":false,"beepDurationDefault":15,"eventState":1,"OutOfRange":true,"solarVolt":0,"temperature":0,"batteryRemaining":0.69449727675494155}

//{"d":[{"__type":"MyTagList.Tag","notificationJS":null,"name":"2Garage","comment":"zzzzzzzzzzz","slaveId":1,"tagType":12,"lastComm":129722480286669850,"alive":true,"signaldBm":-85,"batteryVolt":2.90594601631165,"beeping":false,"lit":false,"migrationPending":false,"beepDurationDefault":15,"eventState":3,"OutOfRange":false},{"__type":"MyTagList.Tag","notificationJS":null,"name":"Truck Key2\n","comment":"","slaveId":2,"tagType":2,"lastComm":129722474624457554,"alive":true,"signaldBm":-65.625,"batteryVolt":2.95384621620178,"beeping":false,"lit":false,"migrationPending":false,"beepDurationDefault":15,"eventState":0,"OutOfRange":false},{"__type":"MyTagList.Tag","notificationJS":"","name":"Front Door","comment":"with hole in enclosure","slaveId":0,"tagType":12,"lastComm":129722485847949499,"alive":true,"signaldBm":-66.25,"batteryVolt":2.90594601631165,"beeping":false,"lit":false,"migrationPending":false,"beepDurationDefault":15,"eventState":1,"OutOfRange":false}]}

NSMutableArray* tagManagerNameList;
NSMutableArray* tagManagerMacList;
NSInteger currentTagManagerIndex;
NSMutableSet* selectedTags;

BOOL optimizeForV2Tag, isTagListEmpty;

@implementation NSString(Tag)

-(BOOL)isEmpty{
	return self==nil || self==(id)[NSNull null] || [self length]==0 || [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length==0;
}

@end

@implementation NSMutableDictionary (Tag)

-(NSString*)stringForKey:(NSString*)key{
	NSString* ret =[self objectForKey:key]; if(ret==nil || ret==(id)[NSNull null])return @""; else return ret;
}

-(BOOL) beeping{return [[self objectForKey:@"beeping"] boolValue];}
-(void) setBeeping:(BOOL)beeping {[self setObject:[NSNumber numberWithBool:beeping] forKey:@"beeping"];}

- (NSString *)description{
	return self.name;
}
-(BOOL)isEqual:(id)object{
	if( [object isKindOfClass:[NSDictionary class]]){
		return [self.uuid isEqual: ((NSDictionary*)object).uuid];
	}
	return NO;
}

-(void)setMirrors:(NSMutableArray *)mirrors{ [self setObject:mirrors forKey:@"mirrors"];}
-(NSMutableArray*) mirrors{ return [self objectForKey:@"mirrors"];}
-(NSString*)mac{ 
	NSString* mac = [self objectForKey:@"mac"];
	return mac==nil? [tagManagerMacList objectAtIndex:currentTagManagerIndex] :mac;
}
-(NSString*)xSetMac{ 
	return [self objectForKey:@"mac"];
}
-(NSString*)tagTypeText{
	switch(self.tagType){
		case TagPro: return @"Tag Pro";
		case Thermostat: return @"Kumostat/Thermostat";
		case BasicTag: return @"Basic Tag";
		case DropCam: return @"Web Cam";
		case ExtResSensor: return @"External Thermister";
		case MotionRH: return @"Tag w/ 13b Temperature";
		case MotionSensor: return @"Tag w/ 8b Temperature";
		case PIR: return @"PIR KumoSensor";
		case ReedSensor: return @"Reed KumoSensor";
		case WeMo: return @"WeMo device";
		case CapSensor: return @"Water/Moisture Sensor";
		case ALS8k: return @"Tag Pro ALS";
		case TCProbe: return @"Outdoor Probe";
		default: return @"Unknown";
	}
}
-(NSString*)placeHolderImageName{

	switch(self.tagType){
		case TagPro: return self.rev==0x6F? @"ph_pro_2k.png":(self.rev==0x7F? @"ph_pro_8k.png":
															  ((self.rev&0xF)==0xA ? @"ph_pro_accel.png": ((self.rev & 0x10)==0?@"ph_pro_2k.png":@"ph_pro_8k.png")));
		case Thermostat: return @"ph_thermostat.png";
		case DropCam: return @"ph_dropcam.png";
		case MotionRH: return @"ph_tag13b.png";
		case MotionSensor: return @"ph_tag8b.png";
		case PIR: return @"ph_pir.png";
		case ALS8k: return @"ph_als_8k.png";
		case ReedSensor: return @"ph_reed.png";
		case WeMo: return @"ph_wemo.png";
		case CapSensor: return @"ph_water.png";

		case TCProbe: return @"ph_probe.png";
		case Usb: return @"ph_usb.png";
		case UsbALS: return @"ph_usb.png";
		default: return @"PlaceHolder.png";
	}
	
}

-(NSString*)tagRevisionText{
	switch(self.rev){
		case 0: return @"1.1";
		case 1: return @"1.2";
		case 11: return @"1.3";
		case 12: return self.version1==1?  @"1.4" : @"2.0";
		case 13: return self.version1==1?  @"1.5" :  @"2.0";
		case 14: return @"2.1";
		case 15: return @"2.2";
		case 0x1F: return @"2.3";
		case 0x20: return @"2.4";
		case 0x23: return @"2.5";
		case 0x24: return @"2.5";
		case 0x25: return @"2.5";
		case 0x4F: return @"rev. 4F";
		case 0x4E: return @"rev. 4E RH/No-Motion";
		case 0x4D: return @"rev. 4D Temperature-Only";
		case 0x6F: return self.tagType==TagPro?@"2048pt" : @"rev. 6F";
		case 0x6E: return self.tagType==TagPro?@"2KPT No-Motion" : @"RH/No-Motion";
		case 0x6D: return self.tagType==TagPro?@"4KPT Temperature-Only" : @"Temperature-Only";
		case 0x6A: return @"Accelerator Based 2KPT";
		case 0x7F:return self.tagType==TagPro?@"8192pt" : (self.tagType==TCProbe?@"Thermocouple" :@"rev. 7F");
		case 0x7E:return self.tagType==TagPro?@"8KPT No-Motion" : (self.tagType==TCProbe?@"Protimeter" : @"RH/No-Motion");
		case 0x7D:return self.tagType==TagPro?@"16KPT Temperature-Only" : (self.tagType==TCProbe?@"Basic Temperature" :@"Temperature-Only");
		case 0x7A: return @"Accelerator Based 8KPT";
		case 0x8F: return @"rev. 8F";
		case 0x8D: return @"rev. 8D Temperature-Only";
		case 0x9F:return self.tagType==TCProbe?@"Thermocouple" : @"rev. 9F";
		case 0x9E:return self.tagType==TCProbe?@"Protimeter" : @"RH/No-Motion";
		case 0x9D:return self.tagType==TCProbe?@"Basic Temperature" : @"Temperature-Only";
		default: return @"";
	}
}
-(NSString*)managerName{ 
	NSString* managerName = [self objectForKey:@"managerName"];
	return managerName==nil?[tagManagerNameList objectAtIndex:currentTagManagerIndex]:managerName;
}

-(void)setMac:(NSString*)mac{ [self setObject:mac forKey:@"mac"];}
-(void)setManagerName:(NSString *)managerName{[self setObject:managerName forKey:@"managerName"];}

-(void)setLastComm:(long long)lastComm{[self setObject:[NSNumber numberWithLongLong:lastComm] forKey:@"lastComm"];}
-(long long) lastComm {return [[self objectForKey:@"lastComm"] longLongValue];}

-(void)setSignaldBm:(float)signaldBm{[self setObject:[NSNumber numberWithFloat:signaldBm] forKey:@"signaldBm"];}
-(float) signaldBm{return [[self objectForKey:@"signaldBm"] floatValue];}
-(float) txpwr{return [[self objectForKey:@"txpwr"] floatValue];}

-(void)setOutOfRange:(BOOL)OutOfRange{[self setObject:[NSNumber numberWithBool:OutOfRange] forKey:@"OutOfRange"];}
-(BOOL) OutOfRange{return [[self objectForKey:@"OutOfRange"] boolValue];}

-(BOOL)running{return [[self objectForKey:@"running"] boolValue];}
-(BOOL)enabled{return [[self objectForKey:@"enabled"] boolValue];}
-(void)setEnabled:(BOOL)enabled{
	[self setObject:[NSNumber	numberWithBool:enabled] forKey:@"enabled"];
}

-(int)v2flag{return [[self objectForKey:@"v2flag"] intValue];}
-(void)setV2flag:(int)v2flag{
	[self setObject:[NSNumber numberWithInt:v2flag] forKey:@"v2flag"];
}

-(NSString*)name{return [self stringForKey:@"name"];}
-(NSString*)lastError{return [self stringForKey:@"lastError"];}
-(NSDictionary*)lastLog{return [self objectForKey:@"lastLog"];}

-(NSString*)comment{return [self stringForKey:@"comment"];}
-(NSString*)image_md5{NSString* str = [self objectForKey:@"image_md5"]; return (str==nil || str==(id)[NSNull null])?@"":str;}
-(void)setNotificationJS:(NSString *)notificationJS{[self setObject:notificationJS forKey:@"notificationJS"];}
-(NSString*)notificationJS{ 
	return [self stringForKey:@"notificationJS"];
}

-(void)setName:(NSString *)name{[self setObject:name forKey:@"name"];}
-(void)setComment:(NSString *)comment{[self setObject:comment forKey:@"comment"];}
-(void)setImage_md5:(NSString *)image_md5{[self setObject:image_md5 forKey:@"image_md5"];}


-(BOOL) alive{return [[self objectForKey:@"alive"] boolValue];}
-(BOOL) migrationPending{return [[self objectForKey:@"migrationPending"] boolValue];}
-(int) beepDurationDefault{return [[self objectForKey:@"beepDurationDefault"] intValue];}

-(void) setAlive:(BOOL)alive{[self setObject:[NSNumber	numberWithBool:alive] forKey:@"alive"];}
-(void) setMigrationPending:(BOOL)migrationPending{[self setObject:[NSNumber	numberWithBool:migrationPending] forKey:@"migrationPending"];}
-(void)setBeepDurationDefault:(int)beepDurationDefault{[self setObject:[NSNumber numberWithInt:beepDurationDefault] forKey:@"beepDurationDefault"];}



-(float) tempCalOffset{return [[self objectForKey:@"tempCalOffset"] floatValue];}
-(void) setTempCalOffset:(float)tempCalOffset{
	[self setObject:[NSNumber numberWithFloat:tempCalOffset] forKey:@"tempCalOffset"];
}
-(float) temperatureDegC{return [[self objectForKey:@"temperature"] floatValue];}
-(float) lux{return [[self objectForKey:@"lux"] floatValue];}
-(void) setTemperatureDegC:(float)temperatureDegC{
	[self setObject:[NSNumber numberWithFloat:temperatureDegC] forKey:@"temperature"];
}

-(NSMutableDictionary*)thermostatRef{return [self objectForKey:@"_thermostatRef"];}
-(void)setThermostatRef:(NSMutableDictionary *)thermostat{
	if(thermostat!=nil)
		[self setObject:thermostat forKey:@"_thermostatRef"];
	else
		[self removeObjectForKey:@"_thermostatRef"];
}
-(NSMutableDictionary*)targetRef{return [self objectForKey:@"_targetRef"];}
-(void)setTargetRef:(NSMutableDictionary *)targetRef{
	if(targetRef!=nil)
		[self setObject:targetRef forKey:@"_targetRef"];
	else
		[self removeObjectForKey:@"_targetRef"];
}

-(NSMutableArray*)scripts{return [self objectForKey:@"_scripts"];}
-(void)setScripts:(NSMutableArray *)scripts{
	if(scripts!=nil)
		[self setObject:scripts forKey:@"_scripts"];
	else
		[self removeObjectForKey:@"_scripts"];
}

-(NSMutableDictionary*)forUpload{
	NSMutableDictionary* ret = [[self mutableCopy] autorelease];
	ret.name = [ret.name stringByReplacingOccurrencesOfString:@" " withString:@" "];
	[ret removeObjectForKey:@"_targetRef"];
	[ret removeObjectForKey:@"_thermostatRef"];
	[ret removeObjectForKey:@"mirrors"];
	[ret removeObjectForKey:@"_scripts"];
	return ret;
}
@end
@implementation NSDictionary (Tag)

-(float) lux{return [[self objectForKey:@"lux"] floatValue];}

-(float) txpwr{return [[self objectForKey:@"txpwr"] floatValue];}

-(NSString*)stringForKey:(NSString*)key{
	NSString* ret =[self objectForKey:key]; if(ret==nil || ret==(id)[NSNull null])return @""; else return ret;
}

-(NSString*)lastError{return [self stringForKey:@"lastError"];}

NSTimeInterval serverTime2LocalTime = 0.0;

-(NSMutableArray*) mirrors{ return [self objectForKey:@"mirrors"];}

+(NSString*)UserFriendlyTimeSpanString:(BOOL)abbrev ForInterval:(NSTimeInterval)diff{
	int daysDifference = floorf(diff / 60 / 60 / 24);
	if (daysDifference >= 1) return [NSString stringWithFormat:abbrev?@"%dd":NSLocalizedString(@"%d days",nil), daysDifference];
	int hoursDifference = floorf(diff / 60 / 60);
	if (hoursDifference >= 1) return [NSString stringWithFormat:abbrev?@"%dh":NSLocalizedString(@"%d hours",nil), hoursDifference];
	int minDifference = floorf(diff / 60);
	if (minDifference >= 1) return [NSString stringWithFormat:abbrev?@"%dm":NSLocalizedString(@"%d min",@"minutes"), minDifference];
	else return [NSString stringWithFormat:abbrev?@"%ds":NSLocalizedString(@"%d sec",@"seconds"), (int)roundf(diff)];
}

-(NSString*) UserFriendlyTimeSpanString:(BOOL)abbrev{
	
	NSDate* lastComm = [NSDate dateWithTimeIntervalSince1970:(([self lastComm] / 10000000) - 11644473600)];
	NSDate* now = [[[NSDate alloc] init] autorelease];
	NSTimeInterval diff = [now timeIntervalSinceDate:lastComm] + serverTime2LocalTime;
	return [NSDictionary UserFriendlyTimeSpanString:abbrev ForInterval:diff];
}

// artificial entry
-(NSMutableDictionary*)thermostatRef{return [self objectForKey:@"_thermostatRef"];}

-(NSMutableDictionary*)thermostat{return [self objectForKey:@"thermostat"];}
-(NSDictionary*)threshold_q{return [self objectForKey:@"threshold_q"];}
-(float)min{return [[self objectForKey:@"min"] floatValue];}
-(float)max{return [[self objectForKey:@"max"] floatValue];}
-(float)step{return [[self objectForKey:@"step"] floatValue];}
-(float)sample1{return [[self objectForKey:@"sample1"] floatValue];}
-(float)sample2{return [[self objectForKey:@"sample2"] floatValue];}

-(NSMutableDictionary*)tempSensor{return [self objectForKey:@"tempSensor"];}
-(NSString*)targetUuid{return [self stringForKey:@"targetUuid"];}
-(NSMutableDictionary*)targetRef{return [self objectForKey:@"_targetRef"];}
-(NSMutableArray*)scripts{return [self objectForKey:@"_scripts"];}

-(NSDictionary*)playback{return [self objectForKey:@"playback"];}

-(float)th_low{return [[self objectForKey:@"th_low"] floatValue];}
-(float)th_high{return [[self objectForKey:@"th_high"] floatValue];}
-(BOOL) turnOff{return [[self objectForKey:@"turnOff"] boolValue];}
-(BOOL) fanOn{return [[self objectForKey:@"fanOn"] boolValue];}
-(BOOL) disableLocal{return [[self objectForKey:@"disableLocal"] boolValue];}
-(ThermostatState) issuedState{return [[self objectForKey:@"issuedState"] intValue];}

-(NSString*)uuid{return [self stringForKey:@"uuid"];}
-(NSString*)uuidFromEventEntry{
	NSString* uuid = [self stringForKey:@"uuid"];
	if(uuid==nil || uuid.length==0 || (id)uuid==[NSNull null]){
		uuid = [self stringForKey:@"picture"];
		return [uuid stringByDeletingPathExtension];
	}
	else return uuid;
}

-(NSString*)mac{ 
	NSString* mac = [self objectForKey:@"mac"];
	return mac==nil? [tagManagerMacList objectAtIndex:currentTagManagerIndex] :mac;
}
-(NSString*)xSetMac{ 
	return [self stringForKey:@"mac"];
}

-(int) capRaw{return [[self objectForKey:@"capRaw"] intValue];}
-(float) cap{return [[self objectForKey:@"cap"] floatValue];}
-(float) capCalOffset{return [[self objectForKey:@"capCalOffset"] floatValue];}

-(NSString*)managerName{ 
	NSString* managerName = [self objectForKey:@"managerName"];
	return managerName==nil?[tagManagerNameList objectAtIndex:currentTagManagerIndex]:managerName;
}
-(BOOL) online{return [[self objectForKey:@"online"] boolValue];}

-(NSString*)notificationJS{ 
	return [self stringForKey:@"notificationJS"];
}
-(NSString*)name{return [self stringForKey:@"name"];}
-(NSString*)comment{return [self stringForKey:@"comment"];}
-(NSString*)image_md5{NSString* str = [self objectForKey:@"image_md5"]; return (str==nil || str==(id)[NSNull null])?@"":str;}

-(int)slaveId{ return [[self objectForKey:@"slaveId"] intValue];}
-(int)oorGrace{ return [[self objectForKey:@"oorGrace"] intValue];}

-(BOOL) isVirtualTag { return self.slaveId<0; }
-(BOOL) isKumostat { return self.tagType==Thermostat && self.slaveId>=0; }
-(BOOL) isWeMo { return self.tagType==WeMo; }
-(BOOL) isCam { return self.tagType==DropCam; }
-(BOOL) isWeMoLED { return self.tagType==WeMo && self.cap>0; }
-(BOOL) isNest { return self.tagType==Thermostat && self.slaveId<0; }
-(BOOL) supportsHomeAway { return [self.thermostat objectForKey:@"nest_id"] != [NSNull null]; }
-(TagType) tagType1{return [[self objectForKey:@"tagType1"] intValue];}
-(TagType) tagType{return [[self objectForKey:@"tagType"] intValue];}
-(BOOL) needCapCal { TagType t = self.tagType;  return t==CapSensor; }
-(BOOL) hasBeeper{ TagType t = self.tagType;  return t==MotionSensor || t==MotionRH || t==BasicTag || t==TagPro || t==ALS8k;}
-(BOOL) hasDS18{ TagType t = self.tagType;  return t==ReedSensor || t==ReedSensor_noHTU || t==TCProbe; }
-(BOOL) hasMotion{TagType t=self.tagType; int rev=self.rev; if(rev>=0x4E && (rev&0xF)==0xE)return false;
	return t==MotionSensor || t==MotionRH || t==ReedSensor || t==ReedSensor_noHTU || t==PIR || t==TagPro || t==ALS8k;}
-(BOOL) has3DCompass{TagType t=self.tagType; return t==MotionSensor || t==MotionRH || t==TagPro; }
-(BOOL) hasLogger{TagType t=self.tagType; return t==TagPro || t==ALS8k; }
-(BOOL) hasALS{TagType t=self.tagType; return t==ALS8k; }
-(BOOL)hasProtimeter{return self.tagType==TCProbe && (self.rev&0xF)==0xE; }
-(BOOL)hasThermocouple{return self.tagType==TCProbe && (self.rev&0xF)==0xF; }
-(BOOL) has13bit{TagType t=self.tagType; return t==MotionRH || t==ReedSensor ||  t==PIR || t==TagPro || t==ALS8k || (t==TCProbe && self.shorted /*using SHT20*/); }
-(BOOL) hasTemperatureSensor {TagType t=self.tagType; return t!=WeMo && t!=DropCam;}
-(BOOL) hasCap{TagType t=self.tagType; int rev=self.rev; if(rev>=0x4D && (rev&0xF)==0xD)return false;
	if(t==TCProbe && ((rev&0xF)==0xE || self.shorted))return true;
	return t==MotionRH || t==ReedSensor ||  t==PIR || t==CapSensor || t==TagPro || t==ALS8k;}

-(BOOL) hasPIR{TagType t=self.tagType; return t==PIR;}
-(BOOL) hasThermostat{TagType t=self.tagType; return t==Thermostat;}

-(long long) lastComm {return [[self objectForKey:@"lastComm"] longLongValue];}

-(BOOL) disabled{return [[self objectForKey:@"disabled"] boolValue];}
-(BOOL) alive{return [[self objectForKey:@"alive"] boolValue];}

-(float) signaldBm{return [[self objectForKey:@"signaldBm"] floatValue];}

-(float) LBTh{return [[self objectForKey:@"LBTh"] floatValue];}
-(float) batteryVolt{return [[self objectForKey:@"batteryVolt"] floatValue];}
-(int) batteryPercent{return roundf(100.0*[[self objectForKey:@"batteryRemaining"] floatValue]);}
-(float) temperatureDegC{return [[self objectForKey:@"temperature"] floatValue];}

-(BOOL) beeping{return [[self objectForKey:@"beeping"] boolValue];}

-(BOOL) lit{return [[self objectForKey:@"lit"] boolValue];}


-(BOOL) OutOfRange{return [[self objectForKey:@"OutOfRange"] boolValue];}

-(BOOL) migrationPending{return [[self objectForKey:@"migrationPending"] boolValue];}
-(int) beepDurationDefault{return [[self objectForKey:@"beepDurationDefault"] intValue];}

-(BOOL) ds18{return [[self objectForKey:@"ds18"] boolValue];}

-(TempEventState) tempEventState{return [[self objectForKey:@"tempEventState"] intValue];}
-(TempEventState) tempState{return [[self objectForKey:@"tempState"] intValue];}
-(CapEventState) capEventState{return [[self objectForKey:@"capEventState"] intValue];}
-(CapEventState) rhState{return [[self objectForKey:@"rhState"] intValue];}

-(LightEventState) lightEventState{return [[self objectForKey:@"lightEventState"] intValue];}
-(LightEventState) lightState{return [[self objectForKey:@"lightState"] intValue];}

-(BOOL) shorted{return [[self objectForKey:@"shorted"] boolValue];}
-(BOOL) rssiMode{return [[self objectForKey:@"rssiMode"] boolValue];}

-(EventState) eventState{return [[self objectForKey:@"eventState"] intValue];}
-(NSString*)eventStateSwatch{
	switch (self.eventState) {
		case Armed:
		case TimedOut:
		case Closed:
			return @"a";
		case Disarmed:
			return @"c";
		case Moved:
		case Opened:
			return @"e";
		default:
			return nil;
	}
}
-(NSString*)tempEventStateSwatch{
	switch(self.tempEventState){
		case TooLow: return @"b";
		case TooHigh: return @"p";
		default: return nil;
	}
}
-(NSString*)capEventStateSwatch{
	switch (self.capEventState) {
		case TooDry: return @"r";
		case TooWet: return @"f";
		default: return nil;
	}
}

-(NSString*)lightEventStateSwatch{
	switch (self.lightEventState) {
		case TooDark: return @"b";
		case TooBright: return @"e";
		default: return nil;
	}
}

-(int)freqOffset{return [[self objectForKey:@"freqOffset"] intValue];}
-(BOOL)needFreqCal{return ABS(self.freqOffset)>maxFreqOffset;}

-(int)version1{return [[self objectForKey:@"version1"] intValue];}
-(int)version2{return [[self objectForKey:@"version2"] intValue];}
-(int)rev{return [[self objectForKey:@"rev"] intValue];}

-(NSString*) msEventString
{ 
	NSString* state1;
	if(self.OutOfRange)state1= NSLocalizedString(@"Out of range",nil);
	else switch([self eventState]){
		case Disarmed:
			state1= NSLocalizedString(@"Disarmed",nil); break;
		case Armed:
			state1= NSLocalizedString(@"Armed",nil); break;
		case Closed:
			state1= NSLocalizedString(@"Closed",nil); break;
		case Moved:
			state1= NSLocalizedString(@"Moved",nil); break;
		case Opened:
			state1= NSLocalizedString(@"Opened",nil); break;
		case DetectedMovement:
			state1= NSLocalizedString(@"Detected Movement",nil); break;
		case TimedOut:
			state1=NSLocalizedString(@"Timed Out",nil); break;
		case Stabilizing:
			state1=NSLocalizedString(@"Stabilizing...",nil); break;
		default:
			state1= NSLocalizedString(@"Unknown",nil);
	}
	return state1;
}
-(NSString*) tempEventString{
	
	if(self.tempEventState == TooHigh)
		return NSLocalizedString(@"Too Hot",nil);
	else if(self.tempEventState==TooLow)
		return NSLocalizedString(@"Too Cold",nil);
	else
		return @"";
}
-(NSString*) cap2EventString
{
	return self.shorted? NSLocalizedString(@"Water Detected",nil) : @"";
}
-(NSString*) capEventString
{
	if(self.capEventState == TooWet)
		return NSLocalizedString(@"Too Wet",nil);
	else if(self.capEventState==TooDry)
		return NSLocalizedString(@"Too Dry",nil);
	else
		return @"";
}
-(NSString*) lightEventString
{
	if(self.lightEventState == TooDark)
		return NSLocalizedString(@"Too Dark",nil);
	else if(self.lightEventState==TooBright)
		return NSLocalizedString(@"Too Bright",nil);
	else
		return @"";
}
-(NSDate*) nsdateFor:(NSString *)key{

	return [NSDate dateWithTimeIntervalSince1970:((
													   [[self objectForKey:key] longLongValue] / 10000000) - 11644473600)];

}
-(NSString*) currentCapEventString
{
	if(self.capEventState==TooDry)
		return NSLocalizedString(@"Detached",nil);
	else
		return @"";
}
-(NSString*) eventTypeString
{ 
	NSMutableArray* events = [[[NSMutableArray alloc] init] autorelease];
	if(self.isWeMo)
		return self.lit?NSLocalizedString(@"On",nil):NSLocalizedString(@"Off",nil);
	if(self.isCam){
		
		[events addObject:self.lit?NSLocalizedString(@"Streaming",nil):NSLocalizedString(@"Off",nil)];
		if(self.beeping)[events addObject:NSLocalizedString(@"Time lapse underway",nil)];
		return [events componentsJoinedByString:@", "];
		
	}
	if(self.isNest){
		if(self.supportsHomeAway)
			[events addObject:self.thermostat.turnOff?@"Away":@"Home"];
		else
			[events addObject:self.thermostat.turnOff?NSLocalizedString(@"Off",nil):NSLocalizedString(@"On",nil)];
	}
	if(self.playback!=nil && (NSNull*)self.playback!=[NSNull null]){
		[events addObject:[NSString stringWithFormat:NSLocalizedString(@"Uploading data: %@/%@",nil),
						   [self.playback objectForKey:@"receivedPoints"],[self.playback objectForKey:@"totalPoints"]  ]];
	}
	if(self.batteryVolt<=self.LBTh){
		[events addObject:NSLocalizedString(@"Battery Low",nil)];
	}
	if(self.needFreqCal){
		[events addObject:NSLocalizedString(@"Need Calibration",nil)];
	}
	if(self.hasMotion){
		[events addObject:self.msEventString];
	}else{
		if(self.OutOfRange)
			[events addObject:NSLocalizedString(@"Out of Range",nil)];
	}
	NSString* tes = self.tempEventString;
	if(tes.length>0)[events addObject:tes];
	
	if(self.tagType == CapSensor){
		tes = self.capEventString;
		if(tes.length>0)[events addObject:tes];
		tes = self.cap2EventString;
		if(tes.length>0)[events addObject:tes];
	}
	else if(self.tagType == CurrentSensor){
		tes = self.currentCapEventString;
		if(tes.length>0)[events addObject:tes];		
	}
	
	return [events componentsJoinedByString:@", "];
}
-(NSString*) eventCategoryString
{ 
	switch([self eventState]){
		case Disarmed:
		case Stabilizing:
			return NSLocalizedString(@"Disarmed",nil);
		case Closed:
		case Armed:
		case TimedOut:
			return NSLocalizedString(@"Armed",nil);
		case Moved:
		case Opened:
		case DetectedMovement:
			return NSLocalizedString(@"Triggered",nil);
		default:
			return NSLocalizedString(@"All",nil);
	}
}
@end

@implementation NSString (NoCrash)

-(NSString*)stringByAppendingString:(NSString *)str{
	if(str!=nil && (NSObject*)str!=[NSNull null]){
		NSMutableString* newStr = [[NSMutableString new] autorelease];
		[newStr appendString:self];
		[newStr appendString:str];
		return newStr;
	}
	else return self;
}

@end
