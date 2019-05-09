//
//  SBSDKUIPDFRenderer.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 21.06.18.
//  Copyright © 2018 doo GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSDKUIDocument.h"
#import "SBSDKPDFRenderer.h"

/**
 * Renders a 'SBSDKUIDocument' into a PDF.
 */
@interface SBSDKUIPDFRenderer : NSObject

/**
 * Renders the document into a PDF at the specified file url.
 * @param document The document to be rendered as a PDF document.
 * @param pageSize The size of the pages in the PDF document.
 * @param pdfOutputURL The file URL where the PDF document is saved at.
 * @return An NSError if the operation failed, nil otherwise.
 */
+ (nullable NSError *)renderDocument:(nonnull SBSDKUIDocument *)document
                        withPageSize:(SBSDKPDFRendererPageSize)pageSize
                              output:(nonnull NSURL *)pdfOutputURL;

@end
