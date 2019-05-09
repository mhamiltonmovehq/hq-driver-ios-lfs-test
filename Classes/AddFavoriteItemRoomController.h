//
//  AddFavoriteItemRoomController.h
//  Survey
//
//  Created by Jason Gorringe on 8/24/18.
//

#import <UIKit/UIKit.h>
#import "PVOFavoriteItemsByRoomController.h"

@class AddRoomController;
@protocol FavoriteItemsByRoomDelegate; // Defined in PVOFavoriteItemsByRoomController

@interface AddFavoriteItemRoomController : UIViewController <UITableViewDataSource,UITableViewDelegate>

-(id)initWithStyle:(UITableViewStyle)style;

@property (nonatomic, retain) NSMutableArray *keys;
@property (nonatomic, retain) NSMutableDictionary *rooms;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, weak) id <FavoriteItemsByRoomDelegate> delegate;

-(IBAction)cancel:(id)sender;

-(void)loadRoomsList;

@end
