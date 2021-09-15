//
//  Activation.h
//  Survey
//
//  Created by Tony Brame on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACTIVATION_NO_ACCESS 0
#define ACTIVATION_CUSTS 1
#define ACTIVATION_DOWNLOAD 2


#define TRIAL_DAYS 30
//has to reach out to within this number of days
#define CHECK_INTERVAL 30

@interface Activation : NSOperation {
    
}

@property (nonatomic) BOOL success;
@property (nonatomic) BOOL allowDevice;
@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic) BOOL deviceIDMatches;
@property (nonatomic) int vanlineDownloadID;
@property (nonatomic) int pricingVersion;
@property (nonatomic, strong) NSString *pricingDownloadLocation;
@property (nonatomic) int milesVersion;
@property (nonatomic, strong) NSString *milesDownloadLocation;
@property (nonatomic) BOOL pastTrial;
@property (nonatomic) BOOL resetTrial;
@property (nonatomic, strong) NSString *activatedFunctionality;
@property (nonatomic) BOOL ignoreUpdates;
@property (nonatomic) BOOL allowAutoInv;
@property (nonatomic) int fileAssociationId;

//determines if the user can access the application
//called first - will return true to continue, error string, or nil for no error (no user creds)
+(int)allowAccess:(NSString**)results;

//+(BOOL)isInTrial;

//+(NSDate*)trialStartDate;

@end
