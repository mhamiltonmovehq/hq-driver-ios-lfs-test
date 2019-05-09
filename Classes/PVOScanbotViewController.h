//
//  PVOScanbotViewController.h
//  Survey
//
//  Created by Brian Prescott on 9/19/17.
//
//

#import <UIKit/UIKit.h>

#if defined(ATLASNET)
#import <ScanbotSDK/SBSDKScanbotSDK.h>
#endif
#import "CNPPopupController.h"

@protocol PVOScanbotViewControllerDelegate < NSObject >

- (void)documentImageCaptured:(UIImage *)documentImage;
- (void)documentImageCancelled;

@end

@interface PVOScanbotViewController : UIViewController < SBSDKScannerViewControllerDelegate, CNPPopupControllerDelegate, UIScrollViewDelegate >
{
}

@property (nonatomic, assign) id < PVOScanbotViewControllerDelegate > delegate;

@end
