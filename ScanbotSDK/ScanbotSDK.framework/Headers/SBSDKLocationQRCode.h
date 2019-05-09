//
//  SBSDKLocationQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code with a geographic locations (geo:).
 * Performs reverse geocoding to get address from longitude and latitude.
 */
@interface SBSDKLocationQRCode : SBSDKMachineReadableCode <MKAnnotation>

/**
 Designated initializer.
 @param metadata The machine readable code metadata to create the instance from.
 @param location The CLLocation extracted from the QR code.
 */
- (instancetype)initWithMetadata:(SBSDKMachineReadableCodeMetadata *)metadata location:(CLLocation *)location;

/**
 * The location.
 */
@property(nonatomic, readonly, strong) CLLocation *location;

/**
 * Placemark object, valid after geocoding finished.
 */
@property(nonatomic, readonly, strong) CLPlacemark *placemark;

/**
 * Whether the receiver still performs geocoding or not. KVO-able.
 */
@property(nonatomic, readonly, getter = isGeocoding) BOOL geocoding;

@end
