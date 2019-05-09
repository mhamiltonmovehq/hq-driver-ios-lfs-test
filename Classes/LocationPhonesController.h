//
//  LocationPhonesController.h
//  Survey
//
//  Created by Tony Brame on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditPhoneController.h"

@interface LocationPhonesController : UITableViewController {
    int locationID;
    int custID;
    
    NSMutableArray *phones;
    EditPhoneController *phoneController;
}

@property (nonatomic) int locationID;
@property (nonatomic) int custID;

@property (nonatomic, strong) NSMutableArray *phones;
@property (nonatomic, strong) EditPhoneController *phoneController;

@end
