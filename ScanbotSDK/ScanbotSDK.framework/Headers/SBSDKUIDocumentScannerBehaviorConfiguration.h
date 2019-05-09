//
//  SBSDKUIDocumentScannerBehaviorConfiguration.h
//  SBSDK Internal Demo
//
//  Created by Yevgeniy Knizhnik on 3/1/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSDKImageFileFormat.h"
#import "SBSDKUIVideoContentMode.h"
#import "SBSDKOrientationLock.h"

/** Subconfiguration for the behavior of the document scanning screen. */
@interface SBSDKUIDocumentScannerBehaviorConfiguration : NSObject

/** Whether auto-snapping is enabled or not. */
@property (nonatomic, assign, getter=isAutoSnappingEnabled) BOOL autoSnappingEnabled;

/** Whether multi-page snapping is enabled or not. */
@property (nonatomic, assign, getter=isMultiPageEnabled) BOOL multiPageEnabled;

/** Whether flash is toggled on or off. */
@property (nonatomic, assign, getter=isFlashEnabled) BOOL flashEnabled;

/** The scaling factor for captured images. Values are clamped to the range 0.0 - 1.0. */
@property (nonatomic, assign) CGFloat imageScale;

/**
 * The sensivity of auto-snapping. Values are clamped to the range 0.0 - 1.0.
 * A value of 1.0 triggers automatic snapping immediately, a value of 0.0 delays the automatic by 3 seconds.
 */
@property (nonatomic, assign) CGFloat autoSnappingSensitivity;

/**
 * The minimum score in percent (0 - 100) of the perspective distortion to accept a detected document.
 * Default is 75.0. Set lower values to accept more perspective distortion.
 * Warning: Lower values result in more blurred document images.
 */
@property(nonatomic, assign) double acceptedAngleScore;

/**
 * The minimum size in percent (0 - 100) of the screen size to accept a detected document.
 * It is sufficient that height or width match the score. Default is 80.0.
 * Warning: Lower values result in low resolution document images.
 */
@property(nonatomic, assign) double acceptedSizeScore;

/** The video layers content mode. */
@property (nonatomic) SBSDKUIVideoContentMode cameraPreviewMode;

/** The preferred orientation of captured images. */
@property (nonatomic) SBSDKOrientationLock orientationLockMode;

/** If set to YES, ignores the aspect ratio warning. */
@property (nonatomic, assign) BOOL ignoreBadAspectRatio;

@end
