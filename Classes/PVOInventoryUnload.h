//
//  PVOInventoryUnload.h
//  Survey
//
//  Created by Tony Brame on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PVOInventoryLoad.h"

@interface PVOInventoryUnload : PVOInventoryLoad
{
    NSMutableArray *loadIDs;
}

@property (nonatomic, strong) NSMutableArray *loadIDs;

@end
