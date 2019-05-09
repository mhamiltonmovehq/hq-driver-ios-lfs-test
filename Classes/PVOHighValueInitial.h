//
//  PVOHighValueInitial.h
//  Survey
//
//  Created by Tony Brame on 9/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PVOSignature.h"

enum PVO_HV_INITIAL_TYPE {
    PVO_HV_INITIAL_TYPE_PACKER = 1,
    PVO_HV_INITIAL_TYPE_CUSTOMER = 2,
    PVO_HV_INITIAL_TYPE_DEST_CUSTOMER = 3
};

@interface PVOHighValueInitial : PVOSignature
{
    int pvoItemID;
}

@property (nonatomic) int pvoItemID;

@end
