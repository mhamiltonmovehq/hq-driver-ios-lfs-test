//
//  PVOReweighController.h
//  Survey
//
//  Created by Tony Brame on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PVOReweighController;
@protocol PVOReweighControllerDelegate <NSObject>
@optional
-(void)reweighDataEntered:(PVOReweighController*)reweighController;
@end

#define PVO_REWEIGH_REQUESTED 0
#define PVO_REWEIGH_REQUESTED_BY_SHIPPER 1
#define PVO_REWEIGH_WAIVED 2

@interface PVOReweighController : UITableViewController {
    id<PVOReweighControllerDelegate> delegate;
    
    BOOL requested;
    BOOL requestedByShipper;
    BOOL waived;
}

@property (nonatomic, strong) id<PVOReweighControllerDelegate> delegate;

-(IBAction)switchChanged:(id)sender;

@end
