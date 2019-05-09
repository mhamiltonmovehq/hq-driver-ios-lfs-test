//
//  PVODeliverySummaryController.h
//  Survey
//
//  Created by Tony Brame on 10/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectLocationController.h"
#import "PVODeliveryController.h"
#import "SelectObjectController.h"
#import "PortraitNavController.h"

@class PVOInventoryLoad;
@class PVOInventoryUnload;

@interface PVODeliveryLoadSelectItem : NSObject {
    PVOInventoryLoad *load;
    NSString *display;
}
@property (nonatomic, strong) PVOInventoryLoad *load;
@property (nonatomic, strong) NSString *display;
@end

@interface PVODeliverySummaryController : UITableViewController <SelectLocationControllerDelegate, SelectObjectControllerDelegate, UIAlertViewDelegate>
{
    NSArray *deliveries;
    NSDictionary *locations;
    NSArray *loads;
    PVOInventoryUnload *newDelivery;
    SelectLocationController *selectLocation;
    PortraitNavController *newNav;
    PVODeliveryController *deliveryController;
    SelectObjectController *selectLoads;
}

@property (nonatomic, strong) NSArray *deliveries;
@property (nonatomic, strong) NSArray *loads;
@property (nonatomic, strong) NSDictionary *locations;
@property (nonatomic, strong) SelectLocationController *selectLocation;
@property (nonatomic, strong) PVODeliveryController *deliveryController;
@property (nonatomic, strong) SelectObjectController *selectLoads;

-(PVOInventoryLoad*)getLoad:(int)loadID;
-(void)loadDeliveryPage:(PVOInventoryUnload*)unload;
-(IBAction)addDelivery:(id)sender;

@end
