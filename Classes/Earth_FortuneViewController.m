
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "Earth_FortuneViewController.h"

/**
 Earth Fortune App
 by Thomas Suarez, Chief Engineer @ CarrotCorp.
**/

@implementation Earth_FortuneViewController

/* Horoscope */
NSString *horoscope; // The fetched horoscope
NSString *sign; // The user's sign

/* Earth */
const int interval = 3; // how fast the Earth changes color
int i = 0; // current Earth color image in the cycle
float hueChange = 0; // current amount of hue change for image tinting
NSMutableArray *colors; // earth fade colors

/* Views */
const float fadeTime = 2.5;
UIImage *earthDefault; // default white Earth to be tinted

/* Objects */
NSUserDefaults *sud; // Stores the user's sign and whether or not the tutorial was done already
AVAudioPlayer *music; // background music player

/* Network */
NSURL *horoURL; // horoscope server URL
bool reachable; // are the internet connection AND server available

#pragma mark INIT

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Test network status
    [self testNetwork];
    
    // Set up user defaults to store the user's sign and whether the tutorial was done already
    sud = [NSUserDefaults standardUserDefaults];
    if ([sud objectForKey:@"sign"] != nil) {
        sign = [sud objectForKey:@"sign"];
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(refreshHoro) userInfo:nil repeats:NO];
    }
    
    // Set up & start fading Earth colors
    [self setupFade];
    
    // Start the background music
    music = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bgmusic" ofType:@"mp3"]] error:NULL];
    [music setNumberOfLoops:-1];
    [music play];
    
    // If the tutorial was never done before, start it now
    if (![sud boolForKey:@"tutdone"]) {
        NSLog(@"Starting tutorial...", nil);
        [self startTutorial];
    }
    else {
        // Fade away tutorial
        [UIView animateWithDuration:4 animations:^{
            horoText.alpha = 0.8;
            iButton.alpha = 0.8;
            arrowButton.alpha = 0.8;
        }];
    }
}

#pragma mark Network

- (void)testNetwork {
    // Initialize reachability object with CarrotCorp server
    Reachability *reach = [Reachability reachabilityWithHostname:@"carrotcorp.com"];
    
    // Set blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        reachable = true;
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NSLog(@"NETWORK DOWN!", nil);
        reachable = false;
    };
    
    // Start the notifier which will cause the reachability object to retain itself
    [reach startNotifier];
}

// Horoscope fetch callback
- (void)fetchedData:(NSData *)responseData {
    horoscope = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    // Parse the response
    if (horoscope.length > 0) {
        horoscope = [horoscope substringFromIndex:3];
        
        NSRange range = [horoscope rangeOfString:@"</p>"];
        if (range.location != NSNotFound) {
            horoscope = [horoscope substringToIndex:range.location];
            
            // Trim white space
            horoscope = [horoscope stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        // If there is no horoscope available, don't show one. Then log the fetched data.
        NSRange error_range = [horoscope rangeOfString:@"<b>Warning</b>"];
        if (error_range.location == NSNotFound) {
            [horoText setText:horoscope];
        }
        else {
            NSLog([NSString stringWithFormat:@"horoscope was not shown due to a server error:\n---------'%@'---------", horoscope], nil);
        }
    }
    else {
        NSLog(@"horoscope was not shown because the string variable 'horoscope' had a length of 0.", nil);
    }
}

// Fetch the data if the internet connection AND server are available
- (void)refreshHoro {
    if (reachable)
    {
        // Set new horoscope server URL
        horoURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://carrotcorp.com/private/earthfortune/gethoro.php?sign=%@", sign]];
        
        // Async server request
        dispatch_async(kBgQueue, ^{
            NSData* data = [NSData dataWithContentsOfURL: horoURL];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        });
    }
}

#pragma mark Earth UI

- (void)setupFade {
    // Set initial earth fade colors
    colors = [[NSMutableArray alloc] initWithObjects: [UIColor blueColor], [UIColor greenColor], [UIColor orangeColor], [UIColor purpleColor], [UIColor redColor], [UIColor whiteColor], [UIColor yellowColor], nil];
    
    // The above colors have an alpha of 1, so they will be opaque.
    // Change them to 0.5 alpha (translucent)
    for (int i=0; i < colors.count; i++) {
        UIColor *newColor = colors[i];
        newColor = [newColor colorWithAlphaComponent:0.5];
        [colors replaceObjectAtIndex:i withObject:newColor];
    }
    
    // Start fading the Earth's color
    earthDefault = [UIImage imageNamed:@"earth.png"];
    [imageHolder setImage:earthDefault];
    [self fadeColor];
}

// Cycle through the Earth color images
- (void)fadeColor {
    // If the image is done with its cycle, restart
    if (i == colors.count) {
        i = 0;
        [self fadeColor];
    }
    
    // Set color tint
    UIImage *coloredImage = [self overlayColor:colors[i]];
    [imageHolder setImage:coloredImage];
    
    // Start animation
    CATransition *transition = [CATransition animation];
    transition.duration = interval;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [imageHolder.layer addAnimation:transition forKey:nil];
    
    // Schedule next fadeColor call
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(fadeColor) userInfo:nil repeats:NO];
    
    // Increment counter
    i++;
}

/*
 From http://stackoverflow.com/a/11074193/2617124 with own modifications
 and some tips from http://www.planet1107.net/blog/tips-tutorials/ios5-core-image-filters/
*/
- (UIImage *)overlayColor:(UIColor *)color {
    // Add to hue change amount
    hueChange += 1.0f;
    
    // Get current image
    CIImage *beginImage = [CIImage imageWithCGImage:earthDefault.CGImage];
    
    // Apply filter to a new image
    CIFilter *filter = [CIFilter filterWithName:@"CIHueAdjust"];
    [filter setDefaults];
    [filter setValue:beginImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:hueChange] forKey:@"inputAngle"];
    
    CIImage *outputImage = [filter outputImage];
    UIImage *endImage = [[UIImage alloc] initWithCIImage:outputImage];
    
    return endImage;
}

