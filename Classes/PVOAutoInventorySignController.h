//
//  PVOAutoInventorySignController.h
//  MobileMover
//
//  Created by David Yost on 9/17/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOVehicle.h"
#import "SignatureViewController.h"
#import "LandscapeNavController.h"
#import "PreviewPDFController.h"
#import "PVONavigationListItem.h"
#import "SingleFieldController.h"

@interface PVOAutoInventorySignController : UITableViewController <SignatureViewControllerDelegate>
{
    NSArray *vehicles;
    
    PVOVehicle *selectedVehicle;
    
    SignatureViewController *sigView;
    LandscapeNavController *sigNav;
    PreviewPDFController *printController;
    PVONavigationListItem *selectedItem;
    
    SingleFieldController *singleFieldController;
    NSString *signatureName;
    
    BOOL isOrigin;
}

@property (nonatomic, retain) NSArray *vehicles;

@property (nonatomic, retain) PVOVehicle *selectedVehicle;

@property (nonatomic, retain) SignatureViewController *sigView;
@property (nonatomic, retain) LandscapeNavController *sigNav;
@property (nonatomic, retain) PreviewPDFController *printController;
@property (nonatomic, retain) PVONavigationListItem *selectedItem;

@property (nonatomic, retain) SingleFieldController *singleFieldController;
@property (nonatomic, retain) NSString *signatureName;

@property (nonatomic) BOOL isOrigin;

@end
