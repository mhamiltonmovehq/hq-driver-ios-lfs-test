//
//  Item.h
//  Survey
//
//  Created by Tony Brame on 5/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define ITEM_COLUMN_ITEMID 0
#define ITEM_COLUMN_ITEMNAME 1
#define ITEM_COLUMN_ITEMISCP 2
#define ITEM_COLUMN_ITEMISPBO 3
#define ITEM_COLUMN_ITEMISCRATE 4
#define ITEM_COLUMN_ITEMISISBULKY 5
#define ITEM_COLUMN_ITEMCUBE 6
#define ITEM_COLUMN_ITEMBULKYID 7
#define ITEM_COLUMN_ITEMISVEHICLE 8
#define ITEM_COLUMN_ITEMISGUN 9
#define ITEM_COLUMN_ITEMISELECTRONIC 10

@interface Item : NSObject {
    int itemID;
    NSString *name;
    double cube;
    int isCP;
    int isPBO;
    int isCrate;
    int isBulky;
    int cartonBulkyID;
    int isVehicle;
    int isGun;
    int isElectronic;
    NSString *CNItemCode;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nameFrench;

@property (nonatomic) int itemID;
@property (nonatomic) double cube;
@property (nonatomic) int isCP;
@property (nonatomic) int isPBO;
@property (nonatomic) int isCrate;
@property (nonatomic) int isBulky;
@property (nonatomic) int cartonBulkyID;
@property (nonatomic) int isVehicle;
@property (nonatomic) int isGun;
@property (nonatomic) int isElectronic;
@property (nonatomic) int isHidden;
@property (nonatomic, strong) NSString *CNItemCode;

-(NSString*)cubeString;

+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix;
+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID;
+(NSString*)getItemSelectString:(int)customerID itemListID:(int)itemListID languageCode:(int)languageCode withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID;
-(Item*)initWithStatement:(sqlite3_stmt*)stmnt;
+(NSMutableDictionary*) getDictionaryFromItemList: (NSArray*)items;
+(NSString*) formatCube: (double)cube;
-(NSComparisonResult)sortByName:(Item*)otherItem;
+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix ignoreItemListId:(BOOL)ignore;
+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID ignoreItemListId:(BOOL)ignore;


@end
