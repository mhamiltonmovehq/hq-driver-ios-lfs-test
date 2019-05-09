//
//  PVOWireframeDamage.m
//  MobileMover
//
//  Created by David Yost on 9/14/15.
//
//  This is basically deprecated, I'm going to create a new class to use thats more generic for everything else.

#import "PVOWireframeDamage.h"
#import "PVOVehicle.h"

@implementation PVOWireframeDamage

@synthesize damageID, vehicleID;
@synthesize description, comments;
@synthesize damageLocation, isOriginDamage, isAutoInventory;
@synthesize damageAlphaCodes, locationType;
@synthesize imageID;

+(PVOWireframeDamage*)initWithID:(int)code alphaCode:(NSString*)alphacode andDescription:(NSString*)desc
{
    PVOWireframeDamage *current = [[PVOWireframeDamage alloc] init];
    
    current.damageAlphaCodes = alphacode;
    current.description = desc;
    current.imageID = -1;
    
    return current;
}

-(NSArray*)allDamages
{
    return [damageAlphaCodes componentsSeparatedByString:@","];
}

-(void)addDamage:(NSString*)damage
{
    if([damageAlphaCodes isEqualToString:@""])
        self.damageAlphaCodes = damage;
    else
        self.damageAlphaCodes = [NSString stringWithFormat:@"%@,%@", damageAlphaCodes, damage];
}

-(void)removeDamage:(NSString*)damage
{
    NSMutableString *str = [NSMutableString stringWithString:damageAlphaCodes];
    //go find last occurrence...
    NSMutableString *currentD = [[NSMutableString alloc] initWithString:@""];
    
    for (int i = [str length]-1; i >= 0; i--)
    {
        if(i == 0)//be sure to get the first char, and skip commas
            [currentD appendFormat:@"%c", [str characterAtIndex:i]];
            
        if(i == 0 || [str characterAtIndex:i] == ',')
        {//check damage
            if([currentD isEqualToString:damage])
            {
                //remove it
                //get the comma too...
                if([currentD length] == [str length])//make sure there is a comma... (i.e. this would be the only damage in the list)
                    [str replaceCharactersInRange:NSMakeRange(i, [currentD length]) withString:@""];
                else
                    [str replaceCharactersInRange:NSMakeRange(i, [currentD length] + 1) withString:@""];
                
                break;
            }
            else
                [currentD setString:@""];
        }
        else
            [currentD appendFormat:@"%c", [str characterAtIndex:i]];
    }
    
    
    self.damageAlphaCodes = str;
}

+(NSString*)getAlphaCodeFromEnum:(NSString*)enumeration
{
    
    
    if([enumeration isEqualToString:@"SCRATCHED"]){
        return @"S";
    }
    else if([enumeration isEqualToString:@"GOUGED"]){
        return @"G";
    }
    else if([enumeration isEqualToString:@"BROKEN"]){
        return @"BR";
    }
    else if([enumeration isEqualToString:@"CUT"]){
        return @"C";
    }
    else if([enumeration isEqualToString:@"CHIPPED"]){
        return @"CH";
    }
    else if([enumeration isEqualToString:@"CRACKED"]){
        return @"CR";
    }
    else if([enumeration isEqualToString:@"BENT"]){
        return @"B";
    }
    else if([enumeration isEqualToString:@"BUFFER_BURNED"]){
        return @"BB";
    }
    else if([enumeration isEqualToString:@"DOOR_DING"]){
        return @"DD";
    }
    else if([enumeration isEqualToString:@"DENT"]){
        return @"D";
    }
    else if([enumeration isEqualToString:@"FADED"]){
        return @"F";
    }
    else if([enumeration isEqualToString:@"FOREIGN_FLUID"]){
        return @"FF";
    }
    else if([enumeration isEqualToString:@"LOOSE"]){
        return @"L";
    }
    else if([enumeration isEqualToString:@"MISSING"]){
        return @"M";
    }
    else if([enumeration isEqualToString:@"PITTED"]){
        return @"P";
    }
    else if([enumeration isEqualToString:@"PEELING_PAINT"]){
        return @"PP";
    }
    else if([enumeration isEqualToString:@"RUST"]){
        return @"RU";
    }
    else if([enumeration isEqualToString:@"STAINED"]){
        return @"DL";
    }
    else if([enumeration isEqualToString:@"SURFACE_SCRATCH"]){
        return @"SS";
    }
    else if([enumeration isEqualToString:@"TORN"]){
        return @"T";
    }
    else if([enumeration isEqualToString:@"TOUCH_UP_PAINT"]){
        return @"TU";
    }
    
    return @"UNKNOWN";
}


