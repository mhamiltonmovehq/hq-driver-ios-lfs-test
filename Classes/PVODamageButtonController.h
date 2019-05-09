//
//  PVODamageButtonController.h
//  Survey
//
//  Created by Tony Brame on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOItemDetail.h"
#import "PVOConditionEntry.h"
#import "TextEditViewController.h"
#import "PVOBaseViewController.h"

#define PVO_DAMAGE_BUTTON_VIEW_LOCATION 0
#define PVO_DAMAGE_BUTTON_VIEW_DAMAGE 1

#define PVO_DAMAGE_BUTTON_LOC_DAMAGE 0
#define PVO_DAMAGE_BUTTON_CLEAR_LAST 1
#define PVO_DAMAGE_BUTTON_CLEAR_ALL 2
#define PVO_DAMAGE_BUTTON_DONE 3


#define DAMAGE_DITTO_QUANTITY_FIELD 100

#define PVO_DAMAGE_BUTTON_CONFIRM_CLEAR_ALL 1000

@protocol PVODamageControllerDelegate <NSObject>
@optional
-(void)pvoDamageControllerContinueToNextItem:(id)controller;
@end


@interface PVODamageButtonController : PVOBaseViewController <UIAlertViewDelegate, UIActionSheetDelegate, TextEditViewDelegate > {
    IBOutlet UITableView *appliedTable;
    IBOutlet UITableView *availableTable;
    IBOutlet UISegmentedControl *segmentedControl;
    
    NSDictionary *locations;
    NSDictionary *conditions;
    
    int currentView;
    
    PVOItemDetail *details;
    
    PVOConditionEntry *currentDamage;
    
    BOOL showNextItem;
    
    int pvoLoadID;
    int pvoUnloadID;
    
    int maxConditions;
    int maxLocations;
    
    id<PVODamageControllerDelegate> delegate;
    
    BOOL isRiderExceptions;
    
    NSMutableArray *menuOptions;
}

@property (nonatomic) BOOL showNextItem;
@property (nonatomic) int pvoLoadID;
@property (nonatomic) int pvoUnloadID;
@property (nonatomic) BOOL isRiderExceptions;

@property (nonatomic, retain) id<PVODamageControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *appliedTable;
@property (nonatomic, retain) IBOutlet UITableView *availableTable;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) PVOItemDetail *details;
@property (nonatomic, retain) PVOConditionEntry *currentDamage;
@property (nonatomic, retain) NSMutableArray *menuOptions;

-(IBAction)switchViews:(id)sender;

-(IBAction)handleEntryClick:(id)sender;

-(void)saveCurrentEntry;

-(void)scrollToBottomOfApplied;

-(NSArray*)getSortedLocationsKeys;

-(void)clearAll;
-(void)clearLast;

-(IBAction)moveToNextItem:(id)sender;

-(void)setupPluralRemoveButtonText:(NSString**)code withDescription:(NSString**)description;
-(void)dittoQuantityEntered:(NSString*)quantity;

-(void)handleBackBtnClick:(id)sender;

-(void)loadItemDamages;

-(void)processDitto;
-(void)processComments;

@end
