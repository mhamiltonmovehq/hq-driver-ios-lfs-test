//
//  ItemType.h
//  Survey
//
//  Created by Lee Zumstein on 2/7/14.
//
//

#import <Foundation/Foundation.h>

enum ITEM_TYPES {
    ITEM_TYPE_CP = 1,
    ITEM_TYPE_PBO = 2,
    ITEM_TYPE_CRATE = 3,
    ITEM_TYPE_BULKY = 4,
    ITEM_TYPE_VEHICLE = 5,
    ITEM_TYPE_GUN = 6,
    ITEM_TYPE_ELECTRONIC = 7
};

@interface ItemType : NSObject {
    NSMutableArray *allowedItems;
    NSMutableArray *hiddenItems;
}

@property(nonatomic,strong) NSMutableArray *allowedItems;
@property(nonatomic,strong) NSMutableArray *hiddenItems;

-(void)addAllowedItemTypes:(NSSet *)itemTypes;
-(void)addAllowedItemType:(int)itemType;
-(void)removeAllowedItemTypes:(NSSet *)itemTypes;
-(void)removeAllowedItemType:(int)itemType;
-(BOOL)isAllowedItemType:(int)itemType;

-(void)addHiddenItemTypes:(NSSet *)itemTypes;
-(void)addHiddenItemType:(int)itemType;
-(void)removeHiddenItemTypes:(NSSet *)itemTypes;
-(void)removeHiddenItemType:(int)itemType;
-(BOOL)isHiddenItemType:(int)itemType;

@end
