//
//  PVOBulkyInventorySignController.h
//  Survey
//
//  Created by Justin on 7/12/16.
//
//


#import <UIKit/UIKit.h>
#import "SignatureViewController.h"
#import "LandscapeNavController.h"
#import "PreviewPDFController.h"
#import "PVONavigationListItem.h"
#import "SingleFieldController.h"
#import "PVOBulkyInventoryItem.h"

@interface PVOBulkyInventorySignController : UITableViewController <SignatureViewControllerDelegate>
{
    NSArray *bulkyItems;
    
    PVOBulkyInventoryItem *selectedbulkyItem;
    
    SignatureViewController *sigView;
    LandscapeNavController *sigNav;
    PreviewPDFController *printController;
    PVONavigationListItem *pvoNavItem;
    
    SingleFieldController *singleFieldController;
    NSString *signatureName;
    
}

@property (nonatomic, retain) NSArray *bulkyItems;

@property (nonatomic, retain) PVOBulkyInventoryItem *selectedbulkyItem;

@property (nonatomic, retain) SignatureViewController *sigView;
@property (nonatomic, retain) LandscapeNavController *sigNav;
@property (nonatomic, retain) PreviewPDFController *printController;
@property (nonatomic, retain) PVONavigationListItem *pvoNavItem;

@property (nonatomic, retain) SingleFieldController *singleFieldController;
@property (nonatomic, retain) NSString *signatureName;


@end
