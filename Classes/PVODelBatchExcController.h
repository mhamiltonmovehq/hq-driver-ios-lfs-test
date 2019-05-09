//
//  PVODelBatchExcController.h
//  Survey
//
//  Created by Tony Brame on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOItemDetail.h"
#import "PVODamageWheelController.h"
#import "PVODamageButtonController.h"
#import "SignatureViewController.h"
#import "LandscapeNavController.h"

@class PVOInventoryUnload;
@class PVOInventoryLoad;

enum EXCEPTIONS_CONTROLLER_TYPE {
    EXC_CONTROLLER_QUICK_SCAN = 0,
    EXC_CONTROLLER_RECEIVE = 1,
    EXC_CONTROLLER_DELIVERY = 2
};

@interface PVODelBatchExcController : UITableViewController <UIAlertViewDelegate, SignatureViewControllerDelegate> {
    NSArray *duplicatedTags;
    NSMutableArray *visitedTags;
    BOOL editing;
    BOOL moveToNextItem;
    BOOL hideBackButton;
    
    PVOInventoryUnload *currentUnload;
    PVOInventoryLoad *currentLoad;
    
    NSString *currentTag;
    SignatureViewController *signatureController;
    LandscapeNavController *sigNav;
    
    enum EXCEPTIONS_CONTROLLER_TYPE excType;
}

@property (nonatomic) BOOL moveToNextItem;
@property (nonatomic) BOOL hideBackButton;
@property (nonatomic) enum EXCEPTIONS_CONTROLLER_TYPE excType;

@property (nonatomic, retain) PVODamageWheelController *wheelDamageController;
@property (nonatomic, retain) PVODamageButtonController *buttonDamageController;
@property (nonatomic, retain) SignatureViewController *signatureController;

@property (nonatomic, retain) NSArray *duplicatedTags;
@property (nonatomic, retain) PVOInventoryUnload *currentUnload;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;

-(IBAction)moveToNextItem:(id)sender;

@end
