//
//  ActivationRecord.h
//  Survey
//
//  Created by Tony Brame on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ActivationRecord : NSObject {
    NSDate *trialBegin;
    NSDate *lastOpen;
    NSDate *lastValidation;
    NSDate *alertNewVersionDate;
    BOOL unlocked;
    BOOL autoUnlocked; /*dyost: added new property to control auto inventory functionality */
    int pricingDBVersion;
    int fileCompany;
    int milesDBVersion;
    NSString *milesDLFolder;
    NSString *tariffDLFolder;
}

@property (nonatomic, strong) NSDate *trialBegin;
@property (nonatomic, strong) NSDate *lastOpen;
@property (nonatomic, strong) NSDate *lastValidation;
@property (nonatomic, strong) NSDate *alertNewVersionDate;
@property (nonatomic, strong) NSString *milesDLFolder;
@property (nonatomic, strong) NSString *tariffDLFolder;
@property (nonatomic) BOOL unlocked;
@property (nonatomic) BOOL autoUnlocked;
@property (nonatomic) int pricingDBVersion;
@property (nonatomic) int fileCompany;
@property (nonatomic) int milesDBVersion;
@property (nonatomic) int fileAssociationId;

@end
