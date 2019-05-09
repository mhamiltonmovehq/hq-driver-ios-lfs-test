//
//  SBSDKDisabilityCertificatesRecognizer.h
//  ScanbotSDKBeta
//
//  Created by Andrew Petrus on 14.11.17.
//  Copyright © 2017 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SBSDKDisabilityCertificatesRecognizerResult.h"
#import "SBSDKDisabilityCertificatesRecognizerDateResult.h"
#import "SBSDKDisabilityCertificatesRecognizerCheckboxResult.h"

/**
 * Wrapper class for disability certificates recognition. Recognition is performed on still UIImage or SampleBufferRef,
 * result is incapsulated in SBSDKDisabilityCertificatesRecognizerResult instance.
 */
@interface SBSDKDisabilityCertificatesRecognizer : NSObject

/**
 * Acquire all available information from UIImage instance
 * @param image The image with detected paper.
 * @return Recognizer result.
 */
- (nullable SBSDKDisabilityCertificatesRecognizerResult *)recognizeFromImage:(nonnull UIImage *)image;

/**
 * Acquire all available information from sample buffer reference
 * @param sampleBufferRef The sample buffer reference containing detected paper.
 * @return Recognizer result.
 */
- (nullable SBSDKDisabilityCertificatesRecognizerResult *)recognizeFromSampleBuffer:(nonnull CMSampleBufferRef)sampleBufferRef
                                                                        orientation:(AVCaptureVideoOrientation)videoOrientation;

@end
