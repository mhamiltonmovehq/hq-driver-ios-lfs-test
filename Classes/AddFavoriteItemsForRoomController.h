//
//  AddFavoriteItemsForRoomController.h
//  Survey
//
//  Created by Jason Gorringe on 8/24/18.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "PVOFavoriteItemsByRoomController.h"

@protocol FavoriteItemsByRoomDelegate; // Defined in PVOFavoriteItemsByRoomController

@interface AddFavoriteItemsForRoomController : UITableViewController <UIActionSheetDelegate> {
    NSMutableDictionary *allItems;
    NSArray *keys;
}

@property (nonatomic, retain) NSMutableDictionary *allItems;
@property (nonatomic, retain) NSArray *keys;

@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic, retain) NSMutableArray *selectedItemsIndexPaths;

@property (nonatomic, retain) Room* room;
@property (nonatomic, retain) NSArray* favorites;
@property (nonatomic, weak) id <FavoriteItemsByRoomDelegate> delegate;

-(void)convertFavoritesToSelectedItems:(NSArray*)items;

@end

