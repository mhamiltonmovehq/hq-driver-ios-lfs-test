//
//  PVOActionItems.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import <UIKit/UIKit.h>
#import "PVOActionTimes.h"

NS_ASSUME_NONNULL_BEGIN

@interface PVOActionItemsController : UITableViewController

@property (nonatomic) bool isOrigin;
@property (nonatomic, retain) PVOActionTimes* actionTimes;

- (void) actionStarted:(NSDate*)newDate;
- (void) actionArrived:(NSDate*)newDate;

@end

NS_ASSUME_NONNULL_END
