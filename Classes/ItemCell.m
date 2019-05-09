//
//  ItemCell.m
//  Survey
//
//  Created by Tony Brame on 5/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ItemCell.h"
#import "SurveyAppDelegate.h"
#import "Item.h"

@implementation ItemCell

@synthesize labelCube, labelShip, labelName, labelNotShip, caller;
@synthesize itemCellLeftSwipe, item, pressed, cellHeld, processedSwipe, processedRightSwipe, processedLeftSwipe;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		
	}
	return self;
}


-(void)removeCounts
{
    [labelNotShip removeFromSuperview];
    [labelShip removeFromSuperview];
    
    CGRect frame = labelName.frame;
    frame.size.width += labelNotShip.frame.size.width + labelShip.frame.size.width;
    labelName.frame = frame;
    
    frame = labelCube.frame;
    frame.origin.x += labelNotShip.frame.size.width + labelShip.frame.size.width;
    labelCube.frame = frame;
}

#define VERTICAL_SWIPE_DRAG_MAX 100
#define HORIZ_SWIPE_DRAG_MIN 100

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	cellHeld = NO;
	//processedLeftSwipe = NO;
	//processedRightSwipe = NO;
	
	pressed = [[NSDate date] timeIntervalSince1970];
	
	//UITouch *touch = [touches anyObject];
	//CGPoint newTouchPosition = [touch locationInView:self];
	//if(mystartTouchPosition.x != newTouchPosition.x || mystartTouchPosition.y != newTouchPosition.y) {
	//	processedSwipe = NO;
	//} 
	//mystartTouchPosition = [touch locationInView:self];
	[super touchesBegan:touches withEvent:event];
	//NSLog(@"cell touchesBegan");
	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	//if(!processedSwipe)
	//{//never swiped
		
		NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
		if(current - pressed > 1.0)
		{
			cellHeld = YES;
		}
		
	//}
	
	[super touchesEnded:touches withEvent:event];
	//NSLog(@"cell touchesEnded");

	//processedSwipe = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
