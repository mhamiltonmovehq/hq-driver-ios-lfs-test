//
//  SBSDKUICroppingScreenConfiguration.h
//  ScanbotSDKBundle
//
//  Created by Yevgeniy Knizhnik on 4/6/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSDKUICroppingScreenTextConfiguration.h"
#import "SBSDKUICroppingScreenUIConfiguration.h"

/**
 * This class describes the look and feel, as well as the textual contents of the page cropping screen.
 * Use the 'defaultConfiguration' class method to retrieve an instance and modify it.
 */
@interface SBSDKUICroppingScreenConfiguration : NSObject

/** Not available. */
- (nonnull instancetype)init NS_UNAVAILABLE;

/** Not available. */
+ (nonnull instancetype)new NS_UNAVAILABLE;

/**
 * Designated initializer. Creates a new instance of 'SBSDKUICroppingScreenConfiguration' and returns it.
 * @param uiConfiguration A subconfiguration for the user interface. Defines colors and sizes.
 * @param textConfiguration A subconfiguration for text being displayed in the page review screen.
 */
- (nonnull instancetype)initWithUIConfiguration:(nonnull SBSDKUICroppingScreenUIConfiguration *)uiConfiguration
                              textConfiguration:(nonnull SBSDKUICroppingScreenTextConfiguration *)textConfiguration
                              NS_DESIGNATED_INITIALIZER;

/**
 * The default configuration.
 * @return A mutable instance of 'SBSDKUICroppingScreenConfiguration' with default values.
 */
+ (nonnull SBSDKUICroppingScreenConfiguration *)defaultConfiguration;

/** The user interface subconfiguration. */
@property (nonnull, nonatomic, strong, readonly) SBSDKUICroppingScreenUIConfiguration *uiConfiguration;

/** The subconfiguration for displayed texts. */
@property (nonnull, nonatomic, strong, readonly) SBSDKUICroppingScreenTextConfiguration *textConfiguration;

@end
