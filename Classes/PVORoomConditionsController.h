//
//  PVORoomConditionsController.h
//  Survey
//
//  Created by Tony Brame on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "PVOInventoryLoad.h"
#import "PVOInventoryUnload.h"
#import "PVORoomConditions.h"
#import "SurveyImageViewer.h"

#define PVO_ROOM_COND_FLOOR_TYPE 0
#define PVO_ROOM_COND_CAMERA 1
#define PVO_ROOM_COND_DAMAGE 2
#define PVO_ROOM_COND_DAMAGE_DETAIL 3

@interface PVORoomConditionsController : PVOBaseTableViewController <UITextViewDelegate>
{
    Room *room;
    PVOInventoryLoad *currentLoad;
    PVOInventoryUnload *currentUnload;
    PVORoomConditions *conditions;
    
    NSMutableArray *rows;
    
    NSDictionary *floorTypes;
    
    UITextView *tboxCurrent;
    
    SurveyImageViewer *imageViewer;
    
    BOOL editing;
}

@property (nonatomic, retain) Room *room;
@property (nonatomic, retain) PVOInventoryLoad *currentLoad;
@property (nonatomic, retain) PVOInventoryUnload *currentUnload;
@property (nonatomic, retain) PVORoomConditions *conditions;
@property (nonatomic, retain) UITextView *tboxCurrent;

-(void)initializeIncludedRows;

-(IBAction)switchChanged:(id)sender;

-(IBAction)done:(id)sender;

-(void)floorTypeSelected:(NSNumber*)newID;


@end
