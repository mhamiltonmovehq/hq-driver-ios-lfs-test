//
//  SurveyImageViewer.m
//  Survey
//
//  Created by Tony Brame on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SurveyImageViewer.h"

#if defined(ATLASNET)
#import <ScanbotSDK/SBSDKScanbotSDK.h>
#endif

#import "SurveyAppDelegate.h"
#import "ExistingImagesController.h"
#import "SurveyCustomer.h"
#import "ShipmentInfo.h"
#import "AppFunctionality.h"
#if defined(ATLASNET)
#import "PVOScanbotViewController.h"
#endif

#import "Mobile_Mover-Swift.h"

@implementation SurveyImageViewer

@synthesize caller, picker, customerID, subID, photosType, existingImagesController, viewController, ipadFrame, ipadPresentView, maxPhotos, wireframeItemID, dismissDelegate, dismissCallback;


//load image if it has one.
+(UIImage*)getDefaultImage:(int)imgType forItem:(int)subid
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *arr = [del.surveyDB getImagesList:del.customerID withPhotoType:imgType
                                            withSubID:subid loadAllItems:NO];
    UIImage *retval = nil;
    if(arr != nil && [arr count] > 0)
    {
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        SurveyImage *image = [arr objectAtIndex:0];
        NSString *filePath = image.path;
        NSString *fullPath = [docsDir stringByAppendingPathComponent:filePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:fullPath])
        {
            UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
            retval = [SurveyAppDelegate resizeImage:img withNewSize:CGSizeMake(30, 30)];
        }
    }
        
    return retval;
}

-(void)loadPhotos
{
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                         destructiveButtonTitle:photosType == IMG_PVO_VEHICLE_DAMAGES && subID == VT_PHOTO ? nil : @"View/Edit Photos"
                                              otherButtonTitles:@"Take New Picture", @"Add Existing Photo", nil];
    sheet.tag = ACTION_SHEET_METHOD;
    [sheet showInView:caller];
    
}

-(void)viewExistingPhotos
{
    //load all images, then show dialog with them all...
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];

    
    if(existingImagesController == nil)
        existingImagesController = [[ExistingImagesController alloc] initWithNibName:@"ExistingImagesView" bundle:nil];
    
    NSMutableArray *imagesArray = [del.surveyDB getImagesList:customerID withPhotoType:photosType withSubID:subID loadAllItems:photosType == IMG_ALL];

    if (photosType == IMG_PVO_VEHICLE_DAMAGES && wireframeItemID && imagesArray != nil)
    {
        //NOTE: if the images are tied to vehicles the "getImageList" method pulls all vehicles for a photo type so we need to narrow it down to the vehicle in question...
        NSMutableArray *vehicleImages = [del.surveyDB getAllVehicleImages:wireframeItemID withCustomerID:customerID];
        NSMutableArray *finalImageList = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [imagesArray count]; i++)
        {
            SurveyImage *image = imagesArray[i];
            if ([vehicleImages containsObject:[NSNumber numberWithInt:image.imageID]])
            {
                [finalImageList addObject:image];
            }
        }
        
        existingImagesController.imagePaths = finalImageList;
    }
    else
    {
        existingImagesController.imagePaths = imagesArray;
    }
    
    
    existingImagesController.subID = subID;
    existingImagesController.photosType = photosType;
    existingImagesController.wireframeItemID = wireframeItemID;
    
    PortraitNavController *nav = [[PortraitNavController alloc] initWithRootViewController:existingImagesController];
    nav.dismissDelegate = dismissDelegate;
    nav.dismissCallback = dismissCallback;
    
    [viewController presentViewController:nav animated:YES completion:nil];
}

-(BOOL)canAddMorePhotos
{
    BOOL canAddMore = YES;
    
    if(maxPhotos <= 0)
        return YES;
    
    //get images list, then check count - must be less than maxPhtots
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *photos = [del.surveyDB getImagesList:del.customerID withPhotoType:photosType withSubID:subID loadAllItems:NO];
    
    if([photos count] >= maxPhotos)
        canAddMore = NO;
    
    return canAddMore;
}

