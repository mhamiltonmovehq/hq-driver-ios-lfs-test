//
//  SBSDKUIMachineCodeScannerUIConfiguration.h
//  ScanbotSDKBundle
//
//  Created by Yevgeniy Knizhnik on 4/17/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Subconfiguration for user interface of the detector screens for bar codes, QR codes and machine readable zones. */
@interface SBSDKUIMachineCodeScannerUIConfiguration : NSObject

/** Foreground color of the cancel button. */
@property (nonnull, nonatomic, strong) UIColor *topBarButtonsColor;

/** Background color of the top bar. */
@property (nonnull, nonatomic, strong) UIColor *topBarBackgroundColor;

/** Background color of the detection overlay. */
@property (nonnull, nonatomic, strong) UIColor *cameraOverlayColor;

/** Foreground color of the detection overlay. */
@property (nonnull, nonatomic, strong) UIColor *finderLineColor;

/** Width of finde frame border. Default is 2. */
@property (nonatomic) CGFloat finderLineWidth;

/** Width of finder frame. Is limited to superview width. Default is 303. */
@property (nonatomic) CGFloat finderWidth;

/** Height of finder frame. Is limited to either superview height, or ui components, like bars, labels or buttons. Default is 303. */
@property (nonatomic) CGFloat finderHeight;

/** Foreground color of the description label. */
@property (nonnull, nonatomic, strong) UIColor *finderTextHintColor;

/** Foreground color of the flash button when flash is off. */
@property (nonnull, nonatomic, strong) UIColor *bottomButtonsInactiveColor;

/** Foreground color of the flash button when flash is on. */
@property (nonnull, nonatomic, strong) UIColor *bottomButtonsActiveColor;

/** Whether the cancel button is hidden or not. */
@property (nonatomic, assign, getter=isCancelButtonHidden) BOOL cancelButtonHidden;

/** Allowed orientations for automatic interface rotations. **/
@property (nonatomic, assign) UIInterfaceOrientationMask allowedInterfaceOrientations;

@end
