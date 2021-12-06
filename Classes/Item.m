//
//  Item.m
//  Survey
//
//  Created by Tony Brame on 5/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Item.h"
#import "SurveyDB.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "SyncGlobals.h"
#import "SurveyImage.h"
#import "Base64.h"

@implementation Item

@synthesize itemID, name, isBulky, isCP, isPBO, isCrate, cube, cartonBulkyID, isHidden;
@synthesize isVehicle, isGun, isElectronic, CNItemCode;

+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix
{
    return [self getItemSelectString:custID withItemTablePrefix:itemTablePrefix withDescriptionTablePrefix:descriptionPrefix withRoomID:-1 ignoreItemListId:FALSE];
}

+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID {
    return [self getItemSelectString:custID withItemTablePrefix:itemTablePrefix withDescriptionTablePrefix:descriptionPrefix withRoomID:roomID ignoreItemListId:FALSE];
}

+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix ignoreItemListId:(BOOL)ignore {
    return [self getItemSelectString:custID withItemTablePrefix:itemTablePrefix withDescriptionTablePrefix:descriptionPrefix withRoomID:-1 ignoreItemListId:ignore];
}

+(NSString*)getItemSelectString:(int)custID withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID ignoreItemListId:(BOOL)ignore
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *itemListClause = @"";
    
    // OT 20830
    if(ignore) {
        if(custID != -1) {
            // Use customer language
            itemListClause = [NSString stringWithFormat:@"d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %d) AND i.ItemListID != 4",custID];
        } else {
            // Default to English
            itemListClause = [NSString stringWithFormat:@"d.LanguageCode = 0 AND NOT i.ItemListID = 4"];
        }
    } else {
        if([del.surveyDB getPVOData:del.customerID].loadType == SPECIAL_PRODUCTS)
        {
            itemListClause = @"d.LanguageCode = 0 AND i.ItemListID = 4";
        }
        else if (custID > 0)
        {
            //itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) AND i.ItemListID = (SELECT CustomItemList FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
            itemListClause = [NSString stringWithFormat:@" d.LanguageCode = (SELECT LanguageCode FROM ShipmentInfo WHERE CustomerID = %1$d) ", custID];
        }
        else
        {
            itemListClause = @" d.LanguageCode = 0 AND i.ItemListID = 0 ";
        }
    }

    NSString *cmd = [NSString stringWithFormat:@"%1$@.ItemID,%2$@.Description,%1$@.IsCartonCP,%1$@.IsCartonPBO,%1$@.IsCrate,%1$@.IsBulky,%1$@.Cube,%1$@.CartonBulkyID,"
                     " %1$@.IsVehicle,%1$@.IsGun,%1$@.IsElectronic,%1$@.Hidden"
                     " FROM Items i "
                     " INNER JOIN ItemDescription d ON %1$@.ItemID = %2$@.ItemID "
                     "%3$@"
                     " WHERE %4$@ "
                     " AND (i.CustomerID IS NULL OR i.CustomerID = %5$d) "
                     " %6$@",
                     itemTablePrefix,
                     descriptionPrefix,
                     (roomID > 0 ? @" INNER JOIN MasterItemList mil ON mil.ItemID = i.ItemID" : @""),
                     itemListClause,
                     custID,
                     (roomID > 0 ? [NSString stringWithFormat:@"AND mil.RoomID = %d", roomID] : @"")];
    
    
    return cmd;
}

