//
//  SBSDKUIDocumentScannerConfiguration.h
//  SBSDK Internal Demo
//
//  Created by Yevgeniy Knizhnik on 3/1/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSDKUIDocumentScannerUIConfiguration.h"
#import "SBSDKUIDocumentScannerTextConfiguration.h"
#import "SBSDKUIDocumentScannerBehaviorConfiguration.h"

/**
 * This class describes the look and feel, the behavior, as well as the textual contents of the detection
 * screen for documents.
 * Use the 'defaultConfiguration' class method to retrieve an instance and modify it.
 */
@interface SBSDKUIDocumentScannerConfiguration : NSObject

/** Not available. */
- (nonnull instancetype)init NS_UNAVAILABLE;

/** Not available. */
+ (nonnull instancetype)new NS_UNAVAILABLE;

/**
 * Designated initializer. Creates a new instance of 'SBSDKUIDocumentScannerConfiguration' and returns it.
 * @param uiConfiguration A subconfiguration for the user interface. Defines colors and sizes.
 * @param textConfiguration A subconfiguration for text being displayed in the document scanning screen.
 * @param behaviorConfiguration A subconfiguration for defining the behavior of the document scanning screen.
 */
- (nonnull instancetype)initWithUIConfiguration:(nonnull SBSDKUIDocumentScannerUIConfiguration *)uiConfiguration
                              textConfiguration:(nonnull SBSDKUIDocumentScannerTextConfiguration *)textConfiguration
                         behaviorConfiguration:(nonnull SBSDKUIDocumentScannerBehaviorConfiguration *)behaviorConfiguration
                        NS_DESIGNATED_INITIALIZER;

/**
 * The default configuration.
 * @return A mutable instance of 'SBSDKUIDocumentScannerConfiguration' with default values.
 */
+ (nonnull SBSDKUIDocumentScannerConfiguration *)defaultConfiguration;

/** The user interface subconfiguration. */
@property (nonnull, nonatomic, strong, readonly) SBSDKUIDocumentScannerUIConfiguration *uiConfiguration;

/** The subconfiguration for displayed texts. */
@property (nonnull, nonatomic, strong, readonly) SBSDKUIDocumentScannerTextConfiguration *textConfiguration;

/** The subconfiguration controlling the scanning screens behavior. */
@property (nonnull, nonatomic, strong, readonly) SBSDKUIDocumentScannerBehaviorConfiguration *behaviorConfiguration;

@end
