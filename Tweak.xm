#import "Tweak.h"

%hook CSCoverSheetViewController

- (void)viewDidLoad { // add oad

	%orig;

	isActive = NO;

	aodView = [[UIView alloc] initWithFrame:[[self view] bounds]];
	[aodView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[aodView setBackgroundColor:[UIColor blackColor]];
	[aodView setAlpha:1];
	[aodView setHidden:YES];
	[[self view] insertSubview:aodView atIndex:0];

	songTitleLabel = [UILabel new];
	songTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[songTitleLabel setBackgroundColor:[UIColor blackColor]];
	[songTitleLabel setText:@"Very good song here"];
	[songTitleLabel setHidden:NO];
	[aodView addSubview:songTitleLabel];

	[NSLayoutConstraint activateConstraints:@[
            [aodView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
			[aodView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
			[aodView.widthAnchor constraintEqualToConstant:256],
			[aodView.heightAnchor constraintEqualToConstant:256],
        ]];

}

- (void)viewWillDisappear:(BOOL)animated {

	%orig;

	if ([aodView isHidden]) return;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"aodDeactivate" object:nil];

}

%end

%hook SBLockScreenManager

- (id)init { // register notification observers

	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	[notificationCenter addObserver:self selector:@selector(activateaod) name:@"aodActivate" object:nil];
	[notificationCenter addObserver:self selector:@selector(deactivateaod) name:@"aodDeactivate" object:nil];

	return %orig;

}

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { 

	%orig;
	
	
	isActive = YES;

	if ([aodView isHidden])
		[self activateaod];
	else
		[self deactivateaod];


}

%new
- (void)activateaod { 

	[aodView setAlpha:1];
	[aodView setHidden:NO];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
		[springboard _simulateHomeButtonPress];
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];

		[[springboard proximitySensorManager] _enableProx];

		[notificationCenter postNotificationName:@"aodUpdateIdleTimer" object:nil];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[notificationCenter postNotificationName:@"aodHideElements" object:nil];
		});
	});

}

%new
- (void)deactivateaod { 

	isActive = NO;

	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		[aodView setAlpha:0];
	} completion:^(BOOL finished) {
		[aodView setHidden:YES];
	}];

	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];


	SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
	[[springboard proximitySensorManager] _disableProx];
	
	[notificationCenter postNotificationName:@"aodUpdateIdleTimer" object:nil];
	[notificationCenter postNotificationName:@"aodUnhideElements" object:nil];


}


%end

%hook SBProximitySensorManager

- (void)_disableProx { // prevent proximity sensor from disabling itself

	if (!isActive)
		%orig;
	else
		return;

}

%end

%hook NCNotificationListView

- (void)touchesBegan:(id)arg1 withEvent:(id)arg2 { // 

	%orig;

	if ([aodView isHidden]) return;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"aodDeactivate" object:nil];

}

%end

%hook SBLiftToWakeController

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 orientation:(int)arg3 { 

	%orig;

	if (isActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"aodDeactivate" object:nil];
		});
	}

}

%end

%hook SBDashBoardIdleTimerProvider

- (id)initWithDelegate:(id)arg1 { // add a notification observer

	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	[notificationCenter addObserver:self selector:@selector(updateIdleTimer) name:@"aodUpdateIdleTimer" object:nil];

	return %orig;

}

%new
- (void)updateIdleTimer { // toggle idle timer

	if (isActive)
		[self addDisabledIdleTimerAssertionReason:@"me.jez.alwaysonmusic"];
	else
		[self removeDisabledIdleTimerAssertionReason:@"me.jez.alwaysonmusic"];

}

%end

%hook SBReachabilityManager

- (BOOL)reachabilityEnabled { // disable reachability

	if (isActive)
		return NO;
	else
		return %orig;

}

%end

%hook SBControlCenterController

- (BOOL)_shouldAllowControlCenterGesture { // disable control center

	if (isActive)
		return NO;
	else
		return %orig;

}

%end

%hook SBMainDisplayPolicyAggregator

- (BOOL)_allowsCapabilityLockScreenCameraWithExplanation:(id *)arg1 { // disable camera swipe

    if (isActive)
		return NO;
	else
		return %orig;

}

- (BOOL)_allowsCapabilityTodayViewWithExplanation:(id *)arg1 { // disable widgets swipe

	if (isActive)
		return NO;
	else
		return %orig;

}

%end

%hook UIStatusBar_Modern

- (void)setFrame:(CGRect)arg1 { // add a notification observer

	if (!hasAddedStatusBarObserver) {
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
		[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];
		hasAddedStatusBarObserver = YES;
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the status bar

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self statusBar] setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self statusBar] setAlpha:1];
		} completion:nil];
	}

}

%end

%hook SBUIProudLockIconView

- (id)initWithFrame:(CGRect)frame { // add a notification observer


	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];


	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the faceid lock

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self superview] setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self superview] setAlpha:1];
		} completion:nil];
	}

}

%end

%hook SBFLockScreenDateView

- (id)initWithFrame:(CGRect)frame { // add a notification observer

	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];


	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the time and date

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setHidden:YES];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setHidden:NO];
		} completion:nil];
	}

}


%end

%hook CSAdjunctItemView

- (id)initWithFrame:(CGRect)frame { // add a notification observer

	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the media player

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1];
		} completion:nil];
	}

}

%end

%hook CSQuickActionsButton

- (id)initWithFrame:(CGRect)frame { // add a notification observer


	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];


	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the quick actions

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1];
		} completion:nil];
	}

}

%end

%hook CSTeachableMomentsContainerView

- (id)initWithFrame:(CGRect)frame { // add a notification observer


	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];


	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the unlock label and control center indicator

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1];
		} completion:nil];
	}

}

%end

%hook CSHomeAffordanceView

- (id)initWithFrame:(CGRect)frame { // add a notification observer


	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodHideElements" object:nil];
	[notificationCenter addObserver:self selector:@selector(setVisibility:) name:@"aodUnhideElements" object:nil];


	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the homebar

	if ([notification.name isEqual:@"aodHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0];
		} completion:nil];
	} else if ([notification.name isEqual:@"aodUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1];
		} completion:nil];
	}

}

%end
