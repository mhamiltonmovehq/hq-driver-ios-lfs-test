//
//  SBSDKOrientationLock.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 4/30/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#ifndef SBSDKOrientationLock_h
#define SBSDKOrientationLock_h

/**
 * This enum describes the available orentiation lock modes for image capturing.
 * All modes work independently from the user interface orientation.
 */
typedef NS_ENUM(NSInteger, SBSDKOrientationLock) {
    
    /**
     * The orientation is not locked. The captured image is oriented according to the current device orientation.
     * The image either has a landscape or portrait aspect ratio.
     */
    SBSDKOrientationLockNone = 0,
    
    /**
     * The orientation is locked to portrait. The captured image is orientated so that the
     * upper area of the image is directed towards the devices camera (top edge). The image always
     * has a portrait aspect ratio.
     */
    SBSDKOrientationLockPortrait = 1,
    
    /**
     * The orientation is locked to portrait upside down. The captured image is orientated so that the
     * upper area of the image is directed towards the devices home button (bottom edge). The image always
     * has a portrait aspect ratio.
     */
    SBSDKOrientationLockPortraitUpsideDown = 2,
    
    /**
     * The orientation is locked to landscape left. The captured image is orientated so that the
     * left area of the image is directed towards the devices camera (top edge). The image always
     * has a landscape aspect ratio.
     */
    SBSDKOrientationLockLandscapeLeft = 3,
    
    /**
     * The orientation is locked to landscape right. The captured image is orientated so that the
     * left area of the image is directed towards the devices home button (bottom edge). The image always
     * has a landscape aspect ratio.
     */
    SBSDKOrientationLockLandscapeRight = 4
};

#endif /* SBSDKOrientationLock_h */