+(NSString*)getItemSelectString:(int)customerID itemListID:(int)itemListID languageCode:(int)languageCode withItemTablePrefix:(NSString*)itemTablePrefix withDescriptionTablePrefix:(NSString*)descriptionPrefix withRoomID:(int)roomID
{
    NSString *itemListClause = [NSString stringWithFormat:@" d.LanguageCode = %d AND i.ItemListID = %d ", languageCode, itemListID];
    
    NSString *cmd = [NSString stringWithFormat:@"%1$@.ItemID,%2$@.Description,%1$@.IsCartonCP,%1$@.IsCartonPBO,%1$@.IsCrate,%1$@.IsBulky,%1$@.Cube,%1$@.CartonBulkyID,"
                     " %1$@.IsVehicle,%1$@.IsGun,%1$@.IsElectronic"
                     " FROM Items i "
                     " INNER JOIN ItemDescription d ON %1$@.ItemID = %2$@.ItemID "
                     "%3$@"
                     " WHERE %4$@ "
                     " AND (i.CustomerID IS NULL OR i.CustomerID = %5$d) "
                     " %6$@",
                     itemTablePrefix,
                     descriptionPrefix,
                     (roomID > 0 ? @" INNER JOIN MasterItemList mil ON mil.ItemID = i.ItemID" : @""),
                     itemListClause,
                     customerID,
                     (roomID > 0 ? [NSString stringWithFormat:@"AND mil.RoomID = %d", roomID] : @"")];

    return cmd;
}

-(Item*)initWithStatement:(sqlite3_stmt*)stmnt
{
    self = [super init];
    if(self)
    {
        int counter = -1;
        self.itemID = sqlite3_column_int(stmnt, ++counter);
        self.name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, ++counter)];
        self.isCP = sqlite3_column_int(stmnt, ++counter);
        self.isPBO = sqlite3_column_int(stmnt, ++counter);
        self.isCrate = sqlite3_column_int(stmnt, ++counter);
        self.isBulky = sqlite3_column_int(stmnt, ++counter);
        self.cube = sqlite3_column_double(stmnt, ++counter);
        self.cartonBulkyID = sqlite3_column_int(stmnt, ++counter);
        if (sqlite3_column_type(stmnt, ++counter) != SQLITE_NULL)
            self.isVehicle = sqlite3_column_int(stmnt, counter) > 0;
        if (sqlite3_column_type(stmnt, ++counter) != SQLITE_NULL)
            self.isGun = sqlite3_column_int(stmnt, counter) > 0;
        if (sqlite3_column_type(stmnt,++counter) != SQLITE_NULL)
            self.isElectronic = sqlite3_column_int(stmnt, counter) > 0;
        
    }
    return self;
}

