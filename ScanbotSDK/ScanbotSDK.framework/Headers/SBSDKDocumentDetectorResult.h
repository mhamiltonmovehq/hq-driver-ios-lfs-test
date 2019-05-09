//
//  SBSDKDocumentDetectorResult.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 25.04.18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSDKPolygon.h"
#import "SBSDKDocumentDetectionStatus.h"

/**
 * This class represents the result of a document detection on an image.
 */
@interface SBSDKDocumentDetectorResult : NSObject

/** The status of the detection. */
@property(nonatomic, readonly) SBSDKDocumentDetectionStatus status;

/** The detected polygon or nil, if no polygon was detected. */
@property(nonatomic, readonly, nullable) SBSDKPolygon *polygon;

/** The size of the detector input image. For convenience. */
@property(nonatomic, readonly) CGSize detectorImageSize;

@end
