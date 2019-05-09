//
//  PVOFavoriteItemsController.h
//  Survey
//
//  Created by Tony Brame on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteItemController.h"
#import "PortraitNavController.h"

@class Item;

@interface PVOFavoriteItemsController : UITableViewController {
    NSMutableArray *favoriteItems;
    FavoriteItemController *addItemController;
    PortraitNavController *newNav;
}

@property (nonatomic, retain) NSMutableArray *favoriteItems;
@property (nonatomic, retain) FavoriteItemController *addItemController;

-(IBAction)done:(id)sender;
-(IBAction)addItem:(id)sender;

-(void)itemAdded:(Item*)item;

@end
