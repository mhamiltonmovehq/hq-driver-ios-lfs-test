//
//  SBSDKMachineReadableZoneRecognizerField.h
//  ScanbotSDK
//
//  Created by Andrew Petrus on 20.03.18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Type classifiers for machine-readable-zone fields.
 */
typedef NS_ENUM(NSUInteger, SBSDKMachineReadableZoneRecognizerFieldName) {
    
    /** Unclassified field. **/
    SBSDKMachineReadableZoneRecognizerFieldNameUnknown = 0,
    
    /** The field describes a document code. **/
    SBSDKMachineReadableZoneRecognizerFieldNameDocumentCode = 1,

    /** The field describes the issuing state or organization. **/
    SBSDKMachineReadableZoneRecognizerFieldNameIssuingStateOrOrganization = 2,

    /** The field describes the issuing department. **/
    SBSDKMachineReadableZoneRecognizerFieldNameDepartmentOfIssuance = 3,
    
    /** The field describes the first name. **/
    SBSDKMachineReadableZoneRecognizerFieldNameFirstName = 4,

    /** The field describes the last name. **/
    SBSDKMachineReadableZoneRecognizerFieldNameLastName = 5,
    
    /** The field describes the nationality. **/
    SBSDKMachineReadableZoneRecognizerFieldNameNationality = 6,
    
    /** The field describes the birth date. **/
    SBSDKMachineReadableZoneRecognizerFieldNameDateOfBirth = 7,
    
    /** The field describes the gender. **/
    SBSDKMachineReadableZoneRecognizerFieldNameGender = 8,
    
    /** The field describes the expiration date. **/
    SBSDKMachineReadableZoneRecognizerFieldNameDateOfExpiry = 9,

    /** The field describes the personal number. **/
    SBSDKMachineReadableZoneRecognizerFieldNamePersonalNumber = 10,
    
    /** The field describes the documents type. **/
    SBSDKMachineReadableZoneRecognizerFieldNameTravelDocumentType = 11,
    
    /** Field for optional value #1. **/
    SBSDKMachineReadableZoneRecognizerFieldNameOptional1 = 12,

    /** Field for optional value #2. **/
    SBSDKMachineReadableZoneRecognizerFieldNameOptional2 = 13,
    
    /** The field describes the discreet issuing state or organization. **/
    SBSDKMachineReadableZoneRecognizerFieldNameDiscreetIssuingStateOrOrganization = 14
};

/**
 A class representing a single data field in a machine-readable-zone.
 */
@interface SBSDKMachineReadableZoneRecognizerField : NSObject

/** The type of the field. */
@property (nonatomic) SBSDKMachineReadableZoneRecognizerFieldName fieldName;

/** The value of the field. */
@property (nonatomic, strong) NSString *value;

/** The recognition confidence value of the field. */
@property (nonatomic) double averageRecognitionConfidence;

@end
