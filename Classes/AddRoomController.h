//
//  AddRoomController.h
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewRoomController.h"

@class AddRoomController;
@protocol AddRoomControllerDelegate <NSObject>
@optional
-(NSArray*)addRoomControllerCustomRoomsList:(AddRoomController*)controller;
-(NSString*)addRoomControllerCustomRoomsHeader:(AddRoomController*)controller;
-(BOOL)addRoomControllerShouldDismiss:(AddRoomController*)controller;
@end

@interface AddRoomController : UIViewController
<UITableViewDelegate, UITableViewDataSource> {
    
    UITableView *tableView;
    
	NSMutableArray *keys;
	NSMutableDictionary *rooms;
	SEL callback;
	NSObject *caller;
	
	UIPopoverController *popover;
	
	//flag indicating it is pushed onto the view controller stack, or it is modal.
	BOOL pushed;
    
    //allow selection between all rooms and a customized list
    int currentView;
    id<AddRoomControllerDelegate> delegate;
    
    int pvoLocationID;
    
    NewRoomController* newRoomController;
}

-(id)initWithStyle:(UITableViewStyle)style;
-(id)initWithStyle:(UITableViewStyle)style andPushed:(BOOL)pushedOntoNavCtl;

@property (nonatomic) SEL callback;
@property (nonatomic) BOOL pushed;

@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) NSMutableArray *keys;
@property (nonatomic, retain) NSMutableDictionary *rooms;
@property (nonatomic, retain) id<AddRoomControllerDelegate> delegate;
@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic) int pvoLocationID;

-(IBAction)cancel:(id)sender;
-(IBAction)newRoom:(id)sender;

-(void)roomAdded:(NSString*)roomName;

-(BOOL)supportCustomRoomSelection;

-(IBAction)viewChanged:(id)sender;
-(void)loadRoomsList;

@end
