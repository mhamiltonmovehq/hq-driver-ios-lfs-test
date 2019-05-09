//
//  MMBaseViewController.h
//  Survey
//
//  Created by Justin Little on 11/10/15.
//
//

#import <UIKit/UIKit.h>

@interface PVOBaseViewController : UIViewController

@property (nonatomic) BOOL quickAddPopupLoaded;
@property (nonatomic) BOOL forceLaunchAddPopup;
@property (nonatomic) BOOL viewHasAppeared;

-(BOOL)viewHasCriticalDataToSave;

@end
