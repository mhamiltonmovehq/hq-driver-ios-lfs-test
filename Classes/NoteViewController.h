//
//  NoteViewController.h
//  Survey
//
//  Created by Tony Brame on 5/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonNotesController.h"
#import "PVOBaseTableViewController.h"

#define NOTE_TYPE_ITEM 0
#define NOTE_TYPE_CUSTOMER 1
#define NOTE_TYPE_THIRD_PARTY 2
//dont give them an option to go to common notes
#define NOTE_TYPE_NONE 3

@interface NoteViewController : PVOBaseTableViewController <UITextViewDelegate>
	//<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
	NSString *destString;
	NSString *description;
	NSString *navTitle;
	UITextView *tboxCurrent;
	SEL callback;
	NSObject *caller;
	UIKeyboardType keyboard;
	//BOOL clearOnEdit;
	BOOL dismiss;
    BOOL modalView;
	int noteType;
    int maxLength;
	CommonNotesController *commonNotes;
	
	UIPopoverController *popover;
}

@property (nonatomic) SEL callback;
@property (nonatomic) UIKeyboardType keyboard;
//@property (nonatomic) BOOL clearOnEdit;
@property (nonatomic) BOOL dismiss;
@property (nonatomic) BOOL modalView;
@property (nonatomic) int noteType;
@property (nonatomic) int maxLength;

@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) NSString *destString;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *navTitle;
@property (nonatomic, retain) UITextView *tboxCurrent;
@property (nonatomic, retain) CommonNotesController *commonNotes;
@property (nonatomic, retain) UIPopoverController *popover;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

-(void)addStringToNote:(NSString*)note;

@end
