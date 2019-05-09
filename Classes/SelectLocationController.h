//
//  SelectLocationController.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EditAddressController.h"

@class SurveyLocation;
@class SelectLocationController;

@protocol SelectLocationControllerDelegate <NSObject>
@optional
-(void)locationSelected:(SelectLocationController*)controller withLocation:(SurveyLocation*)location;
-(BOOL)shouldDismiss:(SelectLocationController*)controller;
@end


@interface SelectLocationController : UITableViewController <UIActionSheetDelegate> {
	NSInteger locationID;
	NSMutableArray *locations;
	EditAddressController *editAddressController;
    
	BOOL goingToLocation;
    
    id<SelectLocationControllerDelegate> delegate;
}

@property (nonatomic) NSInteger locationID;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, retain) EditAddressController *editAddressController;
@property (nonatomic, retain) id<SelectLocationControllerDelegate> delegate;

-(void)locationSelected:(SurveyLocation*)location;

-(IBAction)cancel:(id)sender;

@end