+(NSArray*)getAllDamages
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [array addObject:[PVOWireframeDamage initWithID:12 alphaCode:@"S" andDescription:@"Scratch"]];
    [array addObject:[PVOWireframeDamage initWithID:7 alphaCode:@"G" andDescription:@"Gouge"]];
    [array addObject:[PVOWireframeDamage initWithID:2 alphaCode:@"BR" andDescription:@"Broken"]];
    [array addObject:[PVOWireframeDamage initWithID:3 alphaCode:@"C" andDescription:@"Cut"]];
    [array addObject:[PVOWireframeDamage initWithID:5 alphaCode:@"CH" andDescription:@"Chip"]];
    [array addObject:[PVOWireframeDamage initWithID:6 alphaCode:@"CR" andDescription:@"Cracked"]];
    [array addObject:[PVOWireframeDamage initWithID:1 alphaCode:@"B" andDescription:@"Bent"]];
    [array addObject:[PVOWireframeDamage initWithID:50 alphaCode:@"BB" andDescription:@"Buffer Burn"]];
    [array addObject:[PVOWireframeDamage initWithID:51 alphaCode:@"DD" andDescription:@"Door Ding"]];
    [array addObject:[PVOWireframeDamage initWithID:4 alphaCode:@"D" andDescription:@"Dent"]];
    [array addObject:[PVOWireframeDamage initWithID:52 alphaCode:@"F" andDescription:@"Faded"]];
    [array addObject:[PVOWireframeDamage initWithID:53 alphaCode:@"FF" andDescription:@"Foreign Fluid"]];
    [array addObject:[PVOWireframeDamage initWithID:38 alphaCode:@"L" andDescription:@"Loose"]];
    [array addObject:[PVOWireframeDamage initWithID:8 alphaCode:@"M" andDescription:@"Missing"]];
    [array addObject:[PVOWireframeDamage initWithID:54 alphaCode:@"P" andDescription:@"Pitted"]];
    [array addObject:[PVOWireframeDamage initWithID:100 alphaCode:@"PC" andDescription:@"Paint Chip"]];
    [array addObject:[PVOWireframeDamage initWithID:55 alphaCode:@"PP" andDescription:@"Peeling Paint"]];
    [array addObject:[PVOWireframeDamage initWithID:56 alphaCode:@"RU" andDescription:@"Rust"]];
    [array addObject:[PVOWireframeDamage initWithID:101 alphaCode:@"R" andDescription:@"Rubbed"]];
    [array addObject:[PVOWireframeDamage initWithID:10 alphaCode:@"SL" andDescription:@"Soiled"]];
    [array addObject:[PVOWireframeDamage initWithID:12 alphaCode:@"SS" andDescription:@"Surface Scratches"]];
    [array addObject:[PVOWireframeDamage initWithID:12 alphaCode:@"ST" andDescription:@"Stained"]];
    [array addObject:[PVOWireframeDamage initWithID:13 alphaCode:@"T" andDescription:@"Torn"]];
    [array addObject:[PVOWireframeDamage initWithID:57 alphaCode:@"TU" andDescription:@"Touch-Up Paint"]];
    
    
    return [array sortedArrayUsingSelector:@selector(compare:)];
}

-(id)init
{
    self = [super init];
    if(self)
    {
        damageLocation = CGPointMake(0, 0);
        isOriginDamage = NO;
        isAutoInventory = NO;
    }
    return self;
}

-(NSComparisonResult)compare:(PVOWireframeDamage*)d
{
    return [self.damageAlphaCodes compare:d.damageAlphaCodes];
}

-(CGPoint)getLocationOfDamageInAllView
{
    switch (locationType) {
            //top is rotated in all view...
        case -1:
            return damageLocation;
        case VT_TOP:
            return CGPointMake(210 - damageLocation.y, damageLocation.x);
        case VT_FRONT:
            return CGPointMake(damageLocation.x, 375 + damageLocation.y);
        case VT_RIGHT:
            return CGPointMake(210 + damageLocation.x, damageLocation.y);
        case VT_LEFT:
            return CGPointMake(210 + damageLocation.x, 185 + damageLocation.y);
        case VT_REAR:
            return CGPointMake(325 + damageLocation.x, 375 + damageLocation.y);
        case VT_PHOTO:
            return CGPointMake(damageLocation.x, damageLocation.y);
    }
    return CGPointMake(0,0);
}

