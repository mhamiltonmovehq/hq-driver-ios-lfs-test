//
//  PVOItemDetail.h
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "XMLWriter.h"
#import "CrateDimensions.h"

#define PVO_INVENTORY_NUMBER_CHARS 10

#define PVO_VOID_NO_ITEM_NAME @"NO ITEM"

#define PVO_ITEM_DETAIL_WEIGHT_TYPE_NONE 0
#define PVO_ITEM_DETAIL_WEIGHT_TYPE_CONSTRUCTIVE 1
#define PVO_ITEM_DETAIL_WEIGHT_TYPE_ACTUAL 2

@interface PVOItemDetail : NSObject <NSCopying>
{
    int pvoItemID;
    int pvoLoadID;
    int itemID;
    int roomID;
    int cartonContentID;
    
    int tagColor;
    
    BOOL cartonContents;
    BOOL noExceptions;
    int quantity;
    
//    NSString *comments;
    NSString *lotNumber;
    NSString *itemNumber;
    
    int year;
    NSString *make;
    NSString *modelNumber;
    NSString *serialNumber;
    int odometer;
    NSString *caliberGauge;
    
    NSString *voidReason;
    NSString *verifyStatus;
    
    //an array of PVOConditionEntries
    NSArray *damage;
    
    BOOL itemIsDeleted;
    BOOL itemIsDelivered;
    
    double highValueCost;
    
    double cube;
    int weight;
    int weightType;
    
    BOOL hasDimensions;
    int length;
    int width;
    int height;
    int dimensionUnitType;
    
    BOOL inventoriedAfterSignature;
    
    BOOL received;
    
    BOOL itemIsMPRO;
    BOOL itemIsSPRO;
    BOOL itemIsCONS;
    
    BOOL doneWorking;
    BOOL lockedItem;
    
    int wireframeType;
}

@property(nonatomic) int pvoItemID;
@property(nonatomic) int itemID;
@property(nonatomic) int pvoLoadID;
@property(nonatomic) int roomID;
@property(nonatomic) int cartonContentID;
@property(nonatomic) int tagColor;
@property(nonatomic) BOOL cartonContents;
@property(nonatomic) BOOL noExceptions;
@property(nonatomic) int quantity;
@property(nonatomic) BOOL itemIsDeleted;
@property(nonatomic) BOOL itemIsDelivered;
@property(nonatomic) BOOL inventoriedAfterSignature;
@property(nonatomic) double highValueCost;
@property(nonatomic) double cube;
@property(nonatomic) int weight;
@property(nonatomic) int weightType;
@property(nonatomic) BOOL received;

@property(nonatomic) BOOL hasDimensions;
@property(nonatomic) int length;
@property(nonatomic) int width;
@property(nonatomic) int height;
@property(nonatomic) int dimensionUnitType;

//used for atlasnet currently to indicate if the carton is provided or if the customer already had it (shows on packing services report)
@property(nonatomic) BOOL isCPProvided;

@property (nonatomic, strong) NSArray *damage;
//@property (nonatomic, retain) NSString *comments;
@property (nonatomic, strong) NSString *lotNumber;
@property (nonatomic, strong) NSString *itemNumber;
@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSString *modelNumber;
@property (nonatomic, strong) NSString *securitySealNumber;
@property (nonatomic, strong) NSString *voidReason;
@property (nonatomic, strong) NSString *verifyStatus;
@property (nonatomic, strong) NSString *packerInitials;

@property(nonatomic) int year;
@property(nonatomic) int odometer;
@property(nonatomic) BOOL itemIsMPRO;
@property(nonatomic) BOOL itemIsSPRO;
@property(nonatomic) BOOL itemIsCONS;
@property (nonatomic, strong) NSString *make;
@property (nonatomic, strong) NSString *caliberGauge;

@property(nonatomic) BOOL doneWorking;
@property(nonatomic) BOOL lockedItem;
@property(nonatomic) int wireframeType;

+(NSString*)paddedItemNumber:(NSString*)original;

-(PVOItemDetail*)initWithStatement:(sqlite3_stmt*)stmnt;
-(NSString*)displayInventoryNumber;
-(NSString*)fullItemNumber;
-(NSString*)displayInventoryNumberAndItemName;
-(NSString*)quickSummaryText;
-(NSComparisonResult)compareWithItemNumberAndLot:(PVOItemDetail*)otherItem;

-(void)flushToXML:(XMLWriter*)retval;
-(void)flushToXML:(XMLWriter*)retval withCartonContentDescription:(NSString *)ccDescription;

-(void)updateCube;

@end
