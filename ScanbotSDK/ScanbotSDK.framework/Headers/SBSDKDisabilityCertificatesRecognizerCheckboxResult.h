//
//  SBSDKDisabilityCertificateRecognizerCheckboxResult.h
//  ScanbotSDKBeta
//
//  Created by Andrew Petrus on 14.11.17.
//  Copyright © 2017 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Type classifiers for checkboxes recognized on disability certificates.
 */
typedef NS_ENUM(NSUInteger, SBSDKDisabilityCertificateRecognizerCheckboxType) {
    /** The checkbox states if the cerfiticate is an initial certificate. */
    SBSDKDisabilityCertificateRecognizerCheckboxTypeInitialCertificate,
    
    /** The checkbox states if the cerfiticate is a renewed certificate. */
    SBSDKDisabilityCertificateRecognizerCheckboxTypeRenewedCertificate,
  
    /** The checkbox states if the cerfiticate is about a work accident. */
    SBSDKDisabilityCertificateRecognizerCheckboxTypeWorkAccident,
    
    /** The checkbox states if the cerfiticate is assigned to an accident insurance doctor. */
    SBSDKDisabilityCertificateRecognizerCheckboxTypeAssignedToAccidentInsuranceDoctor,
    
    /** The checkbox could not be classified. */
    SBSDKDisabilityCertificateRecognizerCheckboxTypeUndefined
};

/**
 * Contains information about recognized Disability certificate checkbox.
 */
@interface SBSDKDisabilityCertificatesRecognizerCheckboxResult : NSObject

/** The type of the checkbox. */
@property (nonatomic) SBSDKDisabilityCertificateRecognizerCheckboxType type;

/** Wheather the checkbox is checked or not. */
@property (nonatomic) BOOL isChecked;

/** The confidence value of the recognition. */
@property (nonatomic) double confidenceValue;

@end
