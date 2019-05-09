//
//  MoveItemsController.h
//  Survey
//
//  Created by Lee Zumstein on 1/16/13.
//
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "SurveyedItemsList.h"
#import "PVOItemDetail.h"

@interface SelectMoveItemsController : UITableViewController {
    
    BOOL dismiss;
    BOOL isSave;
    
    NSMutableArray *inventoryItemsList;
    //    NSMutableArray *surveyedItems;
    NSMutableArray *itemsToMove;
    Room *moveToRoom;
    
}

@property (nonatomic) BOOL dismiss;
@property (nonatomic) BOOL isSave;

@property (nonatomic, strong) NSMutableArray *inventoryItemsList;
//@property (nonatomic, retain) NSMutableArray *surveyedItems;
@property (nonatomic, strong) NSMutableArray *itemsToMove;
@property (nonatomic, strong) Room *moveToRoom;


-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
