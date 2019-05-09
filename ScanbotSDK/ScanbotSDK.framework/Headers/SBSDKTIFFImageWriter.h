//
//  SBSDKTIFFImageWriter.h
//  ScanbotSDK
//
//  Created by Andrew Petrus on 08.02.18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Class used to convert and write images in TIFF format
 */
@interface SBSDKTIFFImageWriter : NSObject

/**
 * Write single-page TIFF file
 * @param image The source image from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeTIFF:(UIImage *)image
          fileURL:(NSURL *)fileURL;

/**
 * Write binarized single-page TIFF file
 * @param image The source image from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeBinarizedTIFF:(UIImage *)image
                   fileURL:(NSURL *)fileURL;

/**
 * Write single-page TIFF file
 * @param imageURL The source image URL from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeTIFFFromURL:(NSURL *)imageURL
                 fileURL:(NSURL *)fileURL;

/**
 * Write binarized single-page TIFF file
 * @param imageURL The source image URL from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeBinarizedTIFFFromURL:(NSURL *)imageURL
                          fileURL:(NSURL *)fileURL;

/**
 * Write multi-page TIFF file
 * @param images The array of source images from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeMultiPageTIFF:(NSArray<UIImage *> *)images
                   fileURL:(NSURL *)fileURL;

/**
 * Write binarized multi-page TIFF file
 * @param images The array of source images from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeBinarizedMultiPageTIFF:(NSArray<UIImage *> *)images
                            fileURL:(NSURL *)fileURL;

/**
 * Write multi-page TIFF file
 * @param imageURLs The array of source image URLs from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeMultiPageTIFFFromImageURLs:(NSArray<NSURL *> *)imageURLs
                                fileURL:(NSURL *)fileURL;


/**
 * Write binarized multi-page TIFF file
 * @param imageURLs The array of source images URLs from what TIFF file is to be created.
 * @param fileURL File URL for newly created TIFF file
 * @return Operation result. YES if file created and saved successfuly, NO otherwise.
 */
+ (BOOL)writeBinarizedMultiPageTIFFFromImageURLs:(NSArray<NSURL *> *)imageURLs
                                         fileURL:(NSURL *)fileURL;

@end
