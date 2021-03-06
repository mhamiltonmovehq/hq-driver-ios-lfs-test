//
//  SBSDKImageStorage.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 16.06.15.
//  Copyright (c) 2015 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBSDKImageStoring.h"

/**
 * A thread-safe mutable ordered collection of disk-backed UIImage objects.
 * When it comes to image processing with large images it is impossible to hold all the of a collection images in memory.
 * The images have to be backed on disk and reloaded from the file when demanded.
 * This class is a simple wrapper around the described technique. You can add/remove images from the storage,
 * access the storage via an index and retrieve images or image URLs.
 * There is also support for (automatically) creating and caching thumbnails from the storages images.
 * Conforms to NSCopying. When copying the disk-backing-storage is also copied to a different physical location.
 * Accessing the storage and changing properties is implemented with thread-safety using
 * a single-writer/multiple-reader pattern.
 *
 * The deallocation of this object removes all images from disk.
 *
 * Deprecated! Use `SBSDKIndexedImageStorage` instead!
 *
 */

__attribute__((deprecated("Please use SBSDKIndexImageStorage.")))
@interface SBSDKImageStorage : NSObject

/** The number of images contained in the receiver. */
@property (nonatomic, readonly) NSUInteger imageCount;

/** An array of file URLs of all images the receiver holds. */
@property (nonatomic, readonly, nonnull) NSArray<NSURL *> *imageURLs;

/** Enables or disables the automatic thumbnail creation. Disabled by default. */
@property (atomic, assign, getter = isAutomaticThumbnailCreationEnabled) BOOL enableAutomaticThumbnailCreation;

/** The size of the thumbnails generated by the automatic thumbnail creation. Defaults to the size of the main screen. */
@property (atomic, assign) CGSize automaticThumbnailSize;

/**
 * The JPEG compression quality factor of the stored images.
 * Ranges from 0.0 (small files, bad quality) to 1.0 (huge files, great quality). Defaults to 0.9.
 */
@property (nonatomic, assign) CGFloat imageQuality;

/** Returns the URL of the applications 'Documents' folder. */
+ (nonnull NSURL *)applicationDocumentsFolderURL;

/** Returns the URL of the applications support folder. */
+ (nonnull NSURL *)applicationSupportFolderURL;

/**
 * Convenience initializer. Creates a temporary image storage at a temporary folder.
 * @param images An array of UIImage objects that should be added to the newly create instance image storage.
 * Can be nil or empty.
 * @return Initialized image storage.
 */
+ (nonnull instancetype)temporaryStorageWithImages:(nonnull NSArray<UIImage *> *)images;

/**
 * Designated initializer. Creates an image storage in the folder specified by  folderURL.
 * @param folderURL An NSURL describing the location of the image storage folder on the disk, if it's nil temp path will be used
 * @return Initialized image storage.
 */
- (nonnull instancetype)initWithFolderURL:(nullable NSURL *)folderURL;

/**
 * Appends a single UIImage to the receiver.
 * @param image The UIImage object to be added.
 * @return YES if the operation was successful, NO otherwise.
 */
- (BOOL)addImage:(nullable UIImage *)image;

/**
 * Appends a single image from the URL to the receiver.
 * @param url The URL to the image to be added.
 * @return YES if the operation was successful, NO otherwise.
 */
- (BOOL)addImageFromURL:(nullable NSURL *)url;

/**
 * Removes the image at the given index from the receiver and deletes the image file.
 * @param index The index of the image to be deleted from the receiver. Does nothing if the index is not valid.
 */
- (void)removeImageAtIndex:(NSUInteger)index;

/**
 * Loads the UIImage at the given index from the receiver and returns it.
 * @param index The index of the image to be loaded from the receiver.
 * @return The loaded image or nil if the index was not valid.
 */
- (nullable UIImage *)imageAtIndex:(NSUInteger)index;

/**
 * Returns the images file URL at the given index.
 * Use with caution: if the receiver is deallocated the URL will be invalid.
 * @param index The index of the image in the receiver.
 * @return The file URL the image is physically located at. Or nil if index is invalid.
 */
- (nullable NSURL *)imageURLAtIndex:(NSUInteger)index;

/** Empties the receiver by removing all images from it, including the image files. */
- (void)removeAllImages;

/**
 * Generates a thumbnail of the image at the specified index with given size. The thumbnail is cached.
 * @param index The index of the image in the receiver.
 * @param size The size of the thumbnail. If size has a different aspect ratio than the image the thumbnail is fitted-in
 * the requested size.
 * @return An UIImage object representing the thumbnail.
 */
- (nullable UIImage *)thumbnailForImageAtIndex:(NSUInteger)index ofSize:(CGSize)size;

/**
 * Loads the UIImage at the given key from the receiver and returns it.
 * @param key The dictionary key of the image to be loaded from the receiver.
 * @return The loaded image or nil if for the key no image is available.
 */
- (nullable UIImage *)imageForKey:(nonnull NSString *)key;

/**
 * Adds an UIImage to the receiver.
 * @param image The UIImage object to be added. Passing nil removes the existing image for the given key.
 * @param key The dictionary key of the image to be added to the receiver.
 */
- (void)setImage:(nullable UIImage *)image forKey:(nonnull NSString *)key;

/**
 * Sets a single image from the URL to the receiver.
 * @param url The URL to the image to be added.
 * @param key The dictionary key of the image to be added to the receiver.
 * @param move If YES, the file is moved from the source location, otherwise copied.
 */
- (void)setImageFromURL:(nullable NSURL *)url forKey:(nonnull NSString *)key moveFile:(BOOL)move;

/**
 * Returns the images file URL at the given key.
 * Use with caution: if the receiver is deallocated the URL will be invalid.
 * @param key The key of the image in the receivers image dictionary.
 * @return The file URL the image is physically located at. Or nil if index is invalid.
 */
- (nullable NSURL *)imageURLForKey:(nonnull NSString *)key;

/**
 * Generates a thumbnail of the image at the specified key with given size. The thumbnail is cached.
 * @param key The key of the image in the receivers image dictionary.
 * @param size The size of the thumbnail. If size has a different aspect ratio than the image the thumbnail is fitted-in
 * the requested size.
 * @return An UIImage object representing the thumbnail or nil if no image is present for the given key.
 */
- (nullable UIImage *)thumbnailOfImageForKey:(nonnull NSString *)key ofSize:(CGSize)size;

/**
 * Removes the image at the given key from the receiver and deletes the image file.
 * @param key The key of the image in the receivers image dictionary.
 */
- (void)removeImageForKey:(nonnull NSString *)key;

/**
 * Waits, until all changes to written to disk.
*/
- (void)waitUntilWritingCompleted;

/**
 * Takes an NSIndexSet of indices into the receiver and returns a validated NSIndexSet by removing all invalid indices.
 * @param indexSet The NSIndexSet to validate. If nil or empty all valid indices are added to the result.
 * @return The validated index set.
 */
- (nonnull NSIndexSet *)validatedIndexSetForIndexSet:(nonnull NSIndexSet *)indexSet;

@end