// getDictionaryFromItemList - Gets dictionary to fill item list table view
// Inputs: NSArray of Item objects
// Outputs: NSMutableDictionary:
//              - keys are letters of the alphabet for which at least one item begins with that letter
//              - values are Item objects, in sorted order, that have the first letter of the key
+(NSMutableDictionary*) getDictionaryFromItemList: (NSArray*)items
{
    // Create dictionary - keys are letters of alphabet, values are Item objects
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    
    // To avoid crashes if you switch an existing order to STG
    if(items != nil && [items count] > 0) {
        // Create currentKey - the current letter of the alphabet that we are working with
        NSString* currentKey = nil;
        
        // Create itemsForCurrentKey - the list of items for the current key before going into the dict
        NSMutableArray* itemsForCurrentKey = [[NSMutableArray alloc] init];
        
        // Get first letter of first item to set first currentKey
        Item* firstItem = [items objectAtIndex:0];
        NSString* firstItemName = [firstItem name];
        NSString* firstItemNameUppercase = [firstItemName uppercaseString];
        
        // To avoid crashes if you switch an existing order to STG
        if(firstItemNameUppercase != nil && [firstItemNameUppercase length] > 0) {
            NSString* firstFirstChar = [firstItemNameUppercase substringToIndex:1];
            unichar firstFirstCharUni = [firstItemNameUppercase characterAtIndex:0];
            
            // If first character is not a letter, put it under #
            if(!(firstFirstCharUni >= 65 && firstFirstCharUni <= 90)) {
                currentKey = @"#";
            } else {
                // Otherwise use the first letter as the key
                currentKey = [NSString stringWithString:firstFirstChar];
            }
            
            // Iterate over items
            for(int i = 0; i < [items count]; i++) {
                // Get an item
                Item* currentItem = [items objectAtIndex:i];
                
                // Get item name
                NSString* itemName = [currentItem name];
                NSString* itemNameUppercase = [itemName uppercaseString];
                
                // To avoid crashes if you switch an existing order to STG
                if(itemNameUppercase != nil && [itemNameUppercase length] > 0) {
                    // Get first letter of name to put in correct area of tableview
                    NSString* firstChar = [itemNameUppercase substringToIndex:1];
                    unichar firstCharUni = [itemNameUppercase characterAtIndex:0];
                    
                    // Handle # key
                    if([currentKey isEqualToString:@"#"] && !(firstCharUni >= 65 && firstCharUni <= 90)) {
                        // Stay on # key, do nothing
                    } else {
                        // Move on to next key if this new first char is different than the current key
                        if (![currentKey isEqualToString:firstChar]) {
                            // Check if that key already exists - append it if so
                            if([dictionary objectForKey:currentKey] != nil) {
                                NSMutableArray* append = [dictionary objectForKey:currentKey];
                                [itemsForCurrentKey addObjectsFromArray:append];
                                
                                // Sort this key again
                                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
                                NSArray* sorted = [itemsForCurrentKey  sortedArrayUsingDescriptors:@[sort]];
                                itemsForCurrentKey = [[NSMutableArray alloc] init];
                                [itemsForCurrentKey addObjectsFromArray:sorted];
                                
                                [dictionary removeObjectForKey:currentKey];
                            }
                            
                            // Put the items for this key into the dictionary
                            [dictionary setObject:itemsForCurrentKey forKey:currentKey];
                            
                            // Reset the items for the current key
                            itemsForCurrentKey = [[NSMutableArray alloc] init];
                            
                            // Make this first char the current key
                            currentKey = [NSString stringWithString:firstChar];
                        }
                    }
                    
                    // Add the current item to the current key
                    [itemsForCurrentKey addObject:currentItem];
                    
                    if (i == ([items count] - 1)) {
                        // Check if that key already exists - append it if so
                        if([dictionary objectForKey:currentKey] != nil) {
                            NSMutableArray* append = [dictionary objectForKey:currentKey];
                            [itemsForCurrentKey addObjectsFromArray:append];
                            
                            // Sort this key again
                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
                            NSArray* sorted = [itemsForCurrentKey  sortedArrayUsingDescriptors:@[sort]];
                            itemsForCurrentKey = [[NSMutableArray alloc] init];
                            [itemsForCurrentKey addObjectsFromArray:sorted];
                            
                            [dictionary removeObjectForKey:currentKey];
                        }
                        
                        // add the remaining items to the dictionary
                        [dictionary setObject:itemsForCurrentKey forKey:currentKey];
                        
                        // Reset the items for the current key
                    }
                }
            }
        }
        
    }
    
    return dictionary;
}

-(NSComparisonResult)sortByName:(Item*)otherItem
{
    return [name compare:otherItem.name];
}

+(NSString*) formatCube: (double) cube
{
    NSString *retval;
    
    retval = [[NSString alloc] initWithFormat:@"(%@)", [[NSNumber numberWithDouble:cube] stringValue]];
    
    return retval;
}

-(NSString*)cubeString
{
    NSString *num  = [Item formatCube:cube];
    //NSString *retval = [[NSString alloc] initWithFormat:@"(%@)", num];
    //[num release];
    
    return num;
}


- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    Item *copy = [[Item alloc] init];
    
    copy->name = self->name;
    copy->_nameFrench = self->_nameFrench;
    copy->itemID = self->itemID;
    copy->cube = self->cube;
    copy->isCP = self->isCP;
    copy->isPBO = self->isPBO;
    copy->isCrate = self->isCrate;
    copy->isBulky = self->isBulky;
    copy->cartonBulkyID = self->cartonBulkyID;
    copy->isVehicle = self->isVehicle;
    copy->isGun = self->isGun;
    copy->isElectronic = self->isElectronic;
    copy->isHidden = self->isHidden;
    copy->CNItemCode = self->CNItemCode;

    return copy;
}

@end
