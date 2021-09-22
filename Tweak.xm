#import "Tweak.h"

// Huge credits to litten, https://github.com/schneelittchen/Deja-Vu/blob/main/Tweak/DejaVu.xm
// I just wanted to see this concept https://cdn.discordapp.com/attachments/832190410826186762/889845728623599666/unknown.png come to reality

%hook CSCoverSheetViewController


- (void)viewDidLoad { // add oad

	%orig;

	isActive = NO;

	aodView = [UIView new];
	[aodView setBackgroundColor:[UIColor blackColor]];
	[aodView setAlpha:0];
	[aodView setHidden:YES];
	aodView.translatesAutoresizingMaskIntoConstraints = NO;
	[[self view] insertSubview:aodView atIndex:0];

	songTitleLabel = [MarqueeLabel new];
	songTitleLabel.textAlignment = NSTextAlignmentCenter;
	songTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[songTitleLabel setBackgroundColor:[UIColor blackColor]];
	[aodView insertSubview:songTitleLabel atIndex:0];

	[NSLayoutConstraint activateConstraints:@[

		[aodView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[aodView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
		[aodView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[aodView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

	]];

	// establishing superior constraints here :fr:

	[songTitleLabel.bottomAnchor constraintEqualToAnchor : aodView.safeAreaLayoutGuide.bottomAnchor].active = YES;
	[songTitleLabel.centerXAnchor constraintEqualToAnchor : aodView.centerXAnchor].active = YES;
	[songTitleLabel.leadingAnchor constraintEqualToAnchor : aodView.leadingAnchor].active = YES;
	[songTitleLabel.trailingAnchor constraintEqualToAnchor : aodView.trailingAnchor].active = YES;

	// see? prettier :PartySetsuna:

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
	[notificationCenter addObserver:self selector:@selector(activateAOD) name:@"aodActivate" object:nil];
	[notificationCenter addObserver:self selector:@selector(deactivateAOD) name:@"aodDeactivate" object:nil];

	return %orig;

}

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { 


	%orig;
	
	isActive = YES;

	if ([aodView isHidden])
		[self activateAOD];
	else
		[self deactivateAOD];


}

%new
- (void)activateAOD { 

	NSLog(@"AOD: %@", playing ? @"YES" : @"NO");
	if (!playing) return;
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

	pixelShiftTimer = [NSTimer scheduledTimerWithTimeInterval:180.0 target:self selector:@selector(initiatePixelShift) userInfo:nil repeats:YES];

}

%new
- (void)deactivateAOD { 

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

	[pixelShiftTimer invalidate];
	pixelShiftTimer = nil;
	[notificationCenter postNotificationName:@"aodResetShift" object:nil];

}

%new
- (void)initiatePixelShift { // send pixel shift notification

	[[NSNotificationCenter defaultCenter] postNotificationName:@"aodPixelShift" object:nil];

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

	// pixel shift, because we dont want burnin now do we

	[notificationCenter addObserver:self selector:@selector(shift) name:@"aodPixelShift" object:nil];
	[notificationCenter addObserver:self selector:@selector(resetShift) name:@"aodResetPixelShift" object:nil];

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide the time and date

	if ([notification.name isEqual:@"aodHideElements"]) {

		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

			[self setAlpha:0];

		} completion:^(BOOL finished) {

			[self setHidden:YES];

		}];

	} else if ([notification.name isEqual:@"aodUnhideElements"]) {

		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

			[self setAlpha:1];

		} completion:^(BOOL finished) {

			[self setHidden:NO];

		}];

	}

}

%new
- (void)shift { // pixel shift

	if (!loadedTimeAndDateFrame) originalTimeAndDateFrame = [self frame];
	loadedTimeAndDateFrame = YES;

	int direction = arc4random_uniform(2);
	CGRect newFrame = originalTimeAndDateFrame;
	
	if (direction == 0)
		newFrame.origin.x += arc4random_uniform(15);
	else if (direction == 1)
		newFrame.origin.y += arc4random_uniform(15);

	[self setFrame:newFrame];
	
}

%new
- (void)resetShift { // reset frame

	[self setFrame:originalTimeAndDateFrame];

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



%hook SBMediaController


- (void)setNowPlayingInfo:(id)arg1 { // set now playing info


	%orig;

	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {

		if(information) {

			NSDictionary *dict = (__bridge NSDictionary *)information;

			if(dict)

				// looks like this also pulls up the artist name??? wtf, anyways, it does for me rn	

				if(dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle]) songTitleLabel.text = [NSString stringWithFormat:@"%@", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoTitle]];

		}

	});

}

-(BOOL)isPlaying {

	playing = %orig;

	return playing;

}



%end
