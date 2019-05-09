//
//  CNGOVSignatureValidation.m
//  Survey
//
//  Created by Brian Prescott on 11/14/17.
//

#import "CNGOVSignatureValidation.h"

#import "AppFunctionality.h"
#import "SurveyAppDelegate.h"
#import "SurveyDB.h"
#import "SurveyedItemsList.h"

@implementation CNGOVSignatureValidation

- (BOOL)validate:(int)customerID
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *surveyedItems = [del.surveyDB getAllSurveyedItems:customerID];
    NSMutableDictionary *surveyedItemDict = [NSMutableDictionary dictionary];
    for (SurveyedItemsList *siList in surveyedItems)
    {
        NSDictionary *dict = siList.list;
        for (NSString *k in [dict allKeys])
        {
            SurveyedItem *item = dict[k];
            Item *i = [del.surveyDB getItem:item.itemID WithCustomer:customerID];
            NSString *itemName = i.name;
            if ([itemName length] > 0)
            {
                if ([surveyedItemDict valueForKey:itemName] == nil)
                {
                    surveyedItemDict[itemName] = @(item.shipping);
                }
                else
                {
                    surveyedItemDict[itemName] = @([surveyedItemDict[itemName] intValue] + item.shipping);
                }
            }
        }
    }
    
    //NSLog(@"Surveyed item dict: %@", surveyedItemDict);

    NSArray *pvoLocations = [del.surveyDB getPVOLocationsForCust:customerID];
    NSArray *pvoRooms;
    NSMutableArray *inventoriedItems = [NSMutableArray array];
    for (PVOInventoryLoad *currentLoad in pvoLocations)
    {
        pvoRooms = [del.surveyDB getPVORooms:currentLoad.pvoLoadID withDeletedItems:YES andConditionOnly:[AppFunctionality includeEmptyRoomsInXML] withCustomerID:del.customerID];
        for (PVORoomSummary *sum in pvoRooms)
        {
            NSArray *pvoItems = [del.surveyDB getPVOItems:currentLoad.pvoLoadID forRoom:sum.room.roomID];
            if ([pvoItems count] > 0)
            {
                [inventoriedItems addObjectsFromArray:pvoItems];
                for (PVOItemDetail *detail in pvoItems)
                {
                    Item *item = [del.surveyDB getItem:detail.itemID WithCustomer:customerID];
                    if ([item.name length] > 0)
                    {
                        if (surveyedItemDict[item.name] != nil)
                        {
                            int ctr = [surveyedItemDict[item.name] intValue];
                            ctr -= detail.quantity;
                            if (ctr < 0) ctr = 0;
                            surveyedItemDict[item.name] = @(ctr);
                        }
                    }
                }
            }
        }
    }

    //NSLog(@"Surveyed item dict after removing intentoried items: %@", surveyedItemDict);

    // check to make sure all surveyed items counts are zero
    BOOL isOK = YES;
    for (NSString *key in [surveyedItemDict allKeys])
    {
        if ([surveyedItemDict[key] intValue] > 0)
        {
            isOK = NO;
        }
    }
    
    return isOK;
}

@end
