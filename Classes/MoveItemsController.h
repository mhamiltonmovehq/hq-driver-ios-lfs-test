//
//  MoveItemsController.h
//  Survey
//
//  Created by Lee Zumstein on 1/16/13.
//
//

#import <UIKit/UIKit.h>
#import "SelectMoveItemsController.h"
#import "Room.h"
#import "CubeSheet.h"

@interface MoveItemsController : UITableViewController
{
    SelectMoveItemsController *selectMoveItemsController;
    NSInteger currentRoomID;
    CubeSheet *cubeSheet;
    NSMutableArray *allRooms;
    int pvoLoadID;
    
    BOOL dismiss;
    UIPopoverController *popover;
}

@property (nonatomic, strong) SelectMoveItemsController *selectMoveItemsController;
@property (nonatomic) NSInteger currentRoomID;
@property (nonatomic, strong) CubeSheet *cubeSheet;
@property (nonatomic, strong) NSMutableArray *allRooms;
@property (nonatomic) int pvoLoadID;

@property (nonatomic) BOOL dismiss;
@property (nonatomic, strong) UIPopoverController *popover;

@end