+(NSString*)getXMLDamageEnum:(NSString*)dmg
{
    
    if([dmg isEqualToString:@"S"]){
        return @"SCRATCHED";
    }
    else if([dmg isEqualToString:@"G"]){
        return @"GOUGED";
    }
    else if([dmg isEqualToString:@"BR"]){
        return @"BROKEN";
    }
    else if([dmg isEqualToString:@"C"]){
        return @"CUT";
    }
    else if([dmg isEqualToString:@"CH"]){
        return @"CHIPPED";
    }
    else if([dmg isEqualToString:@"CR"]){
        return @"CRACKED";
    }
    else if([dmg isEqualToString:@"B"]){
        return @"BENT";
    }
    else if([dmg isEqualToString:@"BB"]){
        return @"BUFFER_BURNED";
    }
    else if([dmg isEqualToString:@"DD"]){
        return @"DOOR_DING";
    }
    else if([dmg isEqualToString:@"D"]){
        return @"DENT";
    }
    else if([dmg isEqualToString:@"F"]){
        return @"FADED";
    }
    else if([dmg isEqualToString:@"FF"]){
        return @"FOREIGN_FLUID";
    }
    else if([dmg isEqualToString:@"L"]){
        return @"LOOSE";
    }
    else if([dmg isEqualToString:@"M"]){
        return @"MISSING";
    }
    else if([dmg isEqualToString:@"P"]){
        return @"PITTED";
    }
    else if([dmg isEqualToString:@"PP"]){
        return @"PEELING_PAINT";
    }
    else if([dmg isEqualToString:@"RU"]){
        return @"RUST";
    }
    else if([dmg isEqualToString:@"DL"]){
        return @"STAINED";
    }
    else if([dmg isEqualToString:@"SS"]){
        return @"SURFACE_SCRATCH";
    }
    else if([dmg isEqualToString:@"T"]){
        return @"TORN";
    }
    else if([dmg isEqualToString:@"TU"]){
        return @"TOUCH_UP_PAINT";
    }
    else if ([dmg isEqualToString:@"PC"]){
        return @"Paint Chip";
    }
    
    return @"UNKNOWN";
}

-(void)updateLocationTypeAndXYToSingleImage
{
    //gett the damage location, and convert to the single image x, y
    
    if(damageLocation.x <= 210 && damageLocation.y <= 375)
    {
        //no change to coords
        locationType = VT_TOP;
    }
    else if(damageLocation.x <= 325 && damageLocation.y > 375)
    {
        damageLocation.x = damageLocation.x - 375;
        locationType = VT_FRONT;
    }
    else if(damageLocation.x > 210 && damageLocation.y <= 185)
    {
        damageLocation.x = damageLocation.x - 210;
        locationType = VT_RIGHT;
    }
    else if(damageLocation.x > 210 && damageLocation.y > 185 && damageLocation.y <= 375)
    {
        damageLocation.x = damageLocation.x - 210;
        damageLocation.y = damageLocation.y - 185;
        locationType = VT_LEFT;
    }
    else if(damageLocation.x > 325 && damageLocation.y > 375)
    {
        damageLocation.x = damageLocation.x - 325;
        damageLocation.y = damageLocation.y - 375;
        locationType = VT_REAR;
    }
    
}

//passing in the locationTypeID because PHOTO type stores the ImageID in the locationTypeID
-(void)flushToXML:(XMLWriter*)xml withLocationType:(int)locationTypeID
{
    //start vehicle_damages / wireframe_damages
    if (isAutoInventory)
        [xml writeStartElement:@"vehicle_damage"];
    else
        [xml writeStartElement:@"wireframe_damage"];
    
    switch (locationTypeID) {
        case -1:
            [xml writeElementString:@"location_type" withData:@"None"];
            break;
        case VT_TOP:
            [xml writeElementString:@"location_type" withData:@"Top"];
            break;
        case VT_FRONT:
            [xml writeElementString:@"location_type" withData:@"Front"];
            break;
        case VT_REAR:
            [xml writeElementString:@"location_type" withData:@"Rear"];
            break;
        case VT_LEFT:
            [xml writeElementString:@"location_type" withData:@"Left"];
            break;
        case VT_RIGHT:
            [xml writeElementString:@"location_type" withData:@"Right"];
            break;
        case VT_PHOTO:
            [xml writeElementString:@"location_type" withData:@"Photo"];
            break;
    }
    
    
    [xml writeElementString:@"comments" withData:comments];
    [xml writeElementString:@"is_origin" withData:isOriginDamage ? @"true" : @"false"];
    
    //start location
    [xml writeStartElement:@"damage_location"];
    CGPoint loc = [self getLocationOfDamageInAllView];
    [xml writeAttribute:@"x" withDoubleData:loc.x];
    [xml writeAttribute:@"y" withDoubleData:loc.y];
    //end location
    [xml writeEndElement];
    
    NSArray *vehicleDamages = [self allDamages];
    for (NSString *code in vehicleDamages)
    {
        //start damage
        [xml writeStartElement:@"damage"];
        
        [xml writeAttribute:@"code" withData:code];
        [xml writeAttribute:@"description" withData:[PVOWireframeDamage getXMLDamageEnum:code]];
        
        //end damage
        [xml writeEndElement];
    }
    
    //end vehicle_damage
    [xml writeEndElement];
    
}

