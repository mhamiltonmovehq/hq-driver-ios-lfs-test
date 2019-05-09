//
//  PurgeController.h
//  Survey
//
//  Created by Tony Brame on 10/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PurgeController : UITableViewController <UIActionSheetDelegate> {
	NSDate *purge;
}

@property (nonatomic, retain) NSDate *purge;

-(IBAction)dateSelected:(NSDate*)date;
-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
