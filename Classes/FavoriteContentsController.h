//
//  FavoriteContentsController.h
//  Survey
//
//  Created by Jason Gorringe on 1/3/18.
//

#import <UIKit/UIKit.h>


@interface FavoriteContentsController : UITableViewController <UIActionSheetDelegate> {
    NSMutableDictionary *allItems;
    NSArray *keys;
}

@property (nonatomic, strong) NSMutableDictionary *allItems;
@property (nonatomic, strong) NSArray *keys;

@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) NSMutableArray *selectedItemsIndexPaths;

@end


