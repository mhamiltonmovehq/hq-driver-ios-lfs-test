//
//  PVOVerifyHolder.h
//  Survey
//
//  Created by Tony Brame on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectObjectController.h"
#import "PVOLandingController.h"
#import "AddRoomController.h"
#import "ScanOrEnterValueController.h"
#import "PVOVerifyInventoryItem.h"
#import "PVOItemDetailController.h"
#import "SelectItemWithFilterController.h"

#define PVO_VERIFY_PICK_UP 0
#define PVO_VERIFY_DONT_PICK_UP 1

@class Room;

@interface PVOVerifyHolder : NSObject <SelectObjectControllerDelegate, PVOLandingControllerDelegate, AddRoomControllerDelegate, ScanOrEnterValueControllerDelegate, UIActionSheetDelegate, SelectItemWithFilterControllerDelegate, PVOItemDetailControllerDelegate>
{
    PortraitNavController *navController;
    
    //used intially to say which loads are being worked.
    SelectObjectController *selectController;
    
    //used to specify on not found items which load to associate with
    SelectObjectController *selectSingleLoadController;
    
    PVOLandingController *landingController;
    AddRoomController *addRoomController;
    
    NSMutableArray *selectedLoads;
    
    Room *currentRoom;
    
    ScanOrEnterValueController *scanSerialController;
    
    PVOVerifyInventoryItem *currentItem;
    
    PVOItemDetailController *itemDetailController;
    
    SelectItemWithFilterController *selectItemController;
    
    BOOL notPickingUp;
}

-(id)initFromView:(UIViewController*)vc;

-(void)loadNextScreen;

-(void)roomSelected:(Room*)room;

-(void)continueToItemDetails;

@end
