//
//  PVORoomSummary.h
//  Survey
//
//  Created by Tony Brame on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Room.h"

@interface PVORoomSummary : NSObject {
    int numberOfItems;
    Room *room;
    int weight;
    double cube;
}

@property (nonatomic) int numberOfItems;
@property (nonatomic) double cube;
@property (nonatomic) int weight;
@property (nonatomic, retain) Room *room;

@end
