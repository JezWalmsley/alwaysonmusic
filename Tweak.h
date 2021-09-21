BOOL isActive = NO;
UIView *aodView = nil;
UILabel *songTitleLabel = nil;
UILabel *songArtistLabel = nil;
int previousLowPowerModeState = 0;

BOOL wasAutoBrightnessEnabled = YES;
UIImpactFeedbackGenerator* generator = nil;
NSTimer* inactivityTimer = nil;
NSTimer* pixelShiftTimer = nil;
NSTimer* dimTimer = nil;
BOOL loadedTimeAndDateFrame = NO;
CGRect originalTimeAndDateFrame;
float lastBrightness = 0;
BOOL hasAddedStatusBarObserver = NO;


@interface CSCoverSheetViewController : UIViewController
@end

@interface SBLockScreenManager : NSObject
- (BOOL)isLockScreenVisible;
- (void)setBiometricAutoUnlockingDisabled:(BOOL)arg1 forReason:(id)arg2;
- (void)activateaod;
- (void)deactivateaod;
@end

@interface SBProximitySensorManager : NSObject
- (void)_enableProx;
- (void)_disableProx;
@end

@interface SpringBoard : UIApplication
- (void)_simulateHomeButtonPress;
- (void)_simulateLockButtonPress;
- (SBProximitySensorManager *)proximitySensorManager;
@end

@interface SBDashBoardIdleTimerProvider : NSObject
- (void)addDisabledIdleTimerAssertionReason:(id)arg1;
- (void)removeDisabledIdleTimerAssertionReason:(id)arg1;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL)isPlaying;
- (BOOL)isPaused;
@end

@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(id)arg1;
- (id)takeModeAssertionWithDetails:(id)arg1 error:(id *)arg2;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(id *)arg1;
@end

@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(id)arg1 modeIdentifier:(id)arg2 lifetime:(id)arg3;
@end

@interface _UIStatusBar : UIView
@end

@interface UIStatusBar_Modern : UIView
- (_UIStatusBar *)statusBar;
- (void)setVisibility:(NSNotification *)notification;
@end

@interface SBUIProudLockIconView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end

@interface SBFLockScreenDateView : UIView
- (void)setVisibility:(NSNotification *)notification;
- (void)shift;
- (void)resetShift;
@end

@interface CSAdjunctItemView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end

@interface UICoverSheetButton : UIControl
@end

@interface CSQuickActionsButton : UICoverSheetButton
- (void)setVisibility:(NSNotification *)notification;
@end

@interface CSHomeAffordanceView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end

@interface CSTeachableMomentsContainerView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end