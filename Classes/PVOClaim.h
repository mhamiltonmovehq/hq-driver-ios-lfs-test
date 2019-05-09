//
//  PVOClaim.h
//  Survey
//
//  Created by Tony Brame on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 [self updateDB:@"CREATE TABLE PVOClaims (PVOClaimID INTEGER PRIMARY KEY, CustomerID INT, ClaimDate REAL, "
 "EmployerPaidFor INT, EmployerName TEXT, ShipmentInWarehouse INT, AgencyCode TEXT)"];
 */
@interface PVOClaim : NSObject
{
    int pvoClaimID;
    int customerID;
    NSDate *claimDate;
    bool employerPaid;
    NSString *employer;
    bool shipmentInWarehouse;
    NSString *agencyCode;
}

@property (nonatomic) int pvoClaimID;
@property (nonatomic) int customerID;
@property (nonatomic, retain) NSDate *claimDate;
@property (nonatomic) bool employerPaid;
@property (nonatomic, retain) NSString *employer;
@property (nonatomic) bool shipmentInWarehouse;
@property (nonatomic, retain) NSString *agencyCode;

@end
