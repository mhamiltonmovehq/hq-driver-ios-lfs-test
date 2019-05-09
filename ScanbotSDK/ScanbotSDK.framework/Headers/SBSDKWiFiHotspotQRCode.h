//
//  SBSDKWiFiHotspotQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR code containing information
 * about a WiFi hotspot (WIFI:).
 */
@interface SBSDKWiFiHotspotQRCode : SBSDKMachineReadableCode

/**
 * The SSID of the WIFI.
 */
@property(nonatomic, copy) NSString *SSID;

/**
 * The password of the WIFI. Might be nil or empty.
 */
@property(nonatomic, copy) NSString *password;

/**
 * The authentication type of the WIFI ("WEP", "WPA" or None). Is nil if not WEP or WPA.
 */
@property(nonatomic, copy) NSString *authenticationType;

/**
 * Whether the WIFIs SSID is hidden or not.
 */
@property(nonatomic, assign, getter = hasHiddenSSID) BOOL hiddenSSID;

@end
