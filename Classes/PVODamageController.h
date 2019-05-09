//
//  NoteViewController.h
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PVODamageController : UITableViewController
	//<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
	UITextView *tboxCurrent;
	NSString *description;
    BOOL hasDamage;
}

@property (nonatomic, retain) UITextView *tboxCurrent;
@property (nonatomic, retain) NSString *description;

-(IBAction)switchChanged:(id)sender;

@end
