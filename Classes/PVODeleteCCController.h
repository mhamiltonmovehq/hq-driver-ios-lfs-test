//
//  PVODeleteCCController.h
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PVODeleteCCController : UITableViewController <UIActionSheetDelegate> {
    NSArray *keys;
    NSArray *allItems;
    NSDictionary *contentsDictionary;
    
    NSIndexPath *editPath;
    BOOL setupFavorites;
}

@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSArray *allItems;
@property (nonatomic, retain) NSDictionary *contentsDictionary;

@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic) BOOL setupFavorites;

@property (nonatomic, retain) NSMutableArray *itemsToUnhide;

-(IBAction)done:(id)sender;

-(void)reloadContentsList;

@end
