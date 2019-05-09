//
//  PVORoomConditions.h
//  Survey
//
//  Created by Tony Brame on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVORoomConditions : NSObject
{
    int roomConditionsID;
    int pvoLoadID;
    int pvoUnloadID;
    int roomID;
    int floorTypeID;
    BOOL hasDamage;
    NSString *damageDetail;
}

@property (nonatomic) int roomConditionsID;
@property (nonatomic) int pvoLoadID;
@property (nonatomic) int pvoUnloadID;
@property (nonatomic) int roomID;
@property (nonatomic) int floorTypeID;
@property (nonatomic) BOOL hasDamage;
@property (nonatomic, retain) NSString *damageDetail;

@end
