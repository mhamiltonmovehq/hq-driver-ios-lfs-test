//
//  PVOActionTimes.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PVOActionTimes : NSObject


@property (nonatomic) int pvoActionTimesId;
@property (nonatomic) int customerId;
@property (nonatomic, retain) NSDate* origStarted;
@property (nonatomic, retain) NSDate* origArrived;
@property (nonatomic, retain) NSDate* destStarted;
@property (nonatomic, retain) NSDate* destArrived;

@end

NS_ASSUME_NONNULL_END
