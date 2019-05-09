//
//  PVOVerifyInventoryItem.h
//  Survey
//
//  Created by Tony Brame on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PVOVerifyInventoryItem : NSObject
{
    int custID;
    //only used as a holder for the list item on the select loads screen
    NSString *orderNumber;
    NSString *serialNumber;
    NSString *articleDescription;
}

@property (nonatomic) int custID;
@property (nonatomic, retain) NSString *serialNumber;
@property (nonatomic, retain) NSString *orderNumber;
@property (nonatomic, retain) NSString *articleDescription;

@end
