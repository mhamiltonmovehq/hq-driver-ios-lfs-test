//
//  ItemType.m
//  Survey
//
//  Created by Lee Zumstein on 2/7/14.
//
//

#import "ItemType.h"

@implementation ItemType

@synthesize allowedItems, hiddenItems;


-(void)addAllowedItemTypes:(NSSet *)itemTypes
{
    if (itemTypes != nil && [itemTypes count] > 0) {
        for (NSNumber *itemType in [itemTypes objectEnumerator]) {
            [self addAllowedItemType:[itemType intValue]];
        }
    }
}
-(void)addAllowedItemType:(int)itemType
{
    if (allowedItems == nil)
        allowedItems = [[NSMutableArray alloc] init];
    if (![allowedItems containsObject:[NSNumber numberWithInt:itemType]])
        [allowedItems addObject:[NSNumber numberWithInt:itemType]];
}
-(void)removeAllowedItemTypes:(NSSet *)itemTypes
{
    if (allowedItems != nil)
    {
        for (NSNumber *itemType in [itemTypes objectEnumerator]) {
            [self removeAllowedItemType:[itemType intValue]];
        }
    }
}
-(void)removeAllowedItemType:(int)itemType
{
    if (allowedItems != nil)
    {
        if ([allowedItems containsObject:[NSNumber numberWithInt:itemType]])
            [allowedItems removeObject:[NSNumber numberWithInt:itemType]];
    }
}
-(BOOL)isAllowedItemType:(int)itemType
{
    if (allowedItems != nil)
        return [allowedItems containsObject:[NSNumber numberWithInt:itemType]];
    return NO;
}

-(void)addHiddenItemTypes:(NSSet *)itemTypes
{
    if (itemTypes != nil && [itemTypes count] > 0) {
        for (NSNumber *itemType in [itemTypes objectEnumerator]) {
            [self addHiddenItemType:[itemType intValue]];
        }
    }
}
-(void)addHiddenItemType:(int)itemType
{
    if (hiddenItems == nil)
        hiddenItems = [[NSMutableArray alloc] init];
    if (![hiddenItems containsObject:[NSNumber numberWithInt:itemType]])
        [hiddenItems addObject:[NSNumber numberWithInt:itemType]];
}
-(void)removeHiddenItemTypes:(NSSet *)itemTypes
{
    if (hiddenItems != nil)
    {
        for (NSNumber *itemType in [itemTypes objectEnumerator]) {
            [self removeHiddenItemType:[itemType intValue]];
        }
    }
}
-(void)removeHiddenItemType:(int)itemType
{
    if (hiddenItems != nil)
    {
        if ([hiddenItems containsObject:[NSNumber numberWithInt:itemType]])
            [hiddenItems removeObject:[NSNumber numberWithInt:itemType]];
    }
}
-(BOOL)isHiddenItemType:(int)itemType
{
    if (hiddenItems != nil)
        return [hiddenItems containsObject:[NSNumber numberWithInt:itemType]];
    return NO;
}

@end
