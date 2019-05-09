//
//  PVOAutoInventoryController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOAutoEditViewController.h"
#import "PVOWireFrameTypeController.h"

#define AUTO_INVENTORY_ADD_VEHICLE_ALERT 1000
#define AUTO_INVENTORY_DELETE_VEHICLE_ALERT 1001
#define AUTO_INVENTORY_SHOW_VEHICLE_SIGNATURE_ALERT 1002

@interface PVOAutoInventoryController : UITableViewController <UIActionSheetDelegate, PVOWireFrameTypeControllerDelegate>
{
    NSArray *vehicles;
    NSIndexPath *deleteIndex;
    
    PVOAutoEditViewController *vehicleEditController;
    PVOWireFrameTypeController *wireframe;
    
    PVOVehicle *selectedVehicle;
    
    BOOL isOrigin;
}

@property (nonatomic, retain) NSArray *vehicles;

@property (nonatomic, retain) PVOAutoEditViewController *vehicleEditController;
@property (nonatomic, retain) PVOWireFrameTypeController *wireframe;

@property (nonatomic, retain) PVOVehicle *selectedVehicle;

@property (nonatomic) BOOL isOrigin;

@end
