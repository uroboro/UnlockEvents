#include <libactivator/libactivator.h>

//based on http://iphonedevwiki.net/index.php/Libactivator#Dispatching_Events
static inline LAEvent *LASendEventWithName(NSString *eventName) {
	LAEvent *event = [LAEvent eventWithName:eventName mode:[LASharedActivator currentEventMode]];
	[LASharedActivator sendEventToListener:event];
	return event;
}

static NSString *UEDeviceUnlockCanceled = @"com.uroboro.unlockevents.sbdeviceunlock.canceled";
static NSString *UEDeviceUnlockFailed = @"com.uroboro.unlockevents.sbdeviceunlock.failed";
static NSString *UEDeviceUnlockSucceeded = @"com.uroboro.unlockevents.sbdeviceunlock.succeeded";

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
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	[self sharedInstance];
}

- (id)init {
	if ((self = [super init])) {
		// Register our events
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockCanceled];
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockFailed];
		[LASharedActivator registerEventDataSource:self forEventName:UEDeviceUnlockSucceeded];
	}
	return self;
}

- (void)dealloc {
	[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockCanceled];
	[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockFailed];
	[LASharedActivator unregisterEventDataSourceWithEventName:UEDeviceUnlockSucceeded];

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

////////////////////////////////////////////////////////////////

// Event dispatch

%group UE_IOS6

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

%end // group UE_IOS6

%group UE_IOS8

@interface SBUIPasscodeLockViewBase

- (void)resetForFailedPasscode;

@end

%hook SBUIPasscodeLockViewBase

- (void)resetForFailedPasscode {
    LASendEventWithName(UEDeviceUnlockFailed);
    %orig;
}

%end

@interface SBUIPasscodeLockViewWithKeypad

- (void)_notifyDelegatePasscodeCancelled;

@end

%hook SBUIPasscodeLockViewWithKeypad

- (void)_notifyDelegatePasscodeCancelled {
    LASendEventWithName(UEDeviceUnlockCanceled);
    %orig;
}

%end

@interface SBUIPasscodeLockViewWithKeyboard

- (void)_notifyDelegatePassCodeCancelled;

@end

%hook SBUIPasscodeLockViewWithKeyboard

- (void)_notifyDelegatePasscodeCancelled {
    LASendEventWithName(UEDeviceUnlockCanceled);
    %orig;
}

%end

%end // group UE_IOS8

%ctor {
	if (kCFCoreFoundationVersionNumber < 800) { // < iOS 7
		%init(UE_IOS6);
//	} else if (kCFCoreFoundationVersionNumber < 1000) { // iOS 7
//		%init(UE_IOS7);
	} else { // iOS 8
		%init(UE_IOS8);
	}
	
}