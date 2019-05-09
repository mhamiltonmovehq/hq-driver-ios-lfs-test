//
//  ItemCell.h
//  Survey
//
//  Created by Tony Brame on 5/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"

@interface ItemCell : UITableViewCell {
	IBOutlet UILabel *labelName; 
	IBOutlet UILabel *labelCube;
	IBOutlet UILabel *labelShip;
	IBOutlet UILabel *labelNotShip;
	
	bool processedSwipe;
	bool processedLeftSwipe;
	bool processedRightSwipe;
	bool cellHeld;
	CGPoint mystartTouchPosition;
	Item *item;
	NSTimeInterval pressed;
	
	NSObject *caller;
	SEL itemCellLeftSwipe;
}

@property (nonatomic, retain) NSObject *caller;
@property (nonatomic) SEL itemCellLeftSwipe;
@property (nonatomic) NSTimeInterval pressed;
@property (nonatomic) bool cellHeld;
@property (nonatomic) bool processedSwipe;
@property (nonatomic) bool processedLeftSwipe;
@property (nonatomic) bool processedRightSwipe;

@property (nonatomic, retain) UILabel *labelName;
@property (nonatomic, retain) UILabel *labelCube;
@property (nonatomic, retain) UILabel *labelShip;
@property (nonatomic, retain) UILabel *labelNotShip;
@property (nonatomic, retain) Item *item;

-(void)removeCounts;

@end
