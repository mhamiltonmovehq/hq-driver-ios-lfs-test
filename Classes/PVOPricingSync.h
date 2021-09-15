//
//  PVOPricingSync.h
//  HQ Driver
//
//  Created by Bob Boatwright on 8/11/21.
//

#ifndef PVOPricingSync_h
#define PVOPricingSync_h


#endif /* PVOPricingSync_h */

#define PVO_CONTROL_VERSION  @"/pvoControlVersion";
#define PVO_CONTROL_DATA  @"/pvoControlData";


@class PVOPricingSync;
@interface PVOPricingSync : NSObject {
    
}

+(NSString*)getPVODatabaseVersion: (NSError**) error;
+(NSString*)getPVODatabaseData: (NSError**) error;
@end
