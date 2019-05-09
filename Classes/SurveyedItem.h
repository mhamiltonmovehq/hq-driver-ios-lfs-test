//
//  SurveyedItem.h
//  Survey
//
//  Created by Tony Brame on 6/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CrateDimensions.h"
#import "XMLWriter.h"
#import "Item.h"
#import "CrateDimensions.h"

#define FLUSH_NO_MATERIALS 0
#define FLUSH_MATERIALS_SHIP_MINUS_PACK 1
#define FLUSH_MATERIALS_SAME_AS_SHIP 2

@interface SurveyedItem : NSObject {
	int csID;
	int siID;
	int itemID;
	int roomID;
	int shipping;
	int notShipping;
	int packing;
	int unpacking;
	double cube;
	int weight;
    int imageID;
	Item *item;
	CrateDimensions *dims;
}

@property (nonatomic) int csID;
@property (nonatomic) int siID;
@property (nonatomic) int itemID;
@property (nonatomic) int roomID;
@property (nonatomic) int shipping;
@property (nonatomic) int notShipping;
@property (nonatomic) int packing;
@property (nonatomic) int unpacking;
@property (nonatomic) double cube;
@property (nonatomic) int weight;
@property (nonatomic) int imageID;
@property (nonatomic, retain) Item *item;
@property (nonatomic, retain) CrateDimensions *dims;

-(id)initWithSurveyedItem:(SurveyedItem*)si;
-(void)updateCrateCube:(CrateDimensions*)dims withMinimum:(double)minimun andInches:(double)inches;
-(void)flushToXML:(XMLWriter*)xml withItems:(NSArray*)items materialHandling:(int)handleType;

-(NSComparisonResult)compareAlphabetically:(SurveyedItem*)otherItem;

@end
