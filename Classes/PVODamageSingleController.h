//
//  PVODamageSingleController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Order.h"
#import "PVOCommentsController.h"
#import "LandscapeNavController.h"
#import "PVOVehicle.h"

@class SurveyImageViewer;

@interface PVODamageSingleController : UIViewController <UITableViewDataSource, UITableViewDelegate, PVOCommentsControllerDelegate>
{
    int viewType;
    int imageId;
    int wireframeItemID;
    int wireframeTypeID;
//    PVOVehicle *vehicle;
    
    BOOL pickingDamage;
    CGPoint damageLocation;
    NSArray *allDamages;
    SurveyImageViewer *imageViewer;
    
    PVOCommentsController *comments;
    
    BOOL isOrigin;
    BOOL isAutoInventory;
}

@property (nonatomic) int viewType;
@property (nonatomic) int imageId;
@property (nonatomic) int wireframeItemID;
@property (nonatomic) int wireframeTypeID;
//@property (retain, nonatomic) PVOVehicle *vehicle;
@property (nonatomic, strong) NSMutableArray *damages;

@property (strong, nonatomic) IBOutlet UITableView *tableSummary;
@property (strong, nonatomic) IBOutlet UIImageView *imgSingle;
@property (strong, nonatomic) IBOutlet UITableView *tableDamages;
@property (strong, nonatomic) IBOutlet UIView *viewDamage;
@property (strong, nonatomic) IBOutlet UISwitch *switchHighPriority;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDamages;
@property (strong, nonatomic) IBOutlet UIView *viewDamageDetails;

@property (strong, nonatomic) UIImage *photo;

@property (nonatomic) BOOL isOrigin;
@property (nonatomic) BOOL isAutoInventory;

-(IBAction)segmentIndexChanged:(id)sender;
-(IBAction)cmdBackClick:(id)sender;
-(IBAction)cmdImagesClick:(id)sender;
-(void)loadDamageButtons;
-(void)updateCurrentDamagesLabel;

-(NSString*)descriptionForCode:(NSString*)code;

@end
