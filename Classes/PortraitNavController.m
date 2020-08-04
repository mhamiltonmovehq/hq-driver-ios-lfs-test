//
//  PortraitNavController.m
//
//  Created by Tony Brame on 10/22/12.
//
//

#import "PortraitNavController.h"

@interface PortraitNavController ()

@end

@implementation PortraitNavController
@synthesize dismissDelegate, dismissCallback;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(BOOL)shouldAutorotate
{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTranslucent:NO];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (dismissDelegate != nil && [dismissDelegate respondsToSelector:dismissCallback]) {
        [dismissDelegate performSelectorOnMainThread:dismissCallback withObject:nil waitUntilDone:NO];
    }
    [super dismissViewControllerAnimated:flag completion:completion];
}



@end
