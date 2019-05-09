//
//  ItemViewController.h
//  Survey
//
//  Created by Tony Brame on 5/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"

#define TYPICAL_VIEW 0
#define ALL_VIEW 1
#define SURVEYED_VIEW 2

@interface ItemViewController : UIViewController 
	<UITableViewDelegate, UITableViewDataSource>{
		Room *currentRoom;
		NSMutableArray *keys;
		NSMutableDictionary *items;
		IBOutlet UISegmentedControl *viewControl;
		IBOutlet UITableView *itemTable;
}

@property (nonatomic, retain) Room *currentRoom;
@property (nonatomic, retain) NSMutableArray *keys;
@property (nonatomic, retain) NSMutableDictionary *items;
@property (nonatomic, retain) UISegmentedControl *viewControl;
@property (nonatomic, retain) UITableView *itemTable;


-(IBAction) switchView:(id)sender;

@end
