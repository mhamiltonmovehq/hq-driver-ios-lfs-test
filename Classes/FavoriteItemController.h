//
//  FavoriteItemController.h
//  Survey
//
//  Created by Jason Gorringe on 1/3/18.
//

#import <UIKit/UIKit.h>


@interface FavoriteItemController : UITableViewController <UIActionSheetDelegate> {
    NSMutableDictionary *allItems;
    NSArray *keys;
}

@property (nonatomic, retain) NSMutableDictionary *allItems;
@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSArray* favorites;

@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic, retain) NSMutableArray *selectedItemsIndexPaths;

@end