+(NSString*)fileBaseName:(int)wireFrameTypeID
{
    if(wireFrameTypeID == WT_CAR)
        return @"car";
    else if(wireFrameTypeID == WT_TRUCK)
        return @"truck";
    else if(wireFrameTypeID == WT_SUV)
        return @"suv";
    else if(wireFrameTypeID == WT_PIANO)
        return @"upright_piano";
    else if(wireFrameTypeID == WT_GRAND_PIANO)
        return @"grand_piano";
    else if(wireFrameTypeID == WT_MOTORCYCLE)
        return @"motorcycle";
    else if(wireFrameTypeID == WT_ORGAN)
        return @"organ";
    else
        return nil;
}

+(NSString*)allImageFilename:(int)wireFrameTypeID
{
    return [NSString stringWithFormat:@"%@_all.png", [self fileBaseName:wireFrameTypeID]];
}

+(UIImage*)allImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_all.png", [self fileBaseName:wireFrameTypeID]]];
}

+(UIImage*)topImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_top.png", [self fileBaseName:wireFrameTypeID]]];
}

+(UIImage*)leftImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_left.png", [self fileBaseName:wireFrameTypeID]]];
}

+(UIImage*)rightImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_right.png", [self fileBaseName:wireFrameTypeID]]];
}

+(UIImage*)rearImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_rear.png", [self fileBaseName:wireFrameTypeID]]];
}

+(UIImage*)frontImage:(int)wireFrameTypeID
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@_front.png", [self fileBaseName:wireFrameTypeID]]];
}

+(CGPoint)translateLocationInViewToLocationInImage:(CGPoint)viewLocation withViewSize:(CGSize)viewSize andImage:(UIImage*)image
{
    //get the image size,
    //figure out the dimensions of the view size
    //proportionately return location in view... round?
    
    
    CGSize imgSize = [image size];
    
    return CGPointMake((viewLocation.x / viewSize.width) * imgSize.width,
                       (viewLocation.y / viewSize.height) * imgSize.height);
    
}

+(CGPoint)translateLocationInImageToLocationInView:(CGPoint)locInImage withViewSize:(CGSize)viewSize andImage:(UIImage*)image
{
    //now backwards...    
    CGSize imgSize = [image size];
    
    return CGPointMake((locInImage.x / imgSize.width) * viewSize.width,
                       (locInImage.y / imgSize.height) * viewSize.height);
    
}

+(NSArray*)originDamages:(NSArray*)damages
{
    return [self getDamages:damages atOrigin:YES];
}

+(NSArray*)destinationDamages:(NSArray*)damages
{
    return [self getDamages:damages atOrigin:NO];
}

+(NSArray*)getDamages:(NSArray*)damages atOrigin:(BOOL)isOrigin
{
    /*NOTE: We are not using inspection types for origin/destination filtering...
     //only want damages if we are doing the destination BOL, and then only those that are not origin damages...
     if(inspectionType == IT_BACKUP || inspectionType == IT_ORIGIN_BOL)
     return [NSArray array];*/
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    for (PVOWireframeDamage *d in damages) {
        if(d.isOriginDamage == isOrigin)
        {
            [retval addObject:d];
        }
    }
    
    return retval;
}

