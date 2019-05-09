//
//  NewItemController.h
//  Survey
//
//  Created by Tony Brame on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"
#import "Room.h"
#import "AddRoomController.h"
#import "PortraitNavController.h"

#define NEW_ITEM_NUM_ROWS 4
#define NEW_ITEM_NAME 0
#define NEW_ITEM_CUBE 1
#define NEW_ITEM_IS_CRATE 2
#define NEW_ITEM_IS_SINGLE_USE 3
#define NEW_ITEM_ROOM 4
//#define NEW_ITEM_ROOM 3


@interface NewItemController : UITableViewController
    <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    Item *item;
    Room *room;
    UITextField *tboxCurrent;
    AddRoomController *addRoom;
        SEL callback;
        NSObject *caller;
        PortraitNavController *portraitNavController;
        
        UIPopoverController *popover;
        
    int pvoLocationID;
        BOOL isSingleUse;
}

@property (nonatomic) SEL callback;

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) PortraitNavController *portraitNavController;
@property (nonatomic, strong) NSObject *caller;
@property (nonatomic, strong) Room *room;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) Item *item;
@property (nonatomic, strong) AddRoomController *addRoom;

@property (nonatomic) int pvoLocationID;

-(void) cancel:(id)sender;
-(void) save:(id)sender;
-(void) roomSelected:(Room*)newRoom;
-(IBAction)isCrateSwitched:(id)sender;
-(IBAction)isSingleUseSwitched:(id)sender;
-(void)updateItemValueWithField:(UITextField*)textField;

@end
