//
//  PVOBaseViewController.m
//  Survey
//
//  Created by Justin Little on 11/10/15.
//
//

#import "PVOBaseViewController.h"

@interface PVOBaseViewController ()

@end

@implementation PVOBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _viewHasAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewHasAppeared = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    _viewHasAppeared = NO;
    _forceLaunchAddPopup = NO;
    [super viewDidDisappear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/*
 This is a method i added for force touch shortcuts from the home screen. I didn't want users creating a new customer from the home screen and losing data on screens where data needs saved.
 For example user is on the PVOItemDetailController, goes back to the home screen, force touches the app icon to create new customer, then the app leaves the PVOItemDetailController and data is lost.
 */
- (BOOL)viewHasCriticalDataToSave
{
    return NO;
}

@end
