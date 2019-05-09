//
//  PVOBulkyInventoryItem.m
//  Survey
//
//  Created by Justin on 7/6/16.
//
//

#import "PVOBulkyInventoryItem.h"
#import "SurveyAppDelegate.h"
#import "SurveyImage.h"

@implementation PVOBulkyInventoryItem

-(PVOBulkyInventoryItem*)initWithStatement:(sqlite3_stmt*)stmnt
{
    self = [super init];
    if(self)
    {
        int counter = -1;
        self.pvoBulkyItemID = sqlite3_column_int(stmnt, ++counter);
        self.custID = sqlite3_column_int(stmnt, ++counter);
        self.pvoBulkyItemTypeID = sqlite3_column_int(stmnt, ++counter);
        self.wireframeTypeID = sqlite3_column_int(stmnt, ++counter);
        
    }
    return self;
}

-(void)flushToXML:(XMLWriter*)xml
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [xml writeStartElement:@"bulky_item"];
    [xml writeAttribute:@"name" withData:[del.pricingDB getPVOBulkyTypeDescription:self.pvoBulkyItemTypeID]];
    
    [xml writeElementString:@"bulky_ID" withIntData:self.pvoBulkyItemID];
    
    [xml writeElementString:@"wireframe_type" withIntData:self.wireframeTypeID];
    
    NSArray *dynamicBulkyValues = [del.surveyDB getPVOBulkyData:self.pvoBulkyItemID];
    [xml writeStartElement:@"bulky_data_entries"];
    for (PVOBulkyData *entry in dynamicBulkyValues) {
        [entry flushToXML:xml];
    }
    [xml writeEndElement];
    
    if (self.wireframeTypeID == WT_PHOTO_AUTO)
    {
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        
        //for image view types, get all the images, loop through them, and print the damages that belong to that image.
        NSArray *imagePaths = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_PVO_VEHICLE_DAMAGES withSubID:VT_PHOTO loadAllItems:NO];
        for (SurveyImage *surveyImage in imagePaths)
        {
            NSString *inDocsPath = surveyImage.path;
            NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
            
            UIImage *current = [[UIImage alloc] initWithContentsOfFile:fullPath];
            
            //start vehicle damage
            [xml writeStartElement:@"wireframe_damages"];
            
            //start vehicle wireframe
            [xml writeStartElement:@"bulky_wireframe"];
            
            [xml writeAttribute:@"fileName" withData:[inDocsPath lastPathComponent]];
            [xml writeAttribute:@"height" withIntData:current.size.height];
            [xml writeAttribute:@"width" withIntData:current.size.width];
            
            //end vehicle wireframe
            [xml writeEndElement];
            
            //get all the damages for this vehicle, filter below
            NSArray *allDamages = [del.surveyDB getWireframeDamages:self.pvoBulkyItemID withImageID:surveyImage.imageID withIsVehicle:NO];
            for (PVOWireframeDamage *damage in allDamages)
            {
                [damage flushToXML:xml withLocationType:VT_PHOTO];
            }
            
            //end vehicle damages
            [xml writeEndElement];
            
        }
    }
    else
    {
        //add all of the damages
        NSArray *allDamages = [del.surveyDB getWireframeDamages:self.pvoBulkyItemID];
        UIImage *allImage = [PVOWireframeDamage allImage:self.wireframeTypeID];
        
        //start vehicle damage
        [xml writeStartElement:@"wireframe_damages"];
        
        //start vehicle wireframe
        [xml writeStartElement:@"bulky_wireframe"];
        
        [xml writeAttribute:@"fileName" withData:[PVOWireframeDamage allImageFilename:self.wireframeTypeID]];
        [xml writeAttribute:@"height" withIntData:allImage.size.height];
        [xml writeAttribute:@"width" withIntData:allImage.size.width];
        
        //end vehicle wireframe
        [xml writeEndElement];
        
        if ([allDamages count] > 0)
        {
            for (PVOWireframeDamage *damage in allDamages)
            {
                [damage flushToXML:xml withLocationType:damage.locationType];
            }
        }
        
        //end vehicle damages
        [xml writeEndElement];
    }
    
    [xml writeEndElement];
}

-(NSString*)getFormattedDetails
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray *entries = [del.pricingDB getPVOBulkyDetailEntries:self.pvoBulkyItemTypeID];
    NSArray *datas = [del.surveyDB getPVOBulkyData:self.pvoBulkyItemID];
    
    NSMutableString *retval = [[NSMutableString alloc] init];
    for (PVOBulkyEntry *entry in entries)
    {
        for (PVOBulkyData *data in datas) {
            if (data.dataEntryID == entry.dataEntryID)
            {
                if (entry.entryDataType == RDT_TEXT && [data.textValue length] > 0)
                    [retval appendFormat:@"%@: %@; ", entry.entryName, data.textValue];
                else if (entry.entryDataType == RDT_INTEGER && data.intValue)
                    [retval appendFormat:@"%@: %d; ", entry.entryName, data.intValue];
            }
        }
    }
    
    
    return retval;
}

@end
