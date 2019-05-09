//
//  SelectItemWithFilterController.h
//  Survey
//
//  Created by Tony Brame on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "PortraitNavController.h"

@class NewItemController;
@class SelectItemWithFilterController;
@class Item;

@protocol SelectItemWithFilterControllerDelegate <NSObject>
@optional
-(void)itemController:(SelectItemWithFilterController*)controller selectedItem:(Item*)item;
-(BOOL)itemControllerShouldShowCancel:(SelectItemWithFilterController*)controller;
-(BOOL)itemControllerShouldDismiss:(SelectItemWithFilterController*)controller;
-(BOOL)itemControllerWasCancelled:(SelectItemWithFilterController*)controller;
@end


@interface SelectItemWithFilterController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    
    int loadType;

    
    IBOutlet UITableView *itemsTable;
    IBOutlet UISegmentedControl *segmentFilter;
    
    NSArray *keys;
    NSDictionary *items;
    
    Room *currentRoom;
    
    id<SelectItemWithFilterControllerDelegate> delegate;
    
    IBOutlet UILabel *labelNoFavorites;
    
    BOOL showAddItemButton;
    NewItemController *itemController;
    
    PortraitNavController *newNav;
    
    BOOL searching;
    
    NSString *searchString;
    
    BOOL showSurveyedFilter;
    
    int lastSegment;
    int currentSegment;
    
    BOOL dontReloadOnAppear;
    
    BOOL showCPButton;
    BOOL showPBOButton;
    
    int pvoLocationID;
}

@property (nonatomic) BOOL showAddItemButton;
@property (nonatomic) BOOL showSurveyedFilter;
@property (nonatomic) BOOL showCPButton;
@property (nonatomic) BOOL showPBOButton;

@property (nonatomic, retain) UITableView *itemsTable;
@property (nonatomic, retain) Room *currentRoom;
@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSDictionary *items;
@property (nonatomic, retain) UISegmentedControl *segmentFilter;
@property (nonatomic, retain) id<SelectItemWithFilterControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UILabel *labelNoFavorites;
@property (nonatomic, retain) NewItemController *itemController;
@property (nonatomic, retain) NSString *searchString;

@property (nonatomic) int pvoLocationID;

-(IBAction)segmentFilter_Changed:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)addNewItem:(id)sender;
-(IBAction)dismissKeyboard:(id)sender;
-(IBAction)cmdSearchClick:(id)sender;

-(void)reloadItemsList;

-(void) shrinkViewForKeyboard;

-(NSArray*)surveyedItemsForRoom;

-(BOOL)shouldDismiss;

@end
