//
//  SBSDKUIPage.h
//  SBSDK Internal Demo
//
//  Created by Yevgeniy Knizhnik on 3/2/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSDKPolygon.h"
#import "SBSDKImageFilterTypes.h"
#import "SBSDKDocumentDetector.h"

/** This class represents a scanned documents page. */
@interface SBSDKUIPage : NSObject

/** The ID of the images in the default 'SBSDKUIPageFileStorage'. */
@property (nonatomic, strong, readonly, nonnull) NSUUID* pageFileUUID;

/** The status of the documents polygon that was detected on the original image. */
@property (nonatomic, readonly) SBSDKDocumentDetectionStatus status;

/** The polygon of the area where the document is located within the pages image. */
@property (nonatomic, strong, nullable) SBSDKPolygon* polygon;

/** The filter of the receiver. */
@property (nonatomic, assign) SBSDKImageFilterType filter;

/** Not available. */
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * Designated initializer. Creates a new page object.
 * @param uuid The ID of the images in the default 'SBSDKUIPageFileStorage'.
 * @param polygon The polygon of the area where the document is located within the pages image.
 * @return A new instance of 'SBSDKUIPage'.
 */
- (nonnull instancetype)initWithPageFileID:(nonnull NSUUID *)uuid
                                   polygon:(nullable SBSDKPolygon *)polygon NS_DESIGNATED_INITIALIZER;

/**
 * Designated initializer. Creates a new page object.
 * @param uuid The ID of the images in the default 'SBSDKUIPageFileStorage'.
 * @param polygon The polygon of the area where the document is located within the pages image.
 * @param filter The filter to be applied to the page.
 * @return A new instance of 'SBSDKUIPage'.
 */
- (nonnull instancetype)initWithPageFileID:(nonnull NSUUID *)uuid
                                   polygon:(nullable SBSDKPolygon *)polygon
                                    filter:(SBSDKImageFilterType)filter NS_DESIGNATED_INITIALIZER;
/**
 * Designated initializer. Creates a new page object.
 * @param image The image used as original image.
 * @param polygon The polygon of the area where the document is located within the pages image.
 * @param filter The filter to be applied to the page.
 * @return A new instance of 'SBSDKUIPage'.
 */
- (nonnull instancetype)initWithImage:(nonnull UIImage *)image
                              polygon:(nullable SBSDKPolygon *)polygon
                               filter:(SBSDKImageFilterType)filter NS_DESIGNATED_INITIALIZER;

/**
 * Rotates the receiver clockwise.
 * @param times The number of 90 degree clockwise rotations. Negative values will rotate counter clockwise.
 * @return YES, if the operation was successful, NO otherwise.
 */
- (BOOL)rotateClockwise:(NSInteger)times;


/**
 * Detects the documents polygon on the original image of the receiver.
 * @param applyPolygonIfOkay If set to YES, the detected polygon will be applied to the receiver if its detection status
 * is 'SBSDKDocumentDetectionStatusOK'.
 * @return The document detector result describing the location of the detected document
 * in the image and the status of the detection,
 * or nil, if no document was detected.
 */
- (nullable SBSDKDocumentDetectorResult *)detectDocument:(BOOL)applyPolygonIfOkay;


/** The URL of the original image including any applied rotations. */
- (NSURL *_Nullable)originalImageURL;

/** An UIImage of the original image including any applied rotations. */
- (UIImage *_Nullable)originalImage;

/** An UIImage of the original image including any applied rotations in a resolution matching the devices screen. */
- (UIImage *_Nullable)originalPreviewImage;



/** The URL of the unfiltered document image including applied rotations and polygon. */
- (NSURL *_Nullable)unfilteredDocumentImageURL;

/** An UIImage of the unfiltered document image including applied rotations and polygon. */
- (UIImage *_Nullable)unfilteredDocumentImage;

/**
 * The URL of the unfiltered document image including applied rotations and polygon in a
 * resolution matching the devices screen.
 */
- (NSURL *_Nullable)unfilteredDocumentPreviewImageURL;

/**
 * An UIImage of the unfiltered document image including applied rotations and polygon in a
 * resolution matching the devices screen.
 */
- (UIImage *_Nullable)unfilteredDocumentPreviewImage;



/** The URL of the document image including applied rotations, filter and polygon. */
- (NSURL *_Nullable)documentImageURL;

/** An UIImage of the document image including applied rotations, filter and polygon. */
- (UIImage *_Nullable)documentImage;

/**
 * The URL of the document image including applied rotations, filter and polygon in a
 * resolution matching the devices screen.
 */
- (NSURL *_Nullable)documentPreviewImageURL;

/**
 * An UIImage of the document image including applied rotations, filter and polygon in a
 * resolution matching the devices screen.
 */
- (UIImage *_Nullable)documentPreviewImage;

/**
 * A preview UIImage of the document image including applied rotations, polygon and the given filter in a
 * resolution matching the devices screen.
 */
- (UIImage *_Nullable)documentPreviewImageUsingFilter:(SBSDKImageFilterType)filter;

/**
 * The URL of a preview UIImage of the document image including applied rotations, polygon and the given filter in a
 * resolution matching the devices screen.
 */
- (NSURL *_Nullable)documentPreviewImageURLUsingFilter:(SBSDKImageFilterType)filter;

@end
