//
//  SurveyPhone.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneType.h"

@interface SurveyPhone : NSObject {
    NSInteger custID;
    NSInteger locationID;
    PhoneType *type;
    NSString *number;
    int isPrimary;
}

@property (nonatomic) NSInteger custID;
@property (nonatomic) NSInteger locationID;
@property (nonatomic, strong) PhoneType *type;
@property(nonatomic, strong) NSString *number;
@property(nonatomic) int isPrimary;

@end
