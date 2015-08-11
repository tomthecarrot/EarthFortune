
#import <UIKit/UIKit.h>

@class Earth_FortuneViewController;

/**
 Earth Fortune App
 by Thomas Suarez, Chief Engineer @ CarrotCorp.
**/

@interface Earth_FortuneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    Earth_FortuneViewController *vc;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