+(BOOL)hasDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType
{
    for (PVOWireframeDamage *dam in damages) {
        float xDiff = fabs(dam.damageLocation.x - loc.x);
        float yDiff = fabs(dam.damageLocation.y - loc.y);
        
        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
        {
            //if the location type is photo and the image id for the damage doesn't match continue looping...
            if (locationType == VT_PHOTO && d.imageID != dam.imageID)
                continue;
            
            for (NSString *code in [dam.damageAlphaCodes componentsSeparatedByString:@","])
            {
                if([code isEqualToString:d.damageAlphaCodes])
                    return YES;
            }
        }
    }
    
    return NO;
}

+(void)removeDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType
{
    PVOWireframeDamage *toRemove = nil;
    for (PVOWireframeDamage *dam in damages) {
        float xDiff = fabs(dam.damageLocation.x - loc.x);
        float yDiff = fabs(dam.damageLocation.y - loc.y);
        
        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
        {
            //if the location type is photo and the image id for the damage doesn't match continue looping...
            if (locationType == VT_PHOTO && d.imageID != dam.imageID)
                continue;
            
            //loop through each...
            NSMutableString *newCodes = [NSMutableString stringWithString:@""];
            
            for (NSString *code in [dam.damageAlphaCodes componentsSeparatedByString:@","]) {
                if(![code isEqualToString:d.damageAlphaCodes])
                {
                    if([newCodes isEqualToString:@""])
                        [newCodes appendString:code];
                    else
                        [newCodes appendFormat:@",%@", code];
                }
            }
            dam.damageAlphaCodes = newCodes;
            
            if([dam.damageAlphaCodes isEqualToString:@""])
                toRemove = dam;
            
            break;
        }
    }
    
    if(toRemove != nil && [toRemove.comments isEqualToString:@""])
        [damages removeObject:toRemove];
}

+(void)addDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imgID withIsOrigin:(BOOL)isOrigin
{
    for (PVOWireframeDamage *dam in damages) {
        float xDiff = fabs(dam.damageLocation.x - loc.x);
        float yDiff = fabs(dam.damageLocation.y - loc.y);
        
        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
        {            
            //if the location type is photo and the image id for the damage doesn't match continue looping...
            if (locationType == VT_PHOTO && imgID != dam.imageID)
            {
                continue;
            }
            
            if([dam.damageAlphaCodes isEqualToString:@""])
                dam.damageAlphaCodes = d.damageAlphaCodes;
            else
                dam.damageAlphaCodes = [dam.damageAlphaCodes stringByAppendingFormat:@",%@", d.damageAlphaCodes];
            
            return;
        }
    }
    
    //not found, add new record...
    
    PVOWireframeDamage *toadd = [[PVOWireframeDamage alloc] init];
    toadd.damageAlphaCodes = d.damageAlphaCodes;
    toadd.description = d.description;
    toadd.damageLocation = loc;
    toadd.vehicleID = vehID;
    toadd.imageID = imgID;
    toadd.locationType = locationType;
    toadd.comments = @"";
    toadd.isOriginDamage = isOrigin;
    
    [damages addObject:toadd];
    
}

+(PVOWireframeDamage*)getDamageAtLocation:(CGPoint)loc withDamageList:(NSMutableArray*)damages forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imageID
{
    for (PVOWireframeDamage *dam in damages) {
        float xDiff = fabs(dam.damageLocation.x - loc.x);
        float yDiff = fabs(dam.damageLocation.y - loc.y);
        
        //NOTE: We were originally just comparing X and Y but since it's a floating point number that goes out 10 decimal places sometimes a very minute variation would trip it as a new damage location when it shouldn't which essentially created duplicates.  I've changed it so that if the difference is less than 1/1000th we assume it's the same damage location which should be plenty accurate.
        if(xDiff < 0.001 && yDiff < 0.001 && locationType == dam.locationType)
        {
            //if the location type is photo and the image id for the damage doesn't match continue looping...
            if (locationType == VT_PHOTO && imageID != dam.imageID)
                continue;
            
            return dam;
        }
    }
    
    //not found, add new record...
    
    PVOWireframeDamage *toadd = [[PVOWireframeDamage alloc] init];
    toadd.damageAlphaCodes = @"";
    toadd.description = @"";
    toadd.damageLocation = loc;
    toadd.vehicleID = vehID;
    toadd.locationType = locationType;
    toadd.comments = @"";
    
    [damages addObject:toadd];
    
    return toadd;
}

+(BOOL)wireframeTypeSupportsSingleImage:(int)wireframeTypeID
{
    switch (wireframeTypeID) {
        case WT_CAR:
        case WT_TRUCK:
        case WT_SUV:
            return YES;
            
        default:
            return NO;
    }
}


@end
