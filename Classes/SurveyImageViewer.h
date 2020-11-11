//
//  SurveyImageViewer.h
//  Survey
//
//  Created by Tony Brame on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
@import ImagePicker;
@import Lightbox;

#import <Foundation/Foundation.h>
#import "ExistingImagesController.h"
#import "PVOVehicle.h"
#import "AppFunctionality.h"
#if defined(ATLASNET)
#import "PVOScanbotViewController.h"
#endif

#define ACTION_SHEET_METHOD 1

#define METHOD_NEW_PHOTO 1
#define METHOD_ADD_EXISTING 2
#define METHOD_EDIT_PHOTOS 0

#define ALERT_SCANBOT_EXPIRED 3



#if defined(ATLASNET)
@interface SurveyImageViewer : NSObject < UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PVOScanbotViewControllerDelegate, ImagePickerDelegate >
#else
@interface SurveyImageViewer : NSObject < UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImagePickerDelegate >
#endif
{
    UIView *caller;
    UIImagePickerController *picker;
    int customerID;
    int subID;
    int photosType;
    ExistingImagesController *existingImagesController;
    
    UIViewController *viewController;
    
    CGRect ipadFrame;
    UIView *ipadPresentView;
        
    //used internally to dismiss popover when user selects a photo
    UIPopoverController *popoverController;
    
    //added for PVO Weight tickets - only one image per customer.  <= 0 means unlimited...
    int maxPhotos;
    int wireframeItemID;
}

@property (nonatomic, strong) UIView *caller;
@property (nonatomic, strong) UIView *ipadPresentView;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) ExistingImagesController *existingImagesController;
@property (nonatomic, strong) UIViewController *viewController;

@property (nonatomic) int customerID;
@property (nonatomic) int subID;
@property (nonatomic) int photosType;
@property (nonatomic) CGRect ipadFrame;
@property (nonatomic) int pVOItemID;
//added for PVO Weight tickets - only one image per customer.  <= 0 means unlimited...
@property (nonatomic) int maxPhotos;
@property (nonatomic) int wireframeItemID;

@property (nonatomic) NSObject *dismissDelegate;
@property (nonatomic) SEL dismissCallback;


+(UIImage*)getDefaultImage:(int)imgType forItem:(int)subid;

-(void)loadPhotos;
-(void)addNewPhoto;
-(void)addPhotoToList:(UIImage *)image;
-(void)viewExistingPhotos;

-(BOOL)canAddMorePhotos;

+(UIImage*)drawText:(NSString*)text onImage:(UIImage*)image highText:(NSString*)highText;

- (void)processImageFromMultiPicker:(UIImage*)image;

@end
