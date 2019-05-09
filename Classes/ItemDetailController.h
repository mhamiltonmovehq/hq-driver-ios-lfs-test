//
//  ItemDetailController.h
//  Survey
//
//  Created by Tony Brame on 7/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"
#import "SurveyedItem.h"
#import "CrateDimensions.h"
#import "SingleFieldController.h"
#import "SurveyImageViewer.h"

#define ITEM_DETAIL_SECTION_SHIP 0
#define ITEM_DETAIL_SECTION_WEIGHT 1
#define ITEM_DETAIL_SECTION_COMMENT 2
#define ITEM_DETAIL_SECTION_PHOTO 3
#define ITEM_DETAIL_SECTION_PACK 4
#define ITEM_DETAIL_SECTION_DIMENSIONS 5
#define ITEM_DETAIL_SECTION_INT_BULKY_FT 6

#define ITEM_DETAIL_ROW_SHIPPING 0
#define ITEM_DETAIL_ROW_NOTSHIPPING 1

#define ITEM_DETAIL_ROW_WEIGHT 0
#define ITEM_DETAIL_ROW_CUBE 1

#define ITEM_DETAIL_ROW_PACK 0
#define ITEM_DETAIL_ROW_UNPACK 1

#define ITEM_DETAIL_ROW_LENGTH 0
#define ITEM_DETAIL_ROW_WIDTH 1
#define ITEM_DETAIL_ROW_HEIGHT 2

#define ITEM_DETAIL_BULKY_COST 0
#define ITEM_DETAIL_BULKY_WT_ADD 1
#define ITEM_DETAIL_BULKY_HOURLY 2
#define ITEM_DETAIL_BULKY_HOURS 3

#define ITEM_DETAIL_SECTIONS 6

@interface ItemDetailController : UITableViewController {
    Item *item;
    SurveyedItem *si;
    NSString *comment;
    NSMutableArray *sections;
    CrateDimensions *dims;
    SingleFieldController *fieldController;
    NSIndexPath *editingPath;
    NSObject *caller;
    SEL callback;
    BOOL editing;
    BOOL editingImages;
    SurveyImageViewer *imageViewer;
    UIImage *itemImage;
    int imagesCount;
}

@property (nonatomic) SEL callback;
@property (nonatomic) int imagesCount;

@property (nonatomic, strong) Item *item;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) SurveyedItem *si;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) CrateDimensions *dims;
@property (nonatomic, strong) SingleFieldController *fieldController;
@property (nonatomic, strong) NSObject *caller;
@property (nonatomic, strong) SurveyImageViewer *imageViewer;
@property (nonatomic, strong) UIImage *itemImage;

-(void)initializeSections;

-(void)doneEditing:(NSString*)newValue;
-(IBAction)save:(id)sender;

-(int)sectionTypeAtIndex:(int)idx;

@end
