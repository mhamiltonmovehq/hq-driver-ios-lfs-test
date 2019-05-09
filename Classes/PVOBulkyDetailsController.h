//
//  PVOBulkyDetailsController.h
//  Survey
//
//  Created by Justin on 6/24/16.
//
//The idea here is to mimic the functionality of dynamic reports. We will be able to add bulky items, wireframes, and details via the pricing db without app updates

#import <UIKit/UIKit.h>
#import "SelectObjectController.h"
#import "PVOBulkyEntry.h"
#import "PVOBulkyData.h"
#import "PVOChecklistController.h"
#import "PVOBulkyInventoryItem.h"

@interface PVOBulkyDetailsController : UITableViewController <UITextFieldDelegate, SelectObjectControllerDelegate, PVOWireFrameTypeControllerDelegate>
{
    
}

//@property (nonatomic) int pvoBulkyItemID;
//@property (nonatomic) int pvoBulkyTypeID;
@property (nonatomic) BOOL isOrigin;

@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) PVOBulkyEntry *editingEntry;
@property (nonatomic, strong) UITextField *currentTextBox;
@property (nonatomic, strong) PVOChecklistController *checkListController;
@property (nonatomic, strong) PVOWireFrameTypeController *wireframe;
@property (nonatomic, strong) PVOBulkyInventoryItem *pvoBulkyItem;

-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)updateValueWithField:(UITextField*)sender;

@end
