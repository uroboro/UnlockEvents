#include <libactivator/libactivator.h>

int deepness = -1;

#define logStart(...) deepness++; NSMutableString *uroboroString = [[NSMutableString alloc] initWithFormat:@"uroboro %d ", deepness]; [uroboroString appendFormat:__VA_ARGS__]; NSLog(uroboroString)
#define logEnd() deepness--; [uroboroString release]; if (deepness == -1) NSLog(@"uroboro");

#define logStart1(...) deepness++; NSLog(__VA_ARGS__)
#define logEnd1() deepness--; if (deepness == -1) NSLog(@"uroboro");

__attribute__((always_inline))
static inline LAEvent *LASendEventWithName(NSString *eventName) {
	LAEvent *event = [[[LAEvent alloc] initWithName:eventName mode:[LASharedActivator currentEventMode]] autorelease];
	[LASharedActivator sendEventToListener:event];
NSLog(@"[LASharedActivator sendEventToListener:event];");
	return event;
}

static const NSString *SADdeviceUnlockCanceled = @"sbdeviceunlock.canceled";
static const NSString *SADdeviceUnlockFailed = @"sbdeviceunlock.failed";
static const NSString *SADdeviceUnlockSucceeded = @"sbdeviceunlock.succeeded";

@interface SBSlidingAlertDisplay
- (void)deviceUnlockCanceled;
- (void)deviceUnlockFailed;
/*
- (void)deviceUnlockSucceeded; //Haven't found an instance when this method is actually called
- (void)finishedAnimatingOut;
*/
@end

%hook SBSlidingAlertDisplay

- (void)deviceUnlockCanceled {
%log;
logStart(@"-deviceUnlockCanceled");
	LASendEventWithName(SADdeviceUnlockCanceled);
	%orig;
logEnd();
}

- (void)deviceUnlockFailed {
logStart(@"-deviceUnlockFailed");
	LASendEventWithName(SADdeviceUnlockFailed);
	%orig;
logEnd();
}
/*
- (void)deviceUnlockSucceeded {
logStart(@"-deviceUnlockSucceeded");
	//LASendEventWithName(SADdeviceUnlockSucceeded);
	%orig;
logEnd();
}

- (void)finishedAnimatingOut {
logStart(@"-finishedAnimatingOut");
	//LASendEventWithName(SADdeviceUnlockSucceeded);
	%orig;
logEnd();
}
*/
%end


/*
@interface SBAwayController
- (void)_awayViewFinishedAnimatingOut:(id)anOut;
- (void)_finishedUnlockAttemptWithStatus:(BOOL)status;

- (void)_unlockWithSound:(BOOL)sound isAutoUnlock:(BOOL)unlock;
- (BOOL)attemptDeviceUnlockWithPassword:(id)password alertDisplay:(id)display;
- (void)attemptUnlockWithHardwareKeyPress:(BOOL)hardwareKeyPress;
- (void)unlockWithSound:(BOOL)sound;
- (void)unlockWithSound:(BOOL)sound alertDisplay:(id)display;
- (void)unlockWithSound:(BOOL)sound alertDisplay:(id)display isAutoUnlock:(BOOL)unlock;
- (void)unlockWithSound:(BOOL)sound isAutoUnlock:(BOOL)unlock;

@end

%hook SBAwayController

- (void)_awayViewFinishedAnimatingOut:(id)anOut {
logStart(@"-_awayViewFinishedAnimatingOut:%@", anOut);
	//LASendEventWithName(SADdeviceUnlockSucceeded);
	%orig;
logEnd();
}

- (void)_finishedUnlockAttemptWithStatus:(BOOL)status {
logStart(@"-_finishedUnlockAttemptWithStatus:%s", (status)?"YES":"NO");
	//LASendEventWithName((status)?SADdeviceUnlockSucceeded:SADdeviceUnlockFailed);
	%orig;
logEnd();
}



- (void)_unlockWithSound:(BOOL)sound isAutoUnlock:(BOOL)unlock {
logStart(@"_unlockWithSound:%s isAutoUnlock:%s", (sound)?"YES":"NO", (unlock)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}
- (BOOL)attemptDeviceUnlockWithPassword:(id)password alertDisplay:(id)display {
logStart(@"attemptDeviceUnlockWithPassword:%@ alertDisplay:%@", password, display);
	//LASendEventWithName();
	BOOL r = %orig;
	NSLog(@"uroboro %s", (r)?"YES":"NO");
logEnd();
	return r;
}
- (void)attemptUnlockWithHardwareKeyPress:(BOOL)hardwareKeyPress {
logStart(@"attemptUnlockWithHardwareKeyPress:%s", (hardwareKeyPress)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}
- (void)unlockWithSound:(BOOL)sound {
logStart(@"unlockWithSound:%s", (sound)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}
- (void)unlockWithSound:(BOOL)sound alertDisplay:(id)display {
logStart(@"unlockWithSound:%s alertDisplay:%@", (sound)?"YES":"NO", display);
	//LASendEventWithName();
	%orig;
logEnd();
}
- (void)unlockWithSound:(BOOL)sound alertDisplay:(id)display isAutoUnlock:(BOOL)unlock {
logStart(@"unlockWithSound:%s alertDisplay:%@ isAutoUnlock:%s", (sound)?"YES":"NO", display, (unlock)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}
- (void)unlockWithSound:(BOOL)sound isAutoUnlock:(BOOL)unlock {
logStart(@"unlockWithSound:%s isAutoUnlock:%s", (sound)?"YES":"NO", (unlock)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}

%end
*/

