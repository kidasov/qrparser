#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>

@protocol BackgroundListenerDelegate <NSObject>
-(void) onBackgroundMove;
-(void) onForegroundMove;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (weak) id <BackgroundListenerDelegate>backgroundListenerDelegate;

@end
