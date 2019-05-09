//
//  NewRoomController.h
//  Survey
//
//  Created by mmqa3 on 10/19/15.
//
//

#import <UIKit/UIKit.h>

#import "Room.h"

#import "PortraitNavController.h"



#define NEW_ROOM_NUM_ROWS 2

#define NEW_ROOM_NAME 0

#define NEW_ROOM_IS_SINGLE_USE 1



@interface NewRoomController : UITableViewController

<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    
    Room *room;
    
    UITextField *tboxCurrent;
    
    UIPopoverController *popover;
    
    
    
    BOOL isSingleUse;
    
    int pvoLocationID;
    
}





@property (nonatomic) SEL callback;

@property (nonatomic, retain) UIPopoverController *popover;

@property (nonatomic, retain) PortraitNavController *portraitNavController;

@property (nonatomic, retain) NSObject *caller;

@property (nonatomic, retain) Room *room;

@property (nonatomic, retain) UITextField *tboxCurrent;

@property (nonatomic) int pvoLocationID;



-(void) cancel:(id)sender;

-(void) save:(id)sender;

-(IBAction)isSingleUseSwitched:(id)sender;

-(void)updateItemValueWithField:(UITextField*)textField;

@end
