//
//  PVOInventoryLoad.h
//  Survey
//
//  Created by Tony Brame on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 [self updateDB:@"CREATE TABLE PVOInventoryLoads (PVOLoadID INTEGER PRIMARY KEY, CustomerID INT, "
 "PVOLocationID INT, LocationID INT)"];*/

@interface PVOInventoryLoad : NSObject
{
    int pvoLoadID;
    int custID;
    int pvoLocationID;
    int locationID;
    
    //only used on the summary screen for display
    double cube;
    int weight;
    
    int receivedFromPVOLocationID;
}

@property (nonatomic) int pvoLoadID;
@property (nonatomic) int custID;
@property (nonatomic) int pvoLocationID;
@property (nonatomic) int locationID;

@property (nonatomic) double cube;
@property (nonatomic) int weight;

@property (nonatomic) int receivedFromPVOLocationID;;

@end
