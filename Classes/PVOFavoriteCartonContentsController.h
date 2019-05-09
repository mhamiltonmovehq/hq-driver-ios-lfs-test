//
//  PVOFavoriteCartonContentsController.h
//  Survey
//
//  Created by Justin Little on 10/3/14.
//
//

#import <UIKit/UIKit.h>
#import "FavoriteContentsController.h"
#import "PortraitNavController.h"


@class PVOCartonContent;

@interface PVOFavoriteCartonContentsController : UITableViewController {
    NSMutableArray *favoriteContents;
    FavoriteContentsController *favoriteContentsController;
    PortraitNavController *newNav;
}

@property (nonatomic, retain) NSMutableArray *favoriteContents;
@property (nonatomic, retain) FavoriteContentsController *favoriteContentsController;

-(IBAction)done:(id)sender;
-(IBAction)addItem:(id)sender;

-(void)itemAdded:(PVOCartonContent*)ccItem;


@end
