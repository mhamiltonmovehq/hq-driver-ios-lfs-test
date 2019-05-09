//
//  SBSDKContactQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"
#import <Contacts/Contacts.h>

/**
 * A specific subclass of SBSDKMachineReadableCode, that represents a QR code with
 * personal contact information (vCard, MeCard).
 * Upon creation it tries to geocode all contained postal adresses.
 * Before accessing contact property, make sure processing equals 0.
 */
@interface SBSDKContactQRCode : SBSDKMachineReadableCode

/**
 * The contact record generated from the QR codes vCard or MeCard string.
 */
@property(nonatomic, readwrite) CNContact *contact;

/**
 * The display name of the contact. Usually is first name + last name.
 */
@property(nonatomic, copy, readonly) NSString *displayName;

/**
 * The number of addresses currently being geocoded.
 * If value drops to 0 it is safe to use the self.contact. KVO-able.
 */
@property(nonatomic, readonly) NSUInteger processing;

/**
 * Internal helper function to parse adresses from a contact.
 */
+ (NSArray<CNLabeledValue<CNPostalAddress *> *> *)postalAddressesForContact:(CNContact *)contact
                                                additionalAddressDictionary:(NSDictionary *)dictionary
                                                                      label:(NSString *)label;

@end
