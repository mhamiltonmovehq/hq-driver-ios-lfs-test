//
//  WireFrameTypeController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Order.h"
#import "PVODamageAllController.h"
//#import "PreviewPDFController.h"
#import "PVODamageSingleController.h"
#import "ExistingImagesController.h"
#import "PVOVehicle.h"

@class PVOWireFrameTypeController;
@protocol PVOWireFrameTypeControllerDelegate <NSObject>
@optional
-(void)saveWireFrameTypeIDForDelegate:(int)selectedWireframeType;
-(NSDictionary*)getWireFrameTypes:(PVOWireFrameTypeController*)controller;
@end

@interface PVOWireFrameTypeController : UITableViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate>
{
    //Order *order;
    PVODamageAllController *damage;
    //PreviewPDFController *previewPDF;
    PVODamageSingleController *singleDamage;
    ExistingImagesController *existingImagesController;
//    PVOVehicle *vehicle; //going to try to remove the vehicle and just use a generic ID field, then call the delegate on the vehicles class / checklist controller to save the vehicle
    int wireframeItemID;
    id<PVOWireFrameTypeControllerDelegate> delegate;

    BOOL isOrigin;
    BOOL isAutoInventory;
}

//@property (retain, nonatomic) IBOutlet Order *order;
//@property (retain, nonatomic) IBOutlet UITableView *tableSummary;
//@property (retain, nonatomic) IBOutlet UITableView *tableWireFrameType;
@property (nonatomic, retain) UIImagePickerController *picker;
@property (nonatomic, retain) ExistingImagesController *existingImagesController;
//@property (nonatomic, retain) PVOVehicle *vehicle;
@property (nonatomic) int wireframeItemID;
@property (nonatomic) int selectedWireframeTypeID;

@property (nonatomic) BOOL isOrigin;
@property (nonatomic) BOOL isAutoInventory;

@property (nonatomic, retain) id<PVOWireFrameTypeControllerDelegate> delegate;
@property (nonatomic, retain) NSDictionary *wireFrameTypes;

- (IBAction)cmdNextClick:(id)sender;
- (IBAction)cmdPreviousClick:(id)sender;

@end
