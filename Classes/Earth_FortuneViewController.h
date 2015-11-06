
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"

/**
 Earth Fortune App
 by Thomas Suarez, Chief Engineer @ CarrotCorp.
**/

@interface Earth_FortuneViewController : UIViewController <UIAlertViewDelegate> {
	IBOutlet UIImageView *imageHolder;
    IBOutlet UIImageView *bgholder;
    IBOutlet UITextView *horoText;
    IBOutlet UIView *picker;
    IBOutlet UIView *hud1;
    IBOutlet UIView *hud2;
    IBOutlet UIButton *iButton;
    IBOutlet UIButton *plusButton;
}

- (IBAction)showPicker:(id)sender;
- (IBAction)continueNoHoro:(id)sender;
- (IBAction)selectHoro:(UIButton *)sender;

@end

