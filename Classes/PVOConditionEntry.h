//
//  PVOConditionEntry.h
//  Survey
//
//  Created by Tony Brame on 3/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PVO_DAMAGE_TYPE {
    DAMAGE_LOADING = 1,
    DAMAGE_UNLOADING = 2,
    DAMAGE_RIDER = 3
};

@interface PVOConditionEntry : NSObject {
    int pvoItemID;
    int pvoDamageID;
    
    int pvoLoadID;
    int pvoUnloadID;
    
    //each is a comma delimited list of codes
    NSString *conditions;
    NSString *locations;
    
    enum PVO_DAMAGE_TYPE damageType;
}

@property (nonatomic) int pvoItemID;
@property (nonatomic) int pvoDamageID;
@property (nonatomic) int pvoLoadID;
@property (nonatomic) int pvoUnloadID;
@property (nonatomic) enum PVO_DAMAGE_TYPE damageType;

@property (nonatomic, strong) NSString *conditions;
@property (nonatomic, strong) NSString *locations;

-(NSArray*)conditionArray;
-(NSArray*)locationArray;

-(void)addCondition:(NSString*)condition;
-(void)addLocation:(NSString*)location;
-(void)removeLocation:(NSString*)location;
-(void)removeCondition:(NSString*)condition;

+(NSString*)pluralizeLocation:(NSDictionary*)locDict withKey:(NSString*)key;
+(NSString*)depluralizeLocationCode:(NSString*)code;

-(BOOL)isEmpty;
-(NSString*)getLastCondition;
-(void)removeLastCondition;
-(NSString*)getLastLocation;
-(void)removeLastLocation;
-(void)removeConditionFromArray:(NSString*)condition;
-(void)removeLocationFromArray:(NSString*)location;

@end
