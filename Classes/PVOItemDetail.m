//
//  PVOItemDetail.m
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOItemDetail.h"
#import "SurveyDB.h"
#import "SurveyAppDelegate.h"
#import "AppFunctionality.h"
#import "SyncGlobals.h"
#import "SurveyImage.h"
#import "Base64.h"

@implementation PVOItemDetail

@synthesize itemID, pvoLoadID;
@synthesize roomID;
@synthesize cartonContentID;
@synthesize lotNumber, itemNumber, pvoItemID;
@synthesize damage;

@synthesize tagColor;
@synthesize cartonContents;
@synthesize noExceptions, itemIsDeleted;
@synthesize quantity, itemIsDelivered;
@synthesize highValueCost, cube, weight, weightType;
@synthesize serialNumber, modelNumber, voidReason, verifyStatus, inventoriedAfterSignature;
@synthesize received;

@synthesize hasDimensions;
@synthesize length;
@synthesize width;
@synthesize height;
@synthesize dimensionUnitType;

@synthesize itemIsMPRO, itemIsSPRO, itemIsCONS;
@synthesize year, make, odometer, caliberGauge;
@synthesize wireframeType;
@synthesize doneWorking, lockedItem;

-(id)init
{
    self = [super init];
    if(self)
    {
        quantity = 1;
        self.isCPProvided = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    PVOItemDetail *copy = [[PVOItemDetail alloc] init];
    
    copy.itemID = itemID;
    copy.pvoLoadID = pvoLoadID;
    copy.roomID = roomID;
    copy.cartonContentID = cartonContentID;
    copy.lotNumber = lotNumber;
    copy.itemNumber = itemNumber;
    copy.damage = damage;
    copy.tagColor = tagColor;
    copy.cartonContents = cartonContents;
    copy.noExceptions = noExceptions;
    copy.itemIsDeleted = itemIsDeleted;
    copy.quantity = quantity;
    copy.itemIsDelivered = itemIsDelivered;
//    copy.comments = comments;
    copy.serialNumber = serialNumber;
    copy.modelNumber = modelNumber;
    copy.voidReason = voidReason;
    copy.weightType = weightType;
    copy.cube = cube;
    copy.length = length;
    copy.width = width;
    copy.height = height;
    copy.weight = weight;
    copy.dimensionUnitType = dimensionUnitType;
    copy.verifyStatus = verifyStatus;
    copy.inventoriedAfterSignature = inventoriedAfterSignature;
    copy.received = received;
    copy.itemIsMPRO = itemIsMPRO;
    copy.itemIsSPRO = itemIsSPRO;
    copy.itemIsCONS = itemIsCONS;
    copy.year = year;
    copy.make = make;
    copy.odometer = odometer;
    copy.caliberGauge = caliberGauge;
    copy.doneWorking = doneWorking;
    copy.lockedItem = lockedItem;
    
    return copy;
}


+(NSString*)paddedItemNumber:(NSString*)original
{
    if(original == nil)
        return @"";
    
    NSMutableString *itemNumberToSave = [[NSMutableString alloc] initWithString:original];
    while([itemNumberToSave length] < 3)
        [itemNumberToSave insertString:@"0" atIndex:0];
    
    return itemNumberToSave;
}

-(PVOItemDetail*)initWithStatement:(sqlite3_stmt*)stmnt
{
    self = [super init];
    if(self)
    {
        int counter = -1;
        self.pvoItemID = sqlite3_column_int(stmnt, ++counter);
        self.pvoLoadID = sqlite3_column_int(stmnt, ++counter);
        self.itemID = sqlite3_column_int(stmnt, ++counter);
        self.roomID = sqlite3_column_int(stmnt, ++counter);
        self.tagColor = sqlite3_column_int(stmnt, ++counter);
        self.cartonContents = sqlite3_column_int(stmnt, ++counter) > 0;
        self.noExceptions = sqlite3_column_int(stmnt, ++counter) > 0;
        self.quantity = sqlite3_column_int(stmnt, ++counter);
        self.lotNumber = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.itemNumber = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.itemIsDeleted = sqlite3_column_int(stmnt, ++counter) > 0;
        self.itemIsDelivered = sqlite3_column_int(stmnt, ++counter) > 0;
        self.highValueCost = sqlite3_column_double(stmnt, ++counter);
        self.serialNumber = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.modelNumber = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.voidReason = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.verifyStatus = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.hasDimensions = sqlite3_column_int(stmnt, ++counter) > 0;
        self.length = sqlite3_column_int(stmnt, ++counter);
        self.width = sqlite3_column_int(stmnt, ++counter);
        self.height = sqlite3_column_int(stmnt, ++counter);
        self.dimensionUnitType = sqlite3_column_int(stmnt, ++counter);
        self.inventoriedAfterSignature = sqlite3_column_int(stmnt, ++counter) > 0;
        self.packerInitials = [SurveyDB stringFromStatement:stmnt columnID:++counter];
        self.isCPProvided = sqlite3_column_int(stmnt, ++counter) > 0;
        self.weightType = sqlite3_column_int(stmnt, ++counter);
        self.weight = sqlite3_column_int(stmnt, ++counter);
        self.cube = sqlite3_column_double(stmnt, ++counter);
        
        int columnCount = sqlite3_column_count(stmnt);
        if (columnCount > ++counter)
        {
            if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                self.cartonContentID = sqlite3_column_int(stmnt, counter);
            if (columnCount > ++counter)
            {
                if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                    self.itemIsMPRO = sqlite3_column_int(stmnt, counter) > 0;
                if (columnCount > ++counter)
                {
                    if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                        self.itemIsSPRO = sqlite3_column_int(stmnt, counter) > 0;
                    if (columnCount > ++counter)
                    {
                        if (sqlite3_column_int(stmnt, counter) != SQLITE_NULL)
                            self.itemIsCONS = sqlite3_column_int(stmnt, counter) > 0;
                        if (columnCount > ++ counter)
                        {
                            if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                self.year = sqlite3_column_int(stmnt, counter);
                            if (columnCount > ++counter)
                            {
                                if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                    self.make = [SurveyDB stringFromStatement:stmnt columnID:counter];
                                if (columnCount > ++counter)
                                {
                                    if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                        self.odometer = sqlite3_column_int(stmnt, counter);
                                    if (columnCount > ++counter)
                                    {
                                        if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                            self.caliberGauge = [SurveyDB stringFromStatement:stmnt columnID:counter];
                                        if (columnCount > ++counter)
                                        {
                                            if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                                self.doneWorking = (sqlite3_column_int(stmnt, counter) > 0);
                                            if (columnCount > ++counter)
                                            {
                                                if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                                    self.lockedItem = (sqlite3_column_int(stmnt, counter) > 0);
                                                if (columnCount > ++counter)
                                                {
                                                    if (sqlite3_column_type(stmnt, counter) != SQLITE_NULL)
                                                        self.securitySealNumber = [SurveyDB stringFromStatement:stmnt columnID:counter];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return self;
}


-(NSString*)displayInventoryNumber
{
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@%@", lotNumber == nil ? @"" : lotNumber, itemNumber == nil ? @"" : itemNumber];
    while ([str length] < PVO_INVENTORY_NUMBER_CHARS) {
        [str insertString:@"0" atIndex:lotNumber == nil ? 0 : [lotNumber length]];
    }
    return str;
}


-(NSString*)displayInventoryNumberAndItemName
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    Item *i = [del.surveyDB getItem:itemID WithCustomer:del.customerID];
    NSString *retval = [NSString stringWithFormat:@"%@ - %@", [self fullItemNumber], i.name];
    return retval;
}

-(NSString*)fullItemNumber
{
    return [PVOItemDetail paddedItemNumber:itemNumber];
}

-(NSString*)quickSummaryText
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    PVOInventory *data = [del.surveyDB getPVOData:del.customerID];
    
    NSString *quickSummary = @"";
    if (self.itemID > 0)
    {
        Item *i = [del.surveyDB getItem:itemID WithCustomer:del.customerID];
        if (i != nil && i.name != nil && ![i.name isEqualToString:@""])
            quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Item: ", i.name];
    }
    if (self.roomID > 0)
    {
        Room *r = [del.surveyDB getRoom:self.roomID WithCustomerID:del.customerID];
        if (r != nil && r.roomName != nil && ![r.roomName isEqualToString:@""])
            quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Room: ", r.roomName];
    }
    if (self.tagColor > 0)
    {
        NSDictionary *colors = [del.surveyDB getPVOColors];
        if (colors != nil)
        {
            NSString *color = [colors objectForKey:[NSNumber numberWithInt:self.tagColor]];
            if (color != nil && ![color isEqualToString:@""])
                quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Tag Color: ", color];
        }
    }
    NSString *temp = [self displayInventoryNumber];
    if (temp != nil && ![temp isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Barcode: ", temp];
    if (self.itemIsDeleted && self.voidReason != nil && ![self.voidReason isEqualToString:@""])
    {
        temp = [self.voidReason stringByReplacingOccurrencesOfString:@"\r\n" withString:@" \\ "];
        temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@" \\ "];
        temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@" \\ "];
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Void Reason: ", temp];
    }
    
    if (self.pvoItemID > 0)
    {
        
        NSArray *descriptiveSymbols;
        if (self.pvoLoadID > 0)
            descriptiveSymbols = [del.surveyDB getPVOItemDescriptions:self.pvoItemID withCustomerID:del.customerID];
        else
            descriptiveSymbols = [del.surveyDB getPVOReceivableItemDescriptions:self.pvoItemID];
        
        if (descriptiveSymbols != nil && [descriptiveSymbols count] > 0)
        {
            BOOL first = YES;
            for (PVOItemDescription *pid in descriptiveSymbols)
            {
                if (pid.descriptionCode != nil && ![pid.descriptionCode isEqualToString:@""])
                {
                    if (first) quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Descriptive Symbols: "];
                    quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", first ? @"" : @", ", pid.descriptionCode];
                    first = NO;
                }
            }
        }
        
        if (self.pvoLoadID > 0) {
            if (self.damage == nil) {
                NSArray *damageHolder = [del.surveyDB getPVOItemDamage:self.pvoItemID];
                self.damage = damageHolder;
            }
        }
        else {
            
            NSArray *damageHolder = [del.surveyDB getPVOReceivableItemDamage:self.pvoItemID forDamageType:DAMAGE_LOADING];
            self.damage = damageHolder;
        }
        
        if (self.damage != nil && [self.damage count] > 0)
        {
            
            NSDictionary *pvoDamages = [del.surveyDB getPVODamageWithCustomerID:-1];
            NSDictionary *pvoDamageLocs = [del.surveyDB getPVODamageLocationsWithCustomerID:-1];
            
            quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Exceptions: "];
            BOOL firstDamageLine = YES;
            for (PVOConditionEntry *pce in damage)
            {
                BOOL first = YES;
                NSArray *locs = [pce locationArray], *dmgs = [pce conditionArray];
                if (locs != nil && [locs count] > 0)
                {
                    for (__strong NSString *l in locs)
                    {
                        l = [NSString stringWithFormat:@"%@", [pvoDamageLocs objectForKey:l]];
                        
                        if (first && !firstDamageLine) quickSummary = [quickSummary stringByAppendingString:@"; "];
                        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", (first ? @"" : @", "), l];
                        first = NO;
                    }
                }
                if (dmgs != nil && [dmgs count] > 0)
                {
                    for (__strong NSString *d in dmgs)
                    {
                        d = [NSString stringWithFormat:@"%@", [pvoDamages objectForKey:d]];
                        
                        if (first && !firstDamageLine) quickSummary = [quickSummary stringByAppendingString:@"; "];
                        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", (first ? @"" : @", "), d];
                        first = NO;
                    }
                }
                firstDamageLine = NO;
                
            }
            
        }
//        [self.damage release];
    }
    
    if (self.packerInitials != nil && ![self.packerInitials isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Packer Initials: ", self.packerInitials];
    if (self.quantity > 1)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%d", quickSummary.length > 0 ? @"\r\n" : @"", @"Quantity: ", self.quantity];
    
//    if ([AppFunctionality showCubeAndWeight:data])
//    {
        if (self.weight > 0)
            quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%d", quickSummary.length > 0 ? @"\r\n" : @"", @"Weight: ", self.weight];
        if (self.cube > 0)
            quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%f", quickSummary.length > 0 ? @"\r\n" : @"", @"Cube: ", self.cube];
//    }
    if (self.itemIsMPRO)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Item Is MPRO"];
    if (self.itemIsSPRO)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Item Is SPRO"];
    if (self.itemIsCONS)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Item is CONS"];
    if (self.highValueCost > 0)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@", quickSummary.length > 0 ? @"\r\n" : @"", [NSString stringWithFormat:@"Item Is %@",[AppFunctionality getHighValueDescription]]];
    if (self.year > 0)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%d", quickSummary.length > 0 ? @"\r\n" : @"", @"Year: ", self.year];
    if (self.make != nil && ![self.make isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Make: ", self.make];
    if (self.modelNumber != nil && ![self.modelNumber isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Model #: ", self.modelNumber];
    if (self.serialNumber != nil && ![self.serialNumber isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Serial #: ", self.serialNumber];
    if (self.odometer > 0)
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%d", quickSummary.length > 0 ? @"\r\n" : @"", @"Odometer: ", self.odometer];
    if (self.caliberGauge != nil && ![self.caliberGauge isEqualToString:@""])
        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Caliber/Gauge: ", self.caliberGauge];
//    if (self.comments != nil && ![self.comments isEqualToString:@""])
//    {
//        temp = [self.comments stringByReplacingOccurrencesOfString:@"\r\n" withString:@" \\ "];
//        temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@" \\ "];
//        temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@" \\ "];
//        quickSummary = [quickSummary stringByAppendingFormat:@"%@%@%@", quickSummary.length > 0 ? @"\r\n" : @"", @"Comments: ", temp];
//    }
    
    //[data release];
    
    return quickSummary;
}

-(NSComparisonResult)compareWithItemNumberAndLot:(PVOItemDetail*)otherItem
{
    if (([self itemNumber] == nil || [[self itemNumber] isEqualToString:@""]) ||
        (otherItem.itemNumber == nil || [otherItem.itemNumber isEqualToString:@""]))
    {
        if ([self itemNumber] == nil || [[self itemNumber] isEqualToString:@""])
            return (NSComparisonResult)NSOrderedAscending;
        else if (otherItem.itemNumber == nil || [otherItem.itemNumber isEqualToString:@""])
            return (NSComparisonResult)NSOrderedDescending;
        return (NSComparisonResult)NSOrderedSame;
    }
    if ([[self itemNumber] intValue] > [otherItem.itemNumber intValue]) {
        return (NSComparisonResult)NSOrderedDescending;
    }
    
    if ([[self itemNumber] intValue] < [otherItem.itemNumber intValue]) {
        return (NSComparisonResult)NSOrderedAscending;
    }
    
    if ([[self lotNumber] intValue] > [otherItem.lotNumber intValue]) {
        return (NSComparisonResult)NSOrderedDescending;
    }
    
    if ([[self lotNumber] intValue] < [otherItem.lotNumber intValue]) {
        return (NSComparisonResult)NSOrderedAscending;
    }
    
    return (NSComparisonResult)NSOrderedSame;

}

-(void)flushToXML:(XMLWriter*)retval
{
    [self flushToXML:retval withCartonContentDescription:nil];
}

-(void)flushToXML:(XMLWriter*)retval withCartonContentDescription:(NSString *)ccDescription
{
    NSArray *cartonContentsHolder, *descriptiveSymbols, *itemComments;
    Item *i;
    PVOCartonContent *content;
    //NSData *sigData;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDictionary *pvoDamages = [del.surveyDB getPVODamageWithCustomerID:del.customerID];
    NSDictionary *pvoDamageLocations = [del.surveyDB getPVODamageLocationsWithCustomerID:del.customerID];
    
    NSDictionary *colors = [del.surveyDB getPVOColors];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    i = [del.surveyDB getItem:self.itemID WithCustomer:del.customerID];
    
    if (self.cartonContentID > 0)
        [retval writeStartElement:@"carton_content"];
    else
        [retval writeStartElement:@"item"];
    
    [retval writeAttribute:@"is_carton" withData:i.isCrate ? @"true" : @"false"];
    [retval writeAttribute:@"is_cp" withData:i.isCP ? @"true" : @"false"];
    [retval writeAttribute:@"is_pbo" withData:i.isPBO ? @"true" : @"false"];
    [retval writeAttribute:@"is_delivered" withData:self.itemIsDelivered ? @"true" : @"false"];
    [retval writeAttribute:@"is_deleted" withData:self.itemIsDeleted ? @"true" : @"false"];
    [retval writeAttribute:@"is_vehicle" withData:i.isVehicle ? @"true" : @"false"];
    [retval writeAttribute:@"is_gun" withData:i.isGun ? @"true" : @"false"];
    [retval writeAttribute:@"is_electronic" withData:i.isElectronic ? @"true" : @"false"];
    [retval writeAttribute:@"is_mpro" withData:self.itemIsMPRO ? @"true" : @"false"];
    [retval writeAttribute:@"is_spro" withData:self.itemIsSPRO ? @"true" : @"false"];
    [retval writeAttribute:@"is_cons" withData:self.itemIsCONS ? @"true" : @"false"];
    if (i.isCP)
    {
        [retval writeAttribute:@"is_provided" withData:self.isCPProvided ? @"true" : @"false"];
    }
    
    [retval writeElementString:@"weight_type" withIntData:self.weightType];
    [retval writeElementString:@"weight" withIntData:self.weight];
    
    
    if (i.isCP)
    {
        [retval writeStartElement:@"cube"];
        [retval.file appendString:[NSString stringWithFormat:@"%f", self.cube]];
        [retval writeEndElement];
    }
    else
        [retval writeElementString:@"cube" withDoubleData:self.cube];
    
    
    if (ccDescription != nil && ccDescription.length > 0)
        [retval writeElementString:@"description" withData:ccDescription];
    
    [retval writeElementString:@"article_name" withData:i.name];
    
    if(self.packerInitials != nil && self.packerInitials.length > 0)
        [retval writeElementString:@"packer_initials" withData:self.packerInitials];
    
    [retval writeElementString:@"quantity" withIntData:self.quantity];
    [retval writeElementString:@"lot_number" withData:self.lotNumber];
    [retval writeElementString:@"item_number" withData:self.itemNumber];
    [retval writeElementString:@"barcode" withData:[self displayInventoryNumber]];
//    [retval writeElementString:@"notes" withData:comments];
    itemComments = [del.surveyDB getAllPVOItemCommentsForItem:self.pvoItemID];
    [retval writeStartElement:@"comments"];
    for (PVOItemComment *comment in itemComments) {
        [comment flushToXML:retval];
    }
    [retval writeEndElement];
    
    if(self.inventoriedAfterSignature)
        [retval writeElementString:@"inventory_after_customer_sign" withData:@"true"];
    
    if(i.isCrate || ([AppFunctionality showCrateDimensionsForCartonContent] && self.cartonContentID > 0))
    {
        [retval writeElementString:@"has_dimensions" withData:self.hasDimensions ? @"true" : @"false"];
        if(self.hasDimensions)
        {
            [retval writeElementString:@"length" withIntData:self.length];
            [retval writeElementString:@"width" withIntData:self.width];
            [retval writeElementString:@"height" withIntData:self.height];
            if (self.dimensionUnitType > 0)
                [retval writeElementString:@"dimension_unit_type" withIntData:self.dimensionUnitType];
        }
    }
    
    if (self.year > 0)
        [retval writeElementString:@"year" withIntData:self.year];
    if (self.make != nil)
        [retval writeElementString:@"make" withData:self.make];
    
    [retval writeElementString:@"model_number" withData:self.modelNumber];
    [retval writeElementString:@"serial_number" withData:self.serialNumber];
    [retval writeElementString:@"security_seal_number" withData:self.securitySealNumber];
    
    if (self.odometer > 0)
        [retval writeElementString:@"odometer" withIntData:self.odometer];
    if (self.caliberGauge != nil)
        [retval writeElementString:@"caliber_gauge" withData:self.caliberGauge];
    [retval writeElementString:@"void_reason" withData:self.voidReason];
    
    [retval writeElementString:@"tag_color"
                      withData:[colors
                                objectForKey:[NSNumber numberWithInt:self.tagColor]]];
    
//    //old carton contents
//    cartonContents = [del.surveyDB getPVOCartonContents:self.pvoItemID];
//    [retval writeStartElement:@"carton_contents"];
//    for (NSNumber *contentID in cartonContents) {
//        content = [del.surveyDB getPVOCartonContent:[contentID intValue]];
//        [retval writeElementString:@"description" withData:content.description];
//        
//    }
//    //end carton_contents
//    [retval writeEndElement];
//    
    
    //carton contents
    cartonContentsHolder = [del.surveyDB getPVOCartonContents:self.pvoItemID withCustomerID:-1];
    [retval writeStartElement:@"carton_contents"];
    for (PVOCartonContent *contentID in cartonContentsHolder) {
        content = [del.surveyDB getPVOCartonContent:contentID.contentID withCustomerID:del.customerID];
        PVOItemDetail *contentDetail = [del.surveyDB getPVOCartonContentItem:contentID.cartonContentID];
        if (contentDetail != nil)
            [contentDetail flushToXML:retval withCartonContentDescription:content.description];
        else
        {//write content with description only
            [retval writeStartElement:@"carton_content"];
            [retval writeElementString:@"description" withData:content.description];
            [retval writeEndElement];
        }
    }
    [retval writeEndElement];
    
    //pit in descriptive things
    [retval writeStartElement:@"descriptive_symbols"];
    descriptiveSymbols = [del.surveyDB getPVOItemDescriptions:self.pvoItemID withCustomerID:del.customerID];
    for (PVOItemDescription *pid in descriptiveSymbols) {
        [retval writeStartElement:@"symbol"];
        [retval writeAttribute:@"code" withData:pid.descriptionCode];
        [retval writeAttribute:@"description" withData:pid.description];
        [retval writeEndElement];
    }
    //end descriptive_symbols
    [retval writeEndElement];
    
    //and item damage
    self.damage = [del.surveyDB getPVOItemDamage:self.pvoItemID];
    
    for (PVOConditionEntry *entry in damage) {
        [retval writeStartElement:@"inventory_damage"];
        
        for (NSString *condy in [entry conditionArray]) {
            [retval writeStartElement:@"damage"];
            [retval writeAttribute:@"code" withData:condy];
            [retval writeAttribute:@"description" withData:[pvoDamages objectForKey:condy]];
            [retval writeEndElement];
        }
        
        for (NSString *loc in [entry locationArray]) {
            [retval writeStartElement:@"location"];
            [retval writeAttribute:@"code" withData:loc];
            [retval writeAttribute:@"description" withData:[PVOConditionEntry pluralizeLocation:pvoDamageLocations withKey:loc]];
            [retval writeEndElement];
        }
        
        switch (entry.damageType) {
            case DAMAGE_LOADING:
                [retval writeElementString:@"process_type" withData:@"Loading"];
                break;
            case DAMAGE_UNLOADING:
                [retval writeElementString:@"process_type" withData:@"Unloading"];
                break;
            case DAMAGE_RIDER:
                [retval writeElementString:@"process_type" withData:@"Rider"];
                break;
        }
        
        //end inventory_damage
        [retval writeEndElement];
    }
    
    
    //add high value
    if(self.highValueCost > 0)
    {
        [retval writeStartElement:@"high_value"];
        [retval writeElementString:@"cost" withData:[SurveyAppDelegate formatDouble:self.highValueCost]];
        
        //initials
        if ([AppFunctionality grabHighValueInitials])
        {
            NSArray *highValueInitials = [del.surveyDB getAllPVOHighValueInitials:self.pvoItemID];
            NSData *sigData;
            for (PVOHighValueInitial *pvoinit in highValueInitials)
            {
                sigData = UIImagePNGRepresentation([SyncGlobals removeUnusedImageSpace:[pvoinit signatureData]]);
                if(sigData != nil && sigData.length > 0)
                {
                    [retval writeStartElement:@"initial"];
                    switch (pvoinit.pvoSigTypeID) {
                        case PVO_HV_INITIAL_TYPE_PACKER:
                            [retval writeAttribute:@"type" withData:@"OriginPacker"];
                            break;
                        case PVO_HV_INITIAL_TYPE_CUSTOMER:
                            [retval writeAttribute:@"type" withData:@"OriginShipper"];
                            break;
                        case PVO_HV_INITIAL_TYPE_DEST_CUSTOMER:
                            [retval writeAttribute:@"type" withData:@"DestinationShipper"];
                            break;
                    }
             
                    [retval writeElementString:@"image" withData:[Base64 encode64WithData:sigData]];
                    [retval writeElementString:@"dateTime" withData:[dateFormatter stringFromDate:[NSDate date]]];
                    [retval writeEndElement];
                }
                //[sigData release];
             }
        }
        
        //end high_value
        [retval writeEndElement];
    }
    
    if(self.itemIsDeleted)
        [retval writeElementString:@"deleted_reason" withData:self.voidReason];
    
    
    if ([AppFunctionality addImageLocationsToXML])
    {
        NSArray *itemImages = [del.surveyDB getImagesList:del.customerID
                                            withPhotoTypes:[NSArray arrayWithObjects:[NSNumber numberWithInt:IMG_PVO_ITEMS], [NSNumber numberWithInt:IMG_PVO_DESTINATION_ITEMS], nil]
                                            withSubID:self.pvoItemID loadAllItems:NO loadAllForType:NO];
        
        [retval writeStartElement:@"images"];
        for (SurveyImage *image in itemImages)
        {
            NSFileManager *mgr = [NSFileManager defaultManager];
            
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            if([mgr fileExistsAtPath:[docsDir stringByAppendingString:image.path]])
            {
                [retval writeStartElement:@"image"];
                [retval writeAttribute:@"location" withData:[NSString stringWithFormat:@"%@",[SurveyAppDelegate getLastTwoPathComponents:image.path]]];
                [retval writeAttribute:@"photoType" withIntData:image.photoType];
                if (image.photoType == IMG_PVO_DESTINATION_ITEMS)
                    [retval writeAttribute:@"description" withData:@"Dest."];
                [retval writeEndElement]; //end image
            }
            
        }
        [retval writeEndElement]; //end images
        
    }
    [retval writeEndElement];
    
    
}

-(void)updateCube {
    if(self.dimensionUnitType == 0) {
        self.cube = 0.0;
        return;
    }
    
    int multiplied = self.length * self.width * self.height;
    
    if(self.dimensionUnitType == 1) { // Inches
        self.cube = ceil(multiplied / 1728.0);
    } else if(self.dimensionUnitType == 2) { // Feet
        self.cube = multiplied;
    } else if(self.dimensionUnitType == 3) { // Centimeters
        self.cube = ceil(multiplied / 28316.847);
    } else if(self.dimensionUnitType == 4) { // Meters
        self.cube = ceil(multiplied * 35.315);
    }
}

@end