#pragma mark Hud UI

- (void)setHudAttrs:(UIView *)hud {
    hud.layer.cornerRadius = 15.0;
    hud.layer.shadowColor = [UIColor blackColor].CGColor;
    hud.layer.shadowOpacity = 0.5;
    hud.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    hud.layer.shadowRadius = 10.0;
    hud.alpha = 0;
}

- (void)fadeHud:(UIView *)hud shouldFadeIn:(bool)shouldFadeIn withDelay:(float)delayTime {

    // Delay action
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        
        float newAlpha = shouldFadeIn ? 0.5 : 0.0;
        
        [UIView animateWithDuration:fadeTime animations: ^{
            hud.alpha = newAlpha;
        }];
        
    });
    
}

- (void)startTutorial {
    // Set Hud attributes
    [self setHudAttrs:hud1];
    [self setHudAttrs:hud2];
    
    // Cycle tutorial Hud screens
    [self fadeHud: hud1 shouldFadeIn: true withDelay: 0.0]; // fade in Hud 1
    [self fadeHud: hud1 shouldFadeIn: false withDelay: fadeTime + 3]; // fade out Hud 1
    [self fadeHud: hud2 shouldFadeIn: true withDelay: fadeTime + 3]; // fade in Hud 2
}

- (IBAction)showPicker:(id)sender {
    // Set Hud attributes
    [self setHudAttrs:picker];
    
    [self.view addSubview:picker];
    
    // Fade in picker
    [UIView animateWithDuration:fadeTime animations:^{
        picker.alpha = 0.6;
        iButton.alpha = 0.0;
        arrowButton.alpha = 0.0;
    }];
}

#pragma mark Button UI

- (IBAction)continueNoHoro:(id)sender { // "i" button
    // User continues without viewing a horoscope, wants to watch the Earth fade only.
    [UIView animateWithDuration:fadeTime animations:^{
        picker.alpha = 0.0;
        iButton.alpha = 0.8;
        arrowButton.alpha = 0.0;
        horoText.alpha = 0.0;
    }];
}

- (IBAction)selectHoro:(UIButton *)button { // "+" button
    // Possible horoscope signs
    NSArray *signs = @[ @"Aries", @"Taurus", @"Gemini", @"Cancer", @"Leo", @"Virgo", @"Libra", @"Scorpio", @"Sagittarius", @"Capricorn", @"Aquarius", @"Pisces" ];
    
    // Get sign based on the button's tag in UI
    sign = signs[button.tag-1];
    
    // Save the selected sign for future app launches
    [sud setObject:sign forKey:@"sign"];
    
    NSLog(@"Selected sign: %@", sign);
    
    // Fetch the horoscope and show it
    [self refreshHoro];
    
    // Fade out tutorial hud (if necessary)
    [self fadeHud: hud2 shouldFadeIn: false withDelay: 0.0];
    
    // Fade out the picker view and Fade in the buttons/horoscope text
    [UIView animateWithDuration:fadeTime animations:^{
        picker.alpha = 0.0;
        horoText.alpha = 0.8;
        iButton.alpha = 0.8;
        arrowButton.alpha = 0.8;
    }];
}

#pragma mark ETC

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
