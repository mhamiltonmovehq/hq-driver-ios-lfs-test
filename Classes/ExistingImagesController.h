//
//  ExistingImagesController.h
//  Survey
//
//  Created by Tony Brame on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SurveyImage.h"
#import "PVODamageSingleController.h"
#import "LandscapeNavController.h"

@class PVOVehicle;
@class SurveyImageViewer;

@interface ExistingImagesController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
	IBOutlet UIScrollView *scrollView;
	IBOutlet UINavigationBar *navBar;
	IBOutlet UIView *oneImageView;
	IBOutlet UIImageView *oneImageViewImage;
	NSMutableArray *imagePaths;
    SurveyImageViewer *imageViewer;
    PVODamageSingleController *singleDamage;
    
	int photosType;
	int subID;
    int editingIDX;
    int wireframeItemID;
    
    BOOL isOrigin;
    BOOL isAutoInventory; //signifies the user is using SPECIFICALLY the auto inventory, not bulky inventory
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) UIView *oneImageView;
@property (nonatomic, retain) UIImageView *oneImageViewImage;
@property (nonatomic, retain) NSMutableArray *imagePaths;
@property (nonatomic, retain) SurveyImageViewer *imageViewer;
@property (nonatomic, retain) PVODamageSingleController *singleDamage;

@property (retain, nonatomic) IBOutlet UILabel *lblOneImageDate;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *cmdDelete;

@property (nonatomic) int photosType;
@property (nonatomic) int subID;
@property (nonatomic) int wireframeItemID;


@property (nonatomic) BOOL isOrigin;
@property (nonatomic) BOOL isAutoInventory;

-(IBAction)finishedEditing:(id)sender;
-(IBAction)deleteImage:(id)sender;
-(void)imageSelected:(id)sender;
- (IBAction)cmdEmailClick:(id)sender;

-(void)loadImage:(SurveyImage*)imageDetails;

-(void)imageLoaded:(NSArray*)data;

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end
