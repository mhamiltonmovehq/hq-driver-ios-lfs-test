//
//  SBSDKKeyedImageStorage.h
//  ScanbotSDK
//
//  Created by Yevgeniy Knizhnik on 4/19/18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSDKImageFileFormat.h"
#import "SBSDKStorageLocation.h"

/**
 * A simple thread-safe multiple-reader-single-writer key-value fashioned disk image cache class.
 * Manages images in a dictionary-like fashion.
 */
@interface SBSDKKeyedImageStorage : NSObject

/** The number of stored images. */
@property (nonatomic, readonly) NSUInteger imageCount;

/** Array of all stored images URLs (values). */
@property (nonatomic, readonly, nonnull) NSArray<NSURL *> *imageURLs;

/** Array of all stored keys. */
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *imageKeys;

/** Image file format to be used to store the managed images. */
@property (nonatomic, readonly) SBSDKImageFileFormat fileFormat;

/** The JPEG compression if JPEG file format is used. Range: 0.0 - 1.0. */
@property (nonatomic, assign) CGFloat jpegCompressionQuality;

/**
 * Initializes a new 'SBSDKKeyedImageStorage' at the given storage location.
 * @param storageLocation The storage location at which the new storage should reside.
 * @return A new 'SBSDKKeyedImageStorage' instance at the given storage location.
 */
- (nullable instancetype)initWithStorageLocation:(nullable SBSDKStorageLocation *)storageLocation;

/**
 * Initializes a new 'SBSDKKeyedImageStorage' at the given storage location with given image file format.
 * @param storageLocation The storage location at which the new storage should reside.
 * @param fileFormat The file format that should be used to store the images.
 * @return A new 'SBSDKKeyedImageStorage' instance at the given storage location.
 */
- (nullable instancetype)initWithStorageLocation:(nullable SBSDKStorageLocation *)storageLocation
                                      fileFormat:(SBSDKImageFileFormat)fileFormat;

/**
 * Stores an image at the given key.
 * @param image The UIImage to be managed by the receiver.
 * @param key The key at which to store the image.
 */
- (void)setImage:(nonnull UIImage *)image forKey:(nonnull NSString *)key;

/**
 * Returns the image file URL for given key.
 * @param key The key at which the requested image was stored.
 * @return A URL in the file system pointing to the image file or nil, if there was no image at that key.
 * Caution: Do not perform any write operations at that URL!
 */
- (nullable NSURL *)imageURLForKey:(nonnull NSString *)key;

/**
 * Returns the image for given key.
 * @param key The key at which the requested image was stored.
 * @return The stored UIImage or nil, if there was no image at that key.
 * Caution: Do not perform any write operations at that URL!
 */
- (nullable UIImage *)imageForKey:(nonnull NSString *)key;

/**
 * Removes the image at the given key from the receiver as well as from the file system.
 * @param key The key for the image that should be removed.
*/
 - (void)removeImageForKey:(nonnull NSString *)key;

/**
 * Removes the images at keys from the receiver as well as from the file system, which keys prefix match the prefix string.
 * @param prefix The prefix of the keys for the images that should be removed.
 */
- (void)removeImagesForKeysMatchingPrefix:(nonnull NSString *)prefix;

/**
 * Removes all stored images from the receiver as well as from the file system.
 */
- (void)removeAllImages;

/**
 * Blocks the current thread until all enqueued writing operations have been finished.
 */
- (void)waitUntilWritingCompleted;

@end
