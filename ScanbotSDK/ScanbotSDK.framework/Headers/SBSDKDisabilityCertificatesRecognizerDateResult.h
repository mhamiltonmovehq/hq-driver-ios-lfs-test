//
//  SBSDKDisabilityCertificatesRecognizerDateResult.h
//  ScanbotSDK
//
//  Created by Andrew Petrus on 15.11.17.
//  Copyright © 2017 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Type classifiers for dates recognized on disability certificates.
 */
typedef NS_ENUM(NSUInteger, SBSDKDisabilityCertificatesRecognizerDateResultType) {
	/** The date describes since when the employee is incapable of work. */
    SBSDKDisabilityCertificateRecognizerDateResultTypeIncapableOfWorkSince,
	
    /** The date describes until when the employee is incapable of work. */
    SBSDKDisabilityCertificateRecognizerDateResultTypeIncapableOfWorkUntil,
	
    /** The date describes the day of diagnosis. */
    SBSDKDisabilityCertificateRecognizerDateResultTypeDiagnosedOn,
	
    /** The date could not be classified. */
    SBSDKDisabilityCertificateRecognizerDateResultTypeUndefined
};

/**
 * Class contains date information retrieved by disability certificates recognizer.
 */
@interface SBSDKDisabilityCertificatesRecognizerDateResult : NSObject

/** The string representation of the recognized and validated date. */
@property (nonatomic, strong) NSString *dateString;

/** The type of the date record. */
@property (nonatomic) SBSDKDisabilityCertificatesRecognizerDateResultType dateRecordType;

/** The confidence value of the character recognition. */
@property (nonatomic) double recognitionConfidence;

/** The confidence value of the date validation. */
@property (nonatomic) double validationConfidence;

@end
