//
//  SurveyCustomer.h
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyLocation.h"
#import "XMLWriter.h"

enum PRICING_MODE_TYPE {
    INTERSTATE = 0,
    LOCAL = 1,
    CNCIV = 2,
    CNGOV = 3
};

enum INVENTORY_TYPE {
    STANDARD = 0,
    AUTO = 1,
    BOTH = 2
};

@interface SurveyCustomer : NSObject {
    int custID;
    NSString *lastName;
    NSString *firstName;
    NSString *companyName;
    NSString *email;
    int weight;
    int cancelled;
    enum PRICING_MODE_TYPE pricingMode;
    enum INVENTORY_TYPE inventoryType;
    NSString *originCompletionDate;
    NSString *destinationCompletionDate;
}

@property (nonatomic) int cancelled;
@property (nonatomic) int custID;
@property (nonatomic) int weight;
@property (nonatomic) enum PRICING_MODE_TYPE pricingMode;
@property (nonatomic) enum INVENTORY_TYPE inventoryType;

@property (nonatomic, strong) NSString *originCompletionDate;
@property (nonatomic, strong) NSString *destinationCompletionDate;

@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *companyName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *lastSaveToServerDate;

- (void)flushToXML:(XMLWriter*)xml;
-(NSString *)getFormattedLastSaveToServerDate:(BOOL)withTime;

- (BOOL)isCanadianGovernmentCustomer;
- (BOOL)isCanadianNonGovernmentCustomer;
- (BOOL)isCanadianCustomer;
+ (BOOL)isCanadianCustomer;

@end
