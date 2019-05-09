//
//  SBSDKUICroppingScreenTextConfiguration.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 4/17/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Subconfiguration for the textual content of the page cropping screen. */
@interface SBSDKUICroppingScreenTextConfiguration : NSObject

/** String being displayed on the rotate button. */
@property (nullable, nonatomic, strong) NSString *rotateButtonTitle;

/** String being displayed on the detect button. */
@property (nullable, nonatomic, strong) NSString *detectButtonTitle;

/** String being displayed on the reset button. */
@property (nullable, nonatomic, strong) NSString *resetButtonTitle;

/** String being displayed on the cancel button. */
@property (nullable, nonatomic, strong) NSString *cancelButtonTitle;

/** String being displayed on the done button. */
@property (nullable, nonatomic, strong) NSString *doneButtonTitle;

/** String being displayed as the title on the top bar. */
@property (nullable, nonatomic, strong) NSString *topBarTitle;

@end
