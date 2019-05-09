
NSMutableArray *visitedTags;//
//  PVOCartonContentsSummaryController.h
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOSelectCartonContentsController.h"
#import "PVOItemDetail.h"
#import "PVODamageWheelController.h"
#import "PVODamageButtonController.h"
#import "PVOInventoryLoad.h"

@class PVOItemDetailController;

@interface PVOCartonContentsSummaryController : PVOBaseViewController <UITableViewDelegate, 
UITableViewDataSource, PVOSelectCartonContentsControllerDelegate> {
    PVOItemDetail *pvoItem;
    NSMutableArray *cartonContents;
    NSMutableArray *visitedTags;
    PVOSelectCartonContentsController *selectController;
    PVODamageWheelController *wheelDamageController;
    PVODamageButtonController *buttonDamageController;
    
    IBOutlet UITableView *toolbar;
    IBOutlet UIBarButtonItem *cmdContinue;
    
    IBOutlet UITableView *tableView;
    
    BOOL contentSelected;
    BOOL hideContinueButton;
    BOOL resetVistedTags;
    
}

@property (nonatomic, strong) PVOItemDetail *pvoItem;
@property (nonatomic) BOOL hideContinueButton;
@property (nonatomic) BOOL resetVistedTags;
@property (nonatomic, strong) NSMutableArray *cartonContents;
@property (nonatomic, strong) UITableView *toolbar;
@property (nonatomic, strong) UIBarButtonItem *cmdContinue;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PVOSelectCartonContentsController *selectController;
@property (nonatomic, strong) PVODamageWheelController *wheelDamageController;
@property (nonatomic, strong) PVODamageButtonController *buttonDamageController;
@property (nonatomic, strong) PVOItemDetailController *contentDetail;

-(IBAction)addContentItem:(id)sender;
-(IBAction)continueToDamage:(id)sender;

@end