@interface SBIconController
- (void)_awayControllerUnlocked:(id)unlocked;
@end

%hook SBIconController

- (void)_awayControllerUnlocked:(id)unlocked {
logStart(@"_awayControllerUnlocked:%@", unlocked);
	LASendEventWithName(SADdeviceUnlockSucceeded);
	%orig;
logEnd();
}

%end

/*
@interface SBUIController
- (void)restoreIconList:(BOOL)animate;
@end

%hook SBUIController
- (void)restoreIconList:(BOOL)animate {
logStart(@"restoreIconList:%s", (animate)?"YES":"NO");
	//LASendEventWithName();
	%orig;
logEnd();
}
%end
*/

/////////////////////////////////////////////////////////////////////////////////////////////////
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
		[LASharedActivator registerEventDataSource:self forEventName:SADdeviceUnlockCanceled];
		[LASharedActivator registerEventDataSource:self forEventName:SADdeviceUnlockFailed];
		[LASharedActivator registerEventDataSource:self forEventName:SADdeviceUnlockSucceeded];
	}
	return self;
}

- (void)dealloc {
	if (LASharedActivator.runningInsideSpringBoard) {
		[LASharedActivator unregisterEventDataSourceWithEventName:SADdeviceUnlockCanceled];
		[LASharedActivator unregisterEventDataSourceWithEventName:SADdeviceUnlockFailed];
		[LASharedActivator unregisterEventDataSourceWithEventName:SADdeviceUnlockSucceeded];
	}
	[super dealloc];
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
	NSString *title = @"";

	if ([eventName isEqualToString:SADdeviceUnlockCanceled]) {
		title = @"Unlock Canceled";
	}

	if ([eventName isEqualToString:SADdeviceUnlockFailed]) {
		title = @"Unlock Failed";
	}

	if ([eventName isEqualToString:SADdeviceUnlockSucceeded]) {
		title = @"Unlock Succeeded";
	}

	return title;
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
	return @"Unlocking";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
	NSString *description = @"";

	if ([eventName isEqualToString:SADdeviceUnlockCanceled]) {
		description = @"Device unlock was canceled";
	}

	if ([eventName isEqualToString:SADdeviceUnlockFailed]) {
		description = @"Device unlock failed";
	}

	if ([eventName isEqualToString:SADdeviceUnlockSucceeded]) {
		description = @"Device unlock succeeded";
	}

	return description;
}

- (BOOL)eventWithNameIsHidden:(NSString *)eventName {
	return NO;
}

- (BOOL)eventWithNameRequiresAssignment:(NSString *)eventName {
	return NO;
}

- (BOOL)eventWithName:(NSString *)eventName isCompatibleWithMode:(NSString *)eventMode {
	return YES;//[eventMode isEqualToString:LAEventModeLockScreen];
}

- (BOOL)eventWithNameSupportsUnlockingDeviceToSend:(NSString *)eventName {
	return YES;//[eventName isEqualToString:SADdeviceUnlockSucceeded];
}

@end

%ctor {
	%init;
	[SADUnlockDataSource sharedInstance];
}
