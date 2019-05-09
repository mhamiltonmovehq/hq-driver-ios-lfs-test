//
//  PVOValInitialController.h
//  Survey
//
//  Created by Tony Brame on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

//creating a delegate for ipad to know when sig is completed
@class PVOValInitialController;
@protocol PVOValInitialControllerDelegate <NSObject>
@optional
-(void)initialsEntered:(PVOValInitialController*)initialController;
@end


@interface PVOValInitialController : UIViewController {
    IBOutlet UILabel *labelValAmountDed;
    IBOutlet UILabel *labelValCost;
    IBOutlet UISwitch *switchExValue;
    IBOutlet UISegmentedControl *segmentValType;
    id<PVOValInitialControllerDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UILabel *labelValAmountDed;
@property (nonatomic, retain) IBOutlet UILabel *labelValCost;
@property (nonatomic, retain) IBOutlet UISwitch *switchExValue;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentValType;
@property (nonatomic, retain) id<PVOValInitialControllerDelegate> delegate;

-(IBAction)continue_Clicked:(id)sender;

@end
