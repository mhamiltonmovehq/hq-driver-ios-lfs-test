//
//  SBSDKUIBarcodeScannerViewController.h
//  ScanbotSDKBundle
//
//  Created by Yevgeniy Knizhnik on 3/28/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSDKUIMachineCodeScannerConfiguration.h"
#import "SBSDKMachineReadableCode.h"
#import "SBSDKUIViewController.h"

@class SBSDKUIBarcodeScannerViewController;

/** Delegate protocol for 'SBSDKUIBarcodeScannerViewController'. */
@protocol SBSDKUIBarcodeScannerViewControllerDelegate <SBSDKUIViewControllerDelegate>

/**
 * Informs the delegate that a QR or bar code has been detected.
 * @param viewController The detection view controller that detected the QR or bar code.
 * @param code The detected QR or bar code.
 */
- (void)qrBarcodeDetectionViewController:(nonnull SBSDKUIBarcodeScannerViewController *)viewController
                               didDetect:(nonnull SBSDKMachineReadableCode *)code;

@optional
/**
 * Optional: informs the delegate that the 'SBSDKUICroppingViewController' has been cancelled and dismissed.
 * @param viewController The 'SBSDKUICroppingViewController' that did dismiss.
 */
- (void)qrBarcodeDetectionViewControllerDidCancel:(nonnull SBSDKUIBarcodeScannerViewController *)viewController;
@end

/**
 * A configurable view controller for camera-based detection of QR and bar codes.
 */
@interface SBSDKUIBarcodeScannerViewController : SBSDKUIViewController

/**
 * Creates a new instance of 'SBSDKUIBarcodeScannerViewController' and presents it modally.
 * @param presenter The view controller the new instance should be presented on.
 * @param machineCodeTypes The types of codes to be detected.
 * @param configuration The configuration to define look and feel of the new detection view controller.
 * @param delegate The delegate of the new detection view controller.
 * @return A new instance of 'SBSDKUIBarcodeScannerViewController'.
 */
+ (nonnull instancetype)presentOn:(nonnull UIViewController *)presenter
     withAcceptedMachineCodeTypes:(nullable NSArray<AVMetadataObjectType> *)machineCodeTypes
                    configuration:(nonnull SBSDKUIMachineCodeScannerConfiguration *)configuration
                      andDelegate:(nullable id<SBSDKUIBarcodeScannerViewControllerDelegate>)delegate;

/**
 * Creates a new instance of 'SBSDKUIBarcodeScannerViewController'.
 * @param machineCodeTypes The types of codes to be detected.
 * @param configuration The configuration to define look and feel of the new detection view controller.
 * @param delegate The delegate of the new detection view controller.
 * @return A new instance of 'SBSDKUIBarcodeScannerViewController'.
 */
+ (nonnull instancetype)createNewWithAcceptedMachineCodeTypes:(nullable NSArray<AVMetadataObjectType> *)machineCodeTypes
                                       configuration:(nonnull SBSDKUIMachineCodeScannerConfiguration *)configuration
                                         andDelegate:(nullable id<SBSDKUIBarcodeScannerViewControllerDelegate>)delegate;

/** Enables or disables the QR/bar code detection. */
@property (nonatomic, getter=isRecognitionEnabled) BOOL recognitionEnabled;

/** The receivers delegate. */
@property (nullable, nonatomic, weak) id <SBSDKUIBarcodeScannerViewControllerDelegate> delegate;

@end

