//
//  PVOClaimItemsController.h
//  Survey
//
//  Created by Tony Brame on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOClaim.h"
#import "PVOClaimItem.h"
#import "SingleFieldController.h"
#import "ScannerInputView.h"
#import "PVOItemDetail.h"
#import "SelectObjectController.h"
#import "PVOClaimItemDetailController.h"
#import "ZBarSDK.h"
#import "PreviewPDFController.h"
#import "PortraitNavController.h"

@interface PVOClaimItemsController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, ScannerInputViewDelegate, SelectObjectControllerDelegate, ZBarReaderDelegate, UIAlertViewDelegate>
{
    IBOutlet UITableView *tableView;
    NSMutableArray *items;
    PVOClaim *claim;
    SingleFieldController *manualController;
    ScannerInputView *scannerView;
    SelectObjectController *objectSelectController;
    PVOClaimItemDetailController *claimItemController;
    PortraitNavController *newNav;
    ZBarReaderViewController *zbar;
    PreviewPDFController *printController;
    
    BOOL creatingNewItem;
    PVOClaimItem *newClaimItem;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) PVOClaim *claim;
@property (nonatomic, retain) SingleFieldController *manualController;
@property (nonatomic, retain) ScannerInputView *scannerView;
@property (nonatomic, retain) SelectObjectController *objectSelectController;
@property (nonatomic, retain) PVOClaimItemDetailController *claimItemController;
@property (nonatomic, retain) PreviewPDFController *printController;

-(IBAction)cmdClaimComplete_Click:(id)sender;
-(IBAction)cmdAdd_Click:(id)sender;
-(void)loadClaimItem:(PVOClaimItem*)claimItem;
-(void)itemNumberEntered:(NSString*)value;
-(BOOL)itemNumberEntered:(NSString*)value withLotNumber:(NSString*)lotNumber;
-(void)addItemToClaim:(PVOItemDetail*)pvoItem;
-(BOOL)checkForComplete;


@end
