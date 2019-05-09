//
//  PVOVehicle.m
//  MobileMover
//
//  Created by David Yost on 9/14/15.
//
//

#import "PVOVehicle.h"
#import "SurveyAppDelegate.h"
#import "SurveyImage.h"

@implementation PVOVehicle

@synthesize vehicleID, customerID, wireframeType, inspectionType, declaredValue, serverID;
@synthesize type, year, make, model, color, vin, license, licenseState, odometer;
@synthesize damages;

-(id)init
{
    self = [super init];
    
    if(self != nil)
    {
        serverID = -1; //NOTE: vehicles added on the device will have a -1 server id...
        damages = [[NSMutableArray alloc] init];
    }
    
    return self;
}


//-(NSString*)fileBaseName
//{
//    return [PVOVehicle fileBaseName:wireframeType];
//}
//
//+(NSString*)fileBaseName:(int)wireFrameTypeID
//{
//    if(wireFrameTypeID == WT_CAR)
//        return @"car";
//    else if(wireFrameTypeID == WT_TRUCK)
//        return @"truck";
//    else if(wireFrameTypeID == WT_SUV)
//        return @"suv";
//    else
//        return nil;
//}
//
//-(NSString*)allImageFilename
//{
//    return [NSString stringWithFormat:@"%@_all.png", [self fileBaseName]];
//}
//
//+(NSString*)allImageFilename:(int)wireFrameTypeID
//{
//    return [NSString stringWithFormat:@"%@_all.png", [self fileBaseName:wireFrameTypeID]];
//}
//
//+(UIImage*)allImage:(int)wireFrameTypeID
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_all.png", [self fileBaseName:wireFrameTypeID]]];
//}
//
//-(UIImage*)allImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_all.png", [self fileBaseName]]];
//}
//
//-(UIImage*)topImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_top.png", [self fileBaseName]]];
//}
//
//-(UIImage*)leftImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_left.png", [self fileBaseName]]];
//}
//
//-(UIImage*)rightImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_right.png", [self fileBaseName]]];
//}
//
//-(UIImage*)rearImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_rear.png", [self fileBaseName]]];
//}
//
//-(UIImage*)frontImage
//{
//    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_front.png", [self fileBaseName]]];
//}
//
//-(CGPoint)translateLocationInViewToLocationInImage:(CGPoint)viewLocation withViewSize:(CGSize)viewSize andImage:(UIImage*)image
//{
//    //get the image size,
//    //figure out the dimensions of the view size
//    //proportionately return location in view... round?
//    
//    
//    CGSize imgSize = [image size];
//        
//    return CGPointMake((viewLocation.x / viewSize.width) * imgSize.width, 
//                       (viewLocation.y / viewSize.height) * imgSize.height);
//    
//}

//-(CGPoint)translateLocationInImageToLocationInView:(CGPoint)locInImage withViewSize:(CGSize)viewSize andImage:(UIImage*)image
//{
//    //now backwards...
////    UIImage *orig = nil;
//    
////    switch (locationType) {
////        case VT_TOP:
////            orig = [self topImage];
////            break;
////        case VT_RIGHT:
////            orig = [self rightImage];
////            break;
////        case VT_LEFT:
////            orig = [self leftImage];
////            break;
////        case VT_REAR:
////            orig = [self rearImage];
////            break;
////        case VT_FRONT:
////            orig = [self frontImage];
////            break;
////    }
//    
//    CGSize imgSize = [image size];
//    
//    return CGPointMake((locInImage.x / imgSize.width) * viewSize.width, 
//                       (locInImage.y / imgSize.height) * viewSize.height);
//    
//}

