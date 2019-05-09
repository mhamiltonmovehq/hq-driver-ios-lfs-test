//
//  AccMiniStoEditController.h
//  Survey
//
//  Created by Tony Brame on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MiniStorage.h"

@interface AccMiniStoEditController : UITableViewController {
	MiniStorage *storage;
}

@property (nonatomic, retain) MiniStorage *storage;

-(IBAction)locationChanged:(id)sender;
-(IBAction)weightChanged:(NSString*)weight;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
