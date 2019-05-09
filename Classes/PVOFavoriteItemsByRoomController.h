//
//  PVOFavoriteItemsByRoomController.h
//  Survey
//
//  Created by Jason Gorringe on 8/24/18.
//

#import <UIKit/UIKit.h>
#import "SurveyAppDelegate.h"
#import "AddFavoriteItemRoomController.h"
#import "AddFavoriteItemsForRoomController.h"
#import "PortraitNavController.h"
#import "AddFavoriteItemRoomController.h"

@class Room;
@class AddFavoriteItemRoomController;
@class AddFavoriteItemsForRoomController;

// Delegate used to call back from AddFavoriteItemRoomController and AddFavoriteItemsForRoomController
@protocol FavoriteItemsByRoomDelegate <NSObject>
@optional
-(void)roomChosen:(Room*)room;
-(void)itemsChosen:(NSArray*)items forRoom:(Room*)room;
@end

@interface PVOFavoriteItemsByRoomController : UITableViewController <FavoriteItemsByRoomDelegate,UIActionSheetDelegate> {
    NSMutableArray* favoriteItemsRooms;
    AddFavoriteItemRoomController* addItemRoomController;
    AddFavoriteItemsForRoomController* addItemsForRoomController;
    PortraitNavController *newNav;
}

@property (nonatomic, retain) NSMutableArray* favoriteItemsRooms;
@property (nonatomic, retain) AddFavoriteItemRoomController* addItemRoomController;

@property (nonatomic, retain) NSIndexPath* indexPathToDelete;

-(IBAction)done:(id)sender;
-(IBAction)addRoom:(id)sender;

@end