-(void)addNewPhoto
{
    if(![self canAddMorePhotos])
    {
        [SurveyAppDelegate showAlert:@"Unable to add any more photos of this type. To add a new image, you must delete from the current list via the View/Edit Photos option." withTitle:@"Photo Limit Reached"];
        return;
    }
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // Let user take multiple pictures at once
        ImagePickerAdapterController *ipac = [ImagePickerAdapterController new];
        [ipac setCallingController:self];
        [viewController presentViewController:ipac animated:false completion:nil];
        
        /* Old single image picker code:
        if(picker == nil)
        {
            self.picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
        }
        
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if([SurveyAppDelegate iPad])
        {
            popoverController = [[UIPopoverController alloc] initWithContentViewController:picker];
            [popoverController presentPopoverFromRect:ipadFrame
                                     inView:ipadPresentView
                   permittedArrowDirections:UIPopoverArrowDirectionAny 
                                   animated:YES];
        }
        else
            [viewController presentViewController:picker animated:YES completion:nil];
        */
    }
    else
    {
        [SurveyAppDelegate showAlert:@"This device does not have a camera.  Unable to add new photo." withTitle:@"Error"];
    }
}

-(void)addExistingPhoto
{    
    if(![self canAddMorePhotos])
    {
        [SurveyAppDelegate showAlert:@"Unable to add any more photos of this type. To add a new image, you must delete from the current list via the View/Edit Photos option." withTitle:@"Photo Limit Reached"];
        return;
    }
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])// availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        if(picker == nil)
        {
            self.picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
        }
        
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [viewController presentViewController:picker animated:YES completion:nil];
        
    }
    else
    {
        [SurveyAppDelegate showAlert:@"Unable to access photo library on this device.  Unable to add new photo." withTitle:@"Error"];
    }
}


-(void)addPhotoToList:(UIImage *)image
{
    NSError *error = nil;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0f);
    
    NSString *documentsDirectory = [SurveyAppDelegate getDocsDirectory];
    
    NSString *inDocsPath = [del.surveyDB getPhotoSavePath:customerID
                                 withPhotoType:photosType 
                            withSubID:subID];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:inDocsPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:&error];
    }
    
    if (![fileManager createFileAtPath:filePath contents:data attributes:nil]) 
        [SurveyAppDelegate showAlert:filePath withTitle:@"Error Creating File"];
    else
    {
        int imageId = [del.surveyDB addNewImageEntry:customerID withPhotoType:photosType withSubID:subID withPath:inDocsPath];
        
        //make sure our vehicle image id relationship gets created for later...
        if (photosType == IMG_PVO_VEHICLE_DAMAGES && wireframeItemID)
        {
            [del.surveyDB saveVehicleImage:imageId withVehicleID:wireframeItemID withCustomerID:customerID];
        }
    }
    
}

