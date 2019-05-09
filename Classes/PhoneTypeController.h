//
//  PhoneTypeController.h
//  Survey
//
//  Created by Tony Brame on 5/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhoneType.h"

@interface PhoneTypeController : UITableViewController {
    NSMutableArray *types;
    NSIndexPath *lastIndexPath;
    PhoneType *selectedType;
    //PhoneType *prevType;
    NSInteger originalTypeID;
    NSInteger locationID;
}

@property (nonatomic, strong) NSMutableArray *types;
@property (nonatomic, strong) NSIndexPath *lastIndexPath;
@property (nonatomic, strong) PhoneType *selectedType;
@property (nonatomic) NSInteger originalTypeID;
@property (nonatomic) NSInteger locationID;

-(IBAction) newPhoneTypeEntered: (NSString*)newType;

@end