//+(BOOL)hasDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType
//{
//    for (PVOWireframeDamage *dam in damages) {
//        float xDiff = fabs(dam.damageLocation.x - loc.x);
//        float yDiff = fabs(dam.damageLocation.y - loc.y);
//        
//        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
//        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
//        {
//            //if the location type is photo and the image id for the damage doesn't match continue looping...
//            if (locationType == VT_PHOTO && d.imageID != dam.imageID)
//                continue;
//            
//            for (NSString *code in [dam.damageAlphaCodes componentsSeparatedByString:@","])
//            {
//                if([code isEqualToString:d.damageAlphaCodes])
//                    return YES;
//            }
//        }
//    }
//    
//    return NO;
//}
//
//+(void)removeDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType
//{
//    PVOWireframeDamage *toRemove = nil;
//    for (PVOWireframeDamage *dam in damages) {
//        float xDiff = fabs(dam.damageLocation.x - loc.x);
//        float yDiff = fabs(dam.damageLocation.y - loc.y);
//        
//        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
//        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
//        {
//            //if the location type is photo and the image id for the damage doesn't match continue looping...
//            if (locationType == VT_PHOTO && d.imageID != dam.imageID)
//                continue;
//            
//            //loop through each...
//            NSMutableString *newCodes = [NSMutableString stringWithString:@""];
//            
//            for (NSString *code in [dam.damageAlphaCodes componentsSeparatedByString:@","]) {
//                if(![code isEqualToString:d.damageAlphaCodes])
//                {
//                    if([newCodes isEqualToString:@""])
//                        [newCodes appendString:code];
//                    else
//                        [newCodes appendFormat:@",%@", code];
//                }
//            }
//            dam.damageAlphaCodes = newCodes;
//            
//            if([dam.damageAlphaCodes isEqualToString:@""])
//                toRemove = dam;
//            
//            break;
//        }
//    }
//    
//    if(toRemove != nil && [toRemove.comments isEqualToString:@""])
//        [damages removeObject:toRemove];
//}
//
//+(void)addDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imgID withIsOrigin:(BOOL)isOrigin
//{
//    for (PVOWireframeDamage *dam in damages) {
//        float xDiff = fabs(dam.damageLocation.x - loc.x);
//        float yDiff = fabs(dam.damageLocation.y - loc.y);
//        
//        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
//        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
//        {
//            int vtPhoto = VT_PHOTO;
//            
//            //if the location type is photo and the image id for the damage doesn't match continue looping...
//            if (locationType == VT_PHOTO && imgID != dam.imageID)
//            {
//                continue;
//            }
//            
//            if([dam.damageAlphaCodes isEqualToString:@""])
//                dam.damageAlphaCodes = d.damageAlphaCodes;
//            else
//                dam.damageAlphaCodes = [dam.damageAlphaCodes stringByAppendingFormat:@",%@", d.damageAlphaCodes];
//            
//            return;
//        }
//    }
//    
//    //not found, add new record...
//    
//    PVOWireframeDamage *toadd = [[PVOWireframeDamage alloc] init];
//    toadd.damageAlphaCodes = d.damageAlphaCodes;
//    toadd.description = d.description;
//    toadd.damageLocation = loc;
//    toadd.vehicleID = vehID;
//    toadd.imageID = imgID;
//    toadd.locationType = locationType;
//    toadd.comments = @"";
//    toadd.isOriginDamage = isOrigin;
//    
//    [damages addObject:toadd];
//    
//}
//
//+(PVOWireframeDamage*)getDamageAtLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imageID
//{
//    for (PVOWireframeDamage *dam in damages) {
//        float xDiff = fabs(dam.damageLocation.x - loc.x);
//        float yDiff = fabs(dam.damageLocation.y - loc.y);
//        
//        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
//        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
//        {
//            //if the location type is photo and the image id for the damage doesn't match continue looping...
//            if (locationType == VT_PHOTO && imageID != dam.imageID)
//                continue;
//            
//            return dam;
//        }
//    }
//    
//    //not found, add new record...
//    
//    PVOWireframeDamage *toadd = [[PVOWireframeDamage alloc] init];
//    toadd.damageAlphaCodes = @"";
//    toadd.description = @"";
//    toadd.damageLocation = loc;
//    toadd.vehicleID = vehID;
//    toadd.locationType = locationType;
//    toadd.comments = @"";
//    
//    [damages addObject:toadd];
//    
//    return toadd;
//}


-(void)flushToXML:(XMLWriter*)xml
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [xml writeStartElement:@"vehicle"];
    
    [xml writeElementString:@"vehicle_id" withIntData:vehicleID];
    [xml writeElementString:@"vehicle_type" withData:type];
    [xml writeElementString:@"declared_value" withDoubleData:declaredValue];
    [xml writeElementString:@"year" withData:year];
    [xml writeElementString:@"make" withData:make];
    [xml writeElementString:@"model" withData:model];
    [xml writeElementString:@"color" withData:color];
    [xml writeElementString:@"vin" withData:vin];
    [xml writeElementString:@"license" withData:license];
    [xml writeElementString:@"license_state" withData:licenseState];
    [xml writeElementString:@"odometer" withData:odometer];
    [xml writeElementString:@"server_id" withIntData:serverID];
    
    if (wireframeType == WT_PHOTO_AUTO)
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
            [xml writeStartElement:@"vehicle_damages"];
            
            //start vehicle wireframe
            [xml writeStartElement:@"vehicle_wireframe"];
            
            [xml writeAttribute:@"fileName" withData:[inDocsPath lastPathComponent]];
            [xml writeAttribute:@"height" withIntData:current.size.height];
            [xml writeAttribute:@"width" withIntData:current.size.width];
            
            //end vehicle wireframe
            [xml writeEndElement];
            
            //get all the damages for this vehicle, filter below
            NSArray *allDamages = [del.surveyDB getVehicleDamages:vehicleID withImageID:surveyImage.imageID];
            for (PVOWireframeDamage *damage in allDamages)
            {
                //only print the damages assigned to this photo
                //if(damage.imageID == surveyImage.imageID)
                //{
                    [damage flushToXML:xml withLocationType:VT_PHOTO];
                //}
            }
            
            //end vehicle damages
            [xml writeEndElement];
            
        }
    }
    else
    {
        //add all of the damages
        NSArray *allDamages = [del.surveyDB getVehicleDamages:vehicleID];
        UIImage *allImage = [PVOWireframeDamage allImage:wireframeType];
        
        //start vehicle damage
        [xml writeStartElement:@"vehicle_damages"];
        
        //start vehicle wireframe
        [xml writeStartElement:@"vehicle_wireframe"];
        
        [xml writeAttribute:@"fileName" withData:[PVOWireframeDamage allImageFilename:wireframeType]];
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



+(BOOL)verifyAllVehiclesAreSigned:(int)customerID withIsOrigin:(BOOL)isOrigin
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *vehicles = [del.surveyDB getAllVehicles:customerID];
    
    return [self verifyAllVehiclesAreSigned:customerID withVehicles:vehicles withIsOrigin:isOrigin];
    
}

+(BOOL)verifyAllVehiclesAreSigned:(int)customerID withVehicles:(NSArray*)vehicles withIsOrigin:(BOOL)isOrigin
{
    if ([vehicles count] == 0)
        return FALSE;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    for (PVOVehicle *vehicle in vehicles)
    {
        if(vehicle != nil)
        {
            PVOSignature *sig = [del.surveyDB getPVOSignature:del.customerID forImageType:(isOrigin ? PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_ORIG : PVO_SIGNATURE_TYPE_AUTO_INVENTORY_VEHICLE_DEST) withReferenceID:vehicle.vehicleID];
            if (sig == nil)
            {
                return FALSE;
            }
        }
    }
    
    return TRUE;
}

@end
