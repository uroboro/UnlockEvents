#include <libactivator/libactivator.h>

//from https://github.com/rpetrich/libactivator/blob/master/libactivator-private.h#L168
__attribute__((always_inline))
static inline LAEvent *LASendEventWithName(NSString *eventName) {
	LAEvent *event = [[[LAEvent alloc] initWithName:eventName mode:[LASharedActivator currentEventMode]] autorelease];
	[LASharedActivator sendEventToListener:event];
	return event;
}
//to https://github.com/rpetrich/libactivator/blob/master/libactivator-private.h#L174

static const NSString *UEDeviceUnlockCanceled = @"sbdeviceunlock.canceled";
static const NSString *UEDeviceUnlockFailed = @"sbdeviceunlock.failed";
static const NSString *UEDeviceUnlockSucceeded = @"sbdeviceunlock.succeeded";

@interface SBSlidingAlertDisplay

- (void)deviceUnlockCanceled;
- (void)deviceUnlockFailed;

@end

%hook SBSlidingAlertDisplay

- (void)deviceUnlockCanceled {
	LASendEventWithName(UEDeviceUnlockCanceled);
	%orig;
}

- (void)deviceUnlockFailed {
	LASendEventWithName(UEDeviceUnlockFailed);
	%orig;
}

%end

@interface SBIconController

- (void)_awayControllerUnlocked:(id)unlocked;

@end

%hook SBIconController

- (void)_awayControllerUnlocked:(id)unlocked {
	LASendEventWithName(UEDeviceUnlockSucceeded);
	%orig;
}

%end

////////////////////////////////////////////////////////////////
enum {
	eLAEventModeSpringBoard,
	eLAEventModeApplication,
	eLAEventModeLockScreen
};

static inline unsigned char LAEventModeEnum(NSString *eventMode) {
	unsigned char em;
	if ([eventMode isEqualToString:LAEventModeSpringBoard]) {
		em = eLAEventModeSpringBoard;
	}
	if ([eventMode isEqualToString:LAEventModeApplication]) {
		em = eLAEventModeApplication;
	}
	if ([eventMode isEqualToString:LAEventModeLockScreen]) {
		em = eLAEventModeLockScreen;
	}
	return em;
}

static inline unsigned char SADEventName(NSString *eventName) {
	unsigned char en;
	if ([eventName isEqualToString:UEDeviceUnlockCanceled]) {
		en = 0;
	}
	if ([eventName isEqualToString:UEDeviceUnlockFailed]) {
		en = 1;
	}
	if ([eventName isEqualToString:UEDeviceUnlockSucceeded]) {
		en = 2;
	}
	return en;
}

//Begin unlock datasource
@interface SADUnlockDataSource: NSObject <LAEventDataSource> {
}

+ (id)sharedInstance;

@end

@implementation SADUnlockDataSource

+ (id)sharedInstance {
	static SADUnlockDataSource *shared = nil;
	if (!shared) {
		shared = [[SADUnlockDataSource alloc] init];
	}
	return shared;
}

- (id)init {
	if ((self = [super init])) {
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockCanceled];
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockFailed];
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockSucceeded];
	}
	return self;
}

- (void)dealloc {
	if (LASharedActivator.runningInsideSpringBoard) {
		[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockCanceled];
		[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockFailed];
		[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockSucceeded];
	}
	[super dealloc];
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
	unsigned char en = SADEventName(eventName);
	NSString *title[3] = { @"Unlock Canceled", @"Unlock Failed", @"Unlock Succeeded" };
	return title[en];
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
	return @"Unlocking";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
	unsigned char en = SADEventName(eventName);
	NSString *description[3] = { @"Device unlock was canceled", @"Device unlock failed", @"Device unlock succeeded"};
	return description[en];
}

- (BOOL)eventWithNameIsHidden:(NSString *)eventName {
	return NO;
}

- (BOOL)eventWithNameRequiresAssignment:(NSString *)eventName {
	return NO;
}

- (BOOL)eventWithName:(NSString *)eventName isCompatibleWithMode:(NSString *)eventMode {
	unsigned char en = SADEventName(eventName);
	unsigned char em = LAEventModeEnum(eventMode);
	//                em, en
	BOOL compatibility[3][3] = { { NO, NO, YES}, { NO, NO, YES}, { YES, YES, NO} };
	return compatibility[em][en];
}

- (BOOL)eventWithNameSupportsUnlockingDeviceToSend:(NSString *)eventName {
	return NO;
}

@end

%ctor {
	%init;
	[SADUnlockDataSource sharedInstance];
}
