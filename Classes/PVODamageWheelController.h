//
//  PVOItemDetailController.h
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVODamageButtonController.h"
#import "Room.h"
#import "Item.h"
#import "PVOItemDetail.h"
#import "PVOConditions.h"
#import "PVOInventory.h"
#import "PVOConditionEntry.h"
#import "TextEditViewController.h"

#define PVO_DAMAGE_WHEEL_CLEAR_LAST 0
#define PVO_DAMAGE_WHEEL_CLEAR_ALL 1
#define PVO_DAMAGE_WHEEL_DONE 2

@interface StringKey : NSObject {
    NSString *object;
    NSString *key;
}
@property (nonatomic, strong) NSString *object;
@property (nonatomic, strong) NSString *key;
@end

#define PVO_DAMAGE_CONFIRM_CLEAR_ALL 1000

@interface PVODamageWheelController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIActionSheetDelegate, TextEditViewDelegate> {
    IBOutlet UITableView *conditionsTable;
    IBOutlet UITableView *locationsTable;
    IBOutlet UITableView *appliedTable;
    IBOutlet UISegmentedControl *segmentedControl;
    
    NSDictionary *locations;
    NSDictionary *conditions;
    
    PVOItemDetail *details;
    
    PVOConditionEntry *currentDamage;
    
    BOOL showNextItem;
    
    int pvoLoadID;
    int pvoUnloadID;
    
    int maxConditions;
    
    id<PVODamageControllerDelegate> delegate;
    
    BOOL isRiderExceptions;
    
    NSMutableArray *menuOptions;
}

@property (nonatomic) BOOL showNextItem;
@property (nonatomic) int pvoLoadID;
@property (nonatomic) int pvoUnloadID;
@property (nonatomic) BOOL isRiderExceptions;

@property (nonatomic, strong) id<PVODamageControllerDelegate> delegate;
@property (nonatomic, strong) PVOItemDetail *details;
@property (nonatomic, strong) NSDictionary *conditions;
@property (nonatomic, strong) NSDictionary *locations;
@property (nonatomic, strong) PVOConditionEntry *currentDamage;
@property (nonatomic, strong) NSMutableArray *menuOptions;


@property (nonatomic, strong) IBOutlet UITableView *conditionsTable;
@property (nonatomic, strong) IBOutlet UITableView *locationsTable;
@property (nonatomic, strong) IBOutlet UITableView *appliedTable;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;

-(IBAction)clearAction:(id)sender;

-(NSArray*)getSortedKeysForStringDict:(NSDictionary*)mydict;
-(void)scrollToBottomOfApplied;
-(void)saveCurrentEntry;
-(void)dittoQuantityEntered:(NSString*)quantity;
-(void)handleBackBtnClick:(id)sender;
-(void)loadItemDamages;

-(void)processDitto;
-(void)processComments;

-(void)clearLast;
-(void)clearAll;

@end
