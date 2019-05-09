//
//  DeleteItemController.h
//  Survey
//
//  Created by Tony Brame on 11/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DeleteItemController : UITableViewController <UIActionSheetDelegate> {
	NSMutableDictionary *allItems;
	NSArray *keys;
}

@property (nonatomic, retain) NSMutableDictionary *allItems;
@property (nonatomic, retain) NSArray *keys;

@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic, retain) NSMutableArray *selectedItemsIndexPaths;

@property (nonatomic, retain) NSMutableArray *itemsToUnhide;

@property (nonatomic) int customerId;
@property (nonatomic) BOOL ignoreItemListId;

-(IBAction)cancel:(id)sender;

@end
