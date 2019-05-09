//
//  SBSDKUIVideoContentMode.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 4/18/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#ifndef SBSDKUIVideoContentMode_h
#define SBSDKUIVideoContentMode_h

/** Enumeration of video preview content mode. */
typedef NS_ENUM(NSInteger, SBSDKUIVideoContentMode) {
    /**
     * The video layers content is filled into the video layer.
     * No visible borders. Video may be cropped to the visible screen area.
     */
    SBSDKUIVideoContentModeFillIn,
    
    /**
     * The video layers content is fit into the video layer.
     * Video may have visible borders. Video is fully visible within the screen.
     */
    SBSDKUIVideoContentModeFitIn
};

#endif /* SBSDKUIVideoContentMode_h */
