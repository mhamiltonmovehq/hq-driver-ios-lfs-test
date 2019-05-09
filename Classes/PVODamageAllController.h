//
//  PVODamageAllController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//
#import <UIKit/UIKit.h>
//#import "Order.h"
#import "PVODamageSingleController.h"
//#import "PreviewPDFController.h"
#import "PVOVehicle.h"

@interface PVODamageAllController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    //Order *order;
    PVODamageSingleController *damageSingle;
    //PreviewPDFController *previewPDF;
//    PVOVehicle *vehicle;
    int wireframeTypeID;
    int wireframeItemID;
    
    BOOL isOrigin;
    BOOL isAutoInventory;
}

//@property (retain, nonatomic) Order *order;
@property (strong, nonatomic) IBOutlet UITableView *tableSummary;
@property (strong, nonatomic) IBOutlet UIImageView *imgAll;
//@property (retain, nonatomic) PreviewPDFController *previewPDF;
//@property (retain, nonatomic) PVOVehicle *vehicle;
@property (strong, nonatomic) NSArray *damages;

@property (nonatomic) BOOL isOrigin;
@property (nonatomic) BOOL isAutoInventory;
@property (nonatomic) int wireframeTypeID;
@property (nonatomic) int wireframeItemID;

- (IBAction)cmdFrontClick:(id)sender;
- (IBAction)cmdRearClick:(id)sender;
- (IBAction)cmdRightClick:(id)sender;
- (IBAction)cmdLeftClick:(id)sender;
- (IBAction)cmdTopClick:(id)sender;
- (IBAction)cmdPreviousClick:(id)sender;

-(void)loadSingleImage:(int)viewType;

@end
