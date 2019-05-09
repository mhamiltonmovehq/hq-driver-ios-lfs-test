//
//  PVOWireframeDamage.h
//  MobileMover
//
//  Created by David Yost on 9/14/15.
//
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface PVOWireframeDamage : NSObject
{
    int damageID;
    int vehicleID;
    int locationType;
    int imageID;

    NSString *description;
    NSString *comments;
    NSString *damageAlphaCodes;
    CGPoint damageLocation;
    
    BOOL isOriginDamage;
    BOOL isAutoInventory;
}

+(NSArray*)getAllDamages;

@property (nonatomic) int damageID;
@property (nonatomic) int vehicleID;
@property (nonatomic) int locationType;
@property (nonatomic) int imageID;
@property (nonatomic) BOOL isOriginDamage;
@property (nonatomic) BOOL isAutoInventory;
@property (nonatomic) CGPoint damageLocation;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *comments;
@property (nonatomic, strong) NSString *damageAlphaCodes;

+(NSString*)getAlphaCodeFromEnum:(NSString*)enumeration;
//+(NSString*)getDescriptionFromCode:(NSString*)enumeration;
+(PVOWireframeDamage*)initWithID:(int)code alphaCode:(NSString*)alphacode andDescription:(NSString*)desc;
-(CGPoint)getLocationOfDamageInAllView;
+(NSString*)getXMLDamageEnum:(NSString*)dmg;
-(void)updateLocationTypeAndXYToSingleImage;
-(NSArray*)allDamages;
-(void)addDamage:(NSString*)damage;
-(void)removeDamage:(NSString*)damage;
-(NSComparisonResult)compare:(PVOWireframeDamage*)d;

-(void)flushToXML:(XMLWriter*)xml withLocationType:(int)locationTypeID;

+(NSArray*)originDamages:(NSArray*)damages;
+(NSArray*)destinationDamages:(NSArray*)damages;
+(NSArray*)getDamages:(NSArray*)damages atOrigin:(BOOL)isOrigin;

+(BOOL)hasDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType;
+(void)removeDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType;
+(void)addDamage:(PVOWireframeDamage*)d withDamageList:(NSMutableArray*)damages atLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imgID withIsOrigin:(BOOL)isOrigin;
+(PVOWireframeDamage*)getDamageAtLocation:(CGPoint)loc withDamageList:(NSMutableArray*)damages forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imageID;

+(NSString*)fileBaseName:(int)wireFrameTypeID;
+(NSString*)allImageFilename:(int)wireFrameTypeID;
+(UIImage*)allImage:(int)wireFrameTypeID;
+(UIImage*)topImage:(int)wireFrameTypeID;
+(UIImage*)leftImage:(int)wireFrameTypeID;
+(UIImage*)rightImage:(int)wireFrameTypeID;
+(UIImage*)rearImage:(int)wireFrameTypeID;
+(UIImage*)frontImage:(int)wireFrameTypeID;

//wireframe and images methods I moved out of PVOVehicle and into this for generification
+(CGPoint)translateLocationInViewToLocationInImage:(CGPoint)viewLocation withViewSize:(CGSize)viewSize andImage:(UIImage*)image;
+(CGPoint)translateLocationInImageToLocationInView:(CGPoint)locInImage withViewSize:(CGSize)viewSize andImage:(UIImage*)image;

+(BOOL)wireframeTypeSupportsSingleImage:(int)wireframeTypeID;

@end
