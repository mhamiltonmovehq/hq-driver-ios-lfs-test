//
//  SBSDKUIDocumentScannerUIConfiguration.h
//  SBSDK Internal Demo
//
//  Created by Yevgeniy Knizhnik on 3/1/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Subconfiguration for user interface of the document scanning screen. */
@interface SBSDKUIDocumentScannerUIConfiguration : NSObject

/** Background color of the top bar. */
@property (nonnull, nonatomic, strong) UIColor *topBarBackgroundColor;

/** Foreground color of disabled items in the top bar. */
@property (nonnull, nonatomic, strong) UIColor *topBarButtonsInactiveColor;

/** Foreground color of enabled items in the top bar. */
@property (nonnull, nonatomic, strong) UIColor *topBarButtonsActiveColor;

/** Whether the multi-page button is hidden or not. */
@property (nonatomic, assign, getter=isMultiPageButtonHidden) BOOL multiPageButtonHidden;

/** Whether the flash button is hidden or not. */
@property (nonatomic, assign, getter=isFlashImageButtonHidden) BOOL flashImageButtonHidden;

/** Whether the cancel button is hidden or not. */
@property (nonatomic, assign, getter=isCancelButtonHidden) BOOL cancelButtonHidden;

/** Whether the auto-snapping button is hidden or not. */
@property (nonatomic, assign, getter=isAutoSnappingButtonHidden) BOOL autoSnappingButtonHidden;

/** Color of the shutter buttons outer ring in auto-capture mode. */
@property (nonnull, nonatomic, strong) UIColor *shutterButtonAutoOuterColor;

/** Color of the shutter buttons inner ring in auto-capture mode. */
@property (nonnull, nonatomic, strong) UIColor *shutterButtonAutoInnerColor;

/** Color of the shutter buttons outer ring in manual-capture mode. */
@property (nonnull, nonatomic, strong) UIColor *shutterButtonManualOuterColor;

/** Color of the shutter buttons inner ring in manual-capture mode. */
@property (nonnull, nonatomic, strong) UIColor *shutterButtonManualInnerColor;

/** Color of the shutter buttons activity indicator when capturing an image. */
@property (nonnull, nonatomic, strong) UIColor *shutterButtonIndicatorColor;

/** Foreground color of the buttons in the bottom bar. **/
@property (nonnull, nonatomic, strong) UIColor *bottomBarButtonsColor;

/** Background color of the bottom bar. **/
@property (nonnull, nonatomic, strong) UIColor *bottomBarBackgroundColor;

/** Background color of the camera view. **/
@property (nonnull, nonatomic, strong) UIColor *cameraBackgroundColor;

/** Foreground color of the detected documents polygon, when the polygons quality is acceptable. **/
@property (nonnull, nonatomic, strong) UIColor *polygonColorOK;

/** Foreground color of the detected documents polygon, when the polygons quality is not acceptable. **/
@property (nonnull, nonatomic, strong) UIColor *polygonColor;

/** Background color of the detected documents polygon, when the polygons quality is acceptable. **/
@property (nonnull, nonatomic, strong) UIColor *polygonBackgroundColorOK;

/** Background color of the detected documents polygon, when the polygons quality is not acceptable. **/
@property (nonnull, nonatomic, strong) UIColor *polygonBackgroundColor;

/** Width of the detected documents polygon in points. */
@property (nonatomic, assign) CGFloat polygonLineWidth;

/** Background color of the user guidance label. */
@property (nonnull, nonatomic, strong) UIColor *userGuidanceBackgroundColor;

/** Foreground/text color of the user guidance label. */
@property (nonnull, nonatomic, strong) UIColor *userGuidanceTextColor;

/** Allowed orientations for automatic interface rotations. **/
@property (nonatomic, assign) UIInterfaceOrientationMask allowedInterfaceOrientations;

@end
