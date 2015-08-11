
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "Earth_FortuneViewController.h"

/**
 Earth Fortune App
 by Thomas Suarez, Chief Engineer @ CarrotCorp.
**/

@implementation Earth_FortuneViewController

/* Main */
int i = 0; // current Earth color image in the cycle
float hueChange = 0; // current amount of hue change for image tinting
int tutnum; // which part of the tutorial the user is currently on
static int interval = 3; // how fast the Earth changes color
NSString *horoscope; // The fetched horoscope
NSString *sign; // The user's sign
NSUserDefaults *sud; // Stores the user's sign and whether or not the tutorial was done already
NSMutableArray *colors; // earth fade colors
AVAudioPlayer *music; // background music player

/* View Objects */
UIImage *earthDefault; // default white Earth to be tinted
UIView *newHud;
UIView *newHud2;
UIView *newPicker; // horoscope sign picker view

/* Network */
NSURL *horoURL; // horoscope server URL
bool reachable; // are the internet connection AND server available


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
        tutnum = 1;
        [NSTimer scheduledTimerWithTimeInterval:4.5 target:self selector:@selector(tutorial) userInfo:nil repeats:YES];
    }
    else {
        [UIView beginAnimations: @"Startup_tutdone" context:nil];
        [UIView setAnimationDuration:4];
        
        horoText.alpha = 0.8;
        iButton.alpha = 0.8;
        arrowButton.alpha = 0.8;
        
        [UIView commitAnimations];
    }
}

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
    if (i == 7) {
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

- (void)tutorial {
    
    if (tutnum == 1) {
        newHud = hud1;
        [hud1 removeFromSuperview];
        
        newHud.layer.cornerRadius = 15.0;
        newHud.layer.shadowColor = [UIColor blackColor].CGColor;
        newHud.layer.shadowOpacity = 0.5;
        newHud.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        newHud.layer.shadowRadius = 10.0;
        newHud.alpha = 0;
        
        [self.view addSubview:newHud];
        
        [UIView beginAnimations: @"FadeIn_1" context:nil];
        [UIView setAnimationDuration:4];
        
        newHud.alpha = 0.5;
        
        [UIView commitAnimations];
    }
    if (tutnum == 2) {
        newHud2 = hud2;
        [hud2 removeFromSuperview];
        
        newHud2.layer.cornerRadius = 15.0;
        newHud2.layer.shadowColor = [UIColor blackColor].CGColor;
        newHud2.layer.shadowOpacity = 0.5;
        newHud2.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        newHud2.layer.shadowRadius = 10.0;
        newHud2.alpha = 0;
        
        [self.view addSubview:newHud2];
        ///////////////////
        [UIView beginAnimations: @"FadeOut_1, FadeIn_2" context:nil];
        [UIView setAnimationDuration:4];
        
        newHud.alpha = 0.0;
        newHud2.alpha = 0.5;
        
        [UIView commitAnimations];
        
        [sud setBool:true forKey:@"tutdone"];
    }
    
    tutnum++;
}

- (IBAction)showPicker:(id)sender {
    newPicker = picker;
    [picker removeFromSuperview];
    
    newPicker.layer.cornerRadius = 15.0;
    newPicker.layer.shadowColor = [UIColor blackColor].CGColor;
    newPicker.layer.shadowOpacity = 0.5;
    newPicker.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    newPicker.layer.shadowRadius = 10.0;
    newPicker.alpha = 0;
    
    [self.view addSubview:newPicker];
    ///////////////////
    [UIView beginAnimations: @"FadeOut_2, FadeIn_Picker" context:nil];
    [UIView setAnimationDuration:2.5];
    
    newHud2.alpha = 0.0;
    newPicker.alpha = 0.6;
    iButton.alpha = 0.0;
    arrowButton.alpha = 0.0;
    
    [UIView commitAnimations];
}

// User continues without viewing a horoscope, wants to watch the Earth fade only.
- (IBAction)continueNoHoro:(id)sender {
    [UIView beginAnimations: @"FadeOut_2, NoHoro" context:nil];
    [UIView setAnimationDuration:2.5];
    
    newHud2.alpha = 0.0;
    iButton.alpha = 0.8;
    arrowButton.alpha = 0.0;
    horoText.alpha = 0.0;
    
    [UIView commitAnimations];
}

- (IBAction)selectHoro:(UIButton *)button {
    // Possible horoscope signs
    NSArray *signs = @[ @"Aries", @"Taurus", @"Gemini", @"Cancer", @"Leo", @"Virgo", @"Libra", @"Scorpio", @"Sagittarius", @"Capricorn", @"Aquarius", @"Pisces" ];
    
    // Get sign based on the button's tag in UI
    sign = signs[button.tag-1];
    
    // Save the selected sign for future app launches
    [sud setObject:sign forKey:@"sign"];
    
    NSLog(@"Selected sign: %@", sign);
    
    // Fetch the horoscope and show it
    [self refreshHoro];
    
    // Fade out the picker view and Fade in the buttons/horoscope text
    [UIView beginAnimations: @"FadeOut_Picker, FadeIn_Horo" context:nil];
    [UIView setAnimationDuration:2.5];
    
    picker.alpha = 0.0;
    horoText.alpha = 0.8;
    iButton.alpha = 0.8;
    arrowButton.alpha = 0.8;
    
    [UIView commitAnimations];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end
