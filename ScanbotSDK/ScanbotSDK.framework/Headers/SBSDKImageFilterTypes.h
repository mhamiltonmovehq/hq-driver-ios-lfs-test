//
//  SBSDKImageFilterTypes.h
//  Scanbot SDK
//
//  Created by Sebastian Husche on 09.05.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#ifndef Scanbot_SDK_ImageFilterTypes_h
#define Scanbot_SDK_ImageFilterTypes_h

/**
 The ScanbotSDK image filter types.
 */
typedef enum SBSDKImageFilterType: int {
    
    /** Passthrough filter. Does not alter the image. */
    SBSDKImageFilterTypeNone = 0,
    
    /** Optimizes colors, contrast and brightness. Usecase: photos. */
    SBSDKImageFilterTypeColor = 1,
    
    /** Standard grayscale filter. Creates a grayscaled 8-bit image. */
    SBSDKImageFilterTypeGray = 2,
    
    /** Standard binarization filter with contrast optimization.
     Creates a grayscaled 8-bit image with mostly black or white pixels.
     Usecase: Preparation for optical character recognition.
     */
    SBSDKImageFilterTypeBinarized = 3,
    
    /** Fixes white-balance and cleans up the background.
     Usecase: images of paper documents. */
    SBSDKImageFilterTypeColorDocument = 4,

    /** A filter for binarizing an image. Creates an 8-bit image with pixel
     values set to eiter 0 or 255.
     Usecase: Preparation for optical character recognition.
     */
    SBSDKImageFilterTypePureBinarized = 11,
    
    /** Cleans up the background and tries to preserve photos
     within the image. Usecase: magazine pages, flyers. */
    SBSDKImageFilterTypeBackgroundClean = 13,

    /** Black and white filter with background cleaning.
     Creates a grayscaled 8-bit image with mostly black or white pixels.
     Usecase: Textual documents or documents with black and white illustrations.
     */
    SBSDKImageFilterTypeBlackAndWhite = 14
} SBSDKImageFilterType;

#endif
