//
//  PVONavigationCategory.h
//  Survey
//
//  Created by Tony Brame on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVONavigationCategory : NSObject
{
    int categoryID;
    NSString *description;
}

@property (nonatomic) int categoryID;
@property (nonatomic, strong) NSString *description;

@end