- (void)executeDismissCallback {
    if (dismissDelegate != nil && [dismissDelegate respondsToSelector:dismissCallback]) {
        [dismissDelegate performSelectorOnMainThread:dismissCallback withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - UIImagePickerController methods -

-(void)imagePickerController:(UIImagePickerController*)imagePicker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *customer = [del.surveyDB getCustomer:customerID];
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:customerID];
    
    BOOL isHighValueItem = false;
    if (photosType == IMG_PVO_ITEMS)
    {
        PVOItemDetail *item = [del.surveyDB getPVOItem:subID];
        isHighValueItem = item != nil && item.highValueCost > 0;
    }
    
    UIImage *newImage = nil;
    if (isHighValueItem || (customer.pricingMode == INTERSTATE && shipInfo.orderNumber != nil && [shipInfo.orderNumber length] > 0))
    {//add Order num/date to image
        newImage = [SurveyImageViewer drawText:[NSString stringWithFormat:@"%@(%@)",
                                                [shipInfo.orderNumber length] > 0 ? [NSString stringWithFormat:@"%@ ", shipInfo.orderNumber] : @"",
                                                [SurveyAppDelegate formatDate:[NSDate date]]]
                                       onImage:image
                                       highText:isHighValueItem ? [NSString stringWithFormat:@"%@ Item ", [AppFunctionality getHighValueDescription]] : @"" ];
    }
    
    if(imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        //adding new - check to save to camera roll...
        DriverData *data = [del.surveyDB getDriverData];
        if(data.saveToCameraRoll)
        {
            if (newImage != nil)
                UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
            else
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
    }
    
    [self addPhotoToList:(newImage != nil ? newImage : image)];
    
    [self executeDismissCallback];
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController*)imagePicker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheet methods -

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    int actionIndex = buttonIndex;
    if (photosType == IMG_PVO_VEHICLE_DAMAGES && subID == VT_PHOTO)
        actionIndex++;
    
    if(buttonIndex != [actionSheet cancelButtonIndex])
    {
        if(actionSheet.tag == ACTION_SHEET_METHOD)
        {
            switch (actionIndex) {
                case METHOD_NEW_PHOTO:
                    [self addNewPhoto];
                    break;
                case METHOD_ADD_EXISTING:
                    [self addExistingPhoto];
                    break;
                case METHOD_EDIT_PHOTOS:
                    [self viewExistingPhotos];
                    break;
                default:
                    break;
            }
        }
    }
}

+(UIImage*)drawText:(NSString*)text onImage:(UIImage*)image highText:(NSString*)highText
{
    if (text == nil || image == nil)
        return nil;
    CGContextRef context = NULL;
    CGImageRef imgCombined = NULL;
    @try {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.9.9" options:NSNumericSearch] != NSOrderedAscending)
        {// iOS 7+
            context = CGBitmapContextCreate(NULL,
                                            (size_t)image.size.width,
                                            (size_t)image.size.height,
                                            (size_t)8,
                                            (size_t)(4 * image.size.width),
                                            colorSpace, kCGImageAlphaPremultipliedFirst);
        }
        else
        {// pre iOS 7
            context = CGBitmapContextCreate(NULL,
                                            image.size.width,
                                            image.size.height,
                                            8,
                                            (4 * image.size.width),
                                            colorSpace, kCGImageAlphaPremultipliedFirst);
        }
        //rotate image based on orientation
        if (image.imageOrientation == UIImageOrientationLeft) {
            CGContextRotateCTM(context, (90 * (M_PI/180)));
            CGContextTranslateCTM(context, 0, -image.size.width);
        } else if (image.imageOrientation == UIImageOrientationRight) {
            CGContextRotateCTM(context, (-90 * (M_PI/180)));
            CGContextTranslateCTM(context, -image.size.height, 0);
        } else if (image.imageOrientation == UIImageOrientationUp) {
            //leave it alone
        } else if (image.imageOrientation == UIImageOrientationDown) {
            CGContextTranslateCTM(context, image.size.width, image.size.height);
            CGContextRotateCTM(context, (-180 * (M_PI/180)));
        }
        //draw image
        if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
            CGContextDrawImage(context, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
        } else {
            CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        }
        //draw text
        char* drawText = (char *)[text cStringUsingEncoding:NSASCIIStringEncoding];
        char* drawHighText = (char *)[highText cStringUsingEncoding:NSASCIIStringEncoding];
//        CGContextSelectFont(context, "Arial", 25.2, kCGEncodingMacRoman); // 0.35 inches high (72pt = 1 inch)
        CGFloat fontSize = 62.0;
        CGContextSelectFont(context, "Arial", fontSize, kCGEncodingMacRoman); // 0.35 inches high (72pt = 1 inch)
        CGContextSetTextDrawingMode(context, kCGTextFill);
        CGContextSetRGBFillColor(context, 255, 255, 255, 1);

        //rotate text
        CGFloat yDelta = 20, xDelta = 15, topDelta = yDelta + fontSize;
        CGFloat x = xDelta, y = yDelta;
        CGFloat highY = image.size.height - topDelta, highX = xDelta;
        
        if (image.imageOrientation == UIImageOrientationLeft) {
            CGContextSetTextMatrix(context, CGAffineTransformMakeRotation(-90 * (M_PI/180)));
            y = image.size.width - yDelta; // topDelta;
            highY = yDelta;
        } else if (image.imageOrientation == UIImageOrientationRight) {
            CGContextSetTextMatrix(context, CGAffineTransformMakeRotation(90 * (M_PI/180)));
            x = image.size.height - xDelta; // - strlen(drawText);
            highX = image.size.height - xDelta; // - strlen(drawHighText);
        } else if (image.imageOrientation == UIImageOrientationUp) {
            //leave it alone
        } else if (image.imageOrientation == UIImageOrientationDown) {
            CGContextSetTextMatrix(context, CGAffineTransformMakeRotation(-180 * (M_PI/180)));
            x = image.size.width - xDelta; // - strlen(drawText);
            y = image.size.height - yDelta;
            highX = image.size.height - xDelta; // - strlen(drawHighText);
            highY = yDelta;
        }
        CGContextShowTextAtPoint(context, x, y, drawText, strlen(drawText)); //bottom left corner
        CGContextShowTextAtPoint(context, highX, highY, drawHighText, strlen(drawHighText)); //bottom left corner
        imgCombined = CGBitmapContextCreateImage(context);
        CGColorSpaceRelease(colorSpace);
        
        return [UIImage imageWithCGImage:imgCombined];
    }
    @catch (NSException *exc) {
        return image; //if error, return original image
    }
    @finally {
        if (context != NULL) {
            CGContextRelease(context);
        }
        if (imgCombined != NULL) {
            CGImageRelease(imgCombined);
        }
    }
}

#pragma mark - PVOScanbotViewControllerDelegate -

- (void)documentImageCaptured:(UIImage *)documentImage
{
    if (documentImage == nil)
    {
        [self documentImageCancelled];
        return;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    if (data.saveToCameraRoll)
    {
        UIImageWriteToSavedPhotosAlbum(documentImage, nil, nil, nil);
    }
    
    [self addPhotoToList:documentImage];
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentImageCancelled
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

// Image picker cancel button pressed
- (void)cancelButtonDidPress:(ImagePickerController * _Nonnull)imagePicker {
    [imagePicker dismissViewControllerAnimated:true completion:nil];
}

// Image picker done button pressed
- (void)doneButtonDidPress:(ImagePickerController * _Nonnull)imagePicker images:(NSArray<UIImage *> * _Nonnull)images {
    [imagePicker dismissViewControllerAnimated:true completion:nil];
    
    // Handle images one-by-one now that they have been returned
    for(UIImage *image in images) {
        [self processImageFromMultiPicker:image];
    }
}

// Image picker gallery button pressed
- (void)wrapperDidPress:(ImagePickerController * _Nonnull)imagePicker images:(NSArray<UIImage *> * _Nonnull)images {
    LightboxAdapterController *lbc = [LightboxAdapterController new];
    [lbc showLightboxWithImages:images imagePicker:imagePicker];
}

// Process single image
- (void)processImageFromMultiPicker:(UIImage*)image {
    // Adapted version of didFinishPickingImage for the multi picker
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *customer = [del.surveyDB getCustomer:customerID];
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:customerID];
    
    BOOL isHighValueItem = false;
    if (photosType == IMG_PVO_ITEMS)
    {
        PVOItemDetail *item = [del.surveyDB getPVOItem:subID];
        isHighValueItem = item != nil && item.highValueCost > 0;
    }
    
    UIImage *newImage = nil;
    if (isHighValueItem || (customer.pricingMode == INTERSTATE && shipInfo.orderNumber != nil && [shipInfo.orderNumber length] > 0))
    {//add Order num/date to image
        newImage = [SurveyImageViewer drawText:[NSString stringWithFormat:@"%@(%@)",
                                                [shipInfo.orderNumber length] > 0 ? [NSString stringWithFormat:@"%@ ", shipInfo.orderNumber] : @"",
                                                [SurveyAppDelegate formatDate:[NSDate date]]]
                                       onImage:image
                                      highText:isHighValueItem ? [NSString stringWithFormat:@"%@ Item ", [AppFunctionality getHighValueDescription]] : @"" ];
    }
    
    //adding new - check to save to camera roll...
    DriverData *data = [del.surveyDB getDriverData];
    if(data.saveToCameraRoll)
    {
        if (newImage != nil)
            UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
        else
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    [self executeDismissCallback];
    [self addPhotoToList:(newImage != nil ? newImage : image)];
}

@end
