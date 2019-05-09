//
//  PVOVehicle.h
//  MobileMover
//
//  Created by David Yost on 9/14/15.
//
//

#import <Foundation/Foundation.h>
#import "PVOWireframeDamage.h"
#import "XMLWriter.h"

enum
{
    WT_CAR = 1,
    WT_TRUCK, //2
    WT_SUV, //3
    WT_PHOTO_AUTO, //4
    WT_GRAND_PIANO, //5
    WT_MOTORCYCLE, //6
    WT_PIANO, //7,
    WT_ORGAN
} WIREFRAME_TYPES;


enum
{
    VT_TOP,
    VT_FRONT,
    VT_REAR,
    VT_LEFT,
    VT_RIGHT,
    VT_PHOTO
} VIEW_TYPES;

enum
{
    IT_NONE,
    IT_BACKUP,
    IT_DESTINATION_BOL,
    IT_ORIGIN_BOL
} INSPECTION_TYPES;

@interface PVOVehicle : NSObject
{
    int vehicleID;
    int customerID;
    int wireframeType;
    int inspectionType;
    double declaredValue;
    int serverID;
    
    NSString *type;
    NSString *year;
    NSString *make;
    NSString *model;
    NSString *color;
    NSString *vin;
    NSString *license;
    NSString *licenseState;
    NSString *odometer;
    
    NSMutableArray *damages;
}

@property (nonatomic) int vehicleID;
@property (nonatomic) int customerID;
@property (nonatomic) int wireframeType;
@property (nonatomic) int inspectionType;
@property (nonatomic) double declaredValue;
@property (nonatomic) int serverID;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *year;
@property (nonatomic, strong) NSString *make;
@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *vin;
@property (nonatomic, strong) NSString *license;
@property (nonatomic, strong) NSString *licenseState;
@property (nonatomic, strong) NSString *odometer;
@property (nonatomic, strong) NSMutableArray *damages;

//-(NSString*)fileBaseName;
//+(NSString*)fileBaseName:(int)wireFrameTypeID;
//-(NSString*)allImageFilename;
//+(NSString*)allImageFilename:(int)wireFrameTypeID;
//-(UIImage*)allImage;
//+(UIImage*)allImage:(int)wireFrameTypeID;
//-(UIImage*)topImage;
//-(UIImage*)leftImage;
//-(UIImage*)rightImage;
//-(UIImage*)rearImage;
//-(UIImage*)frontImage;

//-(BOOL)hasDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType;
//-(void)removeDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType;
//-(void)addDamage:(PVOWireframeDamage*)d atLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imgID withIsOrigin:(BOOL)isOrigin;
//-(PVOWireframeDamage*)getDamageAtLocation:(CGPoint)loc forType:(int)locationType andVehicleID:(int)vehID withImageID:(int)imageID;

//-(CGPoint)translateLocationInImageToLocationInView:(CGPoint)locInImage withViewSize:(CGSize)viewSize andImage:(UIImage*)image;
//-(CGPoint)translateLocationInViewToLocationInImage:(CGPoint)viewLocation withViewSize:(CGSize)viewSize andImage:(UIImage*)image;

//-(NSArray*)originDamages;
//-(NSArray*)destinationDamages;
+(BOOL)verifyAllVehiclesAreSigned:(int)customerID withIsOrigin:(BOOL)isOrigin;
+(BOOL)verifyAllVehiclesAreSigned:(int)customerID withVehicles:(NSArray*)vehicles withIsOrigin:(BOOL)isOrigin;

-(void)flushToXML:(XMLWriter*)xml;

@end
