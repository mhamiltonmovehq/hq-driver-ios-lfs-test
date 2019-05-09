//
//  SBSDKDisabilityCertificatesRecognizerResult.h
//  ScanbotSDKBeta
//
//  Created by Andrew Petrus on 14.11.17.
//  Copyright © 2017 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBSDKDisabilityCertificatesRecognizerCheckboxResult.h"
#import "SBSDKDisabilityCertificatesRecognizerDateResult.h"

/**
 * Class contains disability certificates recognizer retrieved information.
 */
@interface SBSDKDisabilityCertificatesRecognizerResult : NSObject

/** Array of found checkboxes */
@property (nonatomic, strong) NSArray<SBSDKDisabilityCertificatesRecognizerCheckboxResult *> *checkboxes;

/** Array of found dates */
@property (nonatomic, strong) NSArray<SBSDKDisabilityCertificatesRecognizerDateResult *> *dates;

/** Defines whether recognition was successful */
@property (nonatomic) BOOL recognitionSuccessful;

/** Internal property, do not use. */
@property (nonatomic, strong) UIImage* debugImage;

/** Human readable string representation of contained information */
- (NSString *)stringRepresentation;

@end
