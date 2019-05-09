//
//  PVOClaimItem.h
//  Survey
//
//  Created by Tony Brame on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 [self updateDB:@"CREATE TABLE PVOClaimItems (PVOClaimID INT, PVOItemID INT"
 "Description TEXT, EstimatedWeight INT, AgeOrDatePurchased TEXT, OriginalCost REAL,"
 "ReplacementCost REAL, EstimatedRepairCost REAL)"];*/

@interface PVOClaimItem : NSObject
{
    int pvoClaimItemID;
    int pvoClaimID;
    int pvoItemID;
    NSString *description;
    int estimatedWeight;
    NSString *ageOrDatePurchased;
    double originalCost;
    double replacementCost;
    double estimatedRepairCost;
}

@property (nonatomic) int pvoClaimItemID;
@property (nonatomic) int pvoClaimID;
@property (nonatomic) int pvoItemID;
@property (nonatomic) int estimatedWeight;
@property (nonatomic) double originalCost;
@property (nonatomic) double replacementCost;
@property (nonatomic) double estimatedRepairCost;

@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *ageOrDatePurchased;

@end
