//
//  DeleteRoomController.h
//  Survey
//
//  Created by Tony Brame on 11/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DeleteRoomController : UITableViewController <UIActionSheetDelegate> {
    NSDictionary *allRooms;
    NSArray *keys;
}

@property (nonatomic, strong) NSDictionary *allRooms;
@property (nonatomic, strong) NSArray *keys;

@property (nonatomic, strong) NSMutableArray *selectedRooms;
@property (nonatomic, strong) NSMutableArray *selectedRoomsIndexPaths;

@property (nonatomic, strong) NSMutableArray *roomsToUnhide;

@end
