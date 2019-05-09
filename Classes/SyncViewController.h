//
//  SyncViewController.h
//  Survey
//
//  Created by Tony Brame on 7/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProcessSync.h"
#import "PVOSync.h"

@interface SyncViewController : UIViewController {
	IBOutlet UITextView *tboxProgress;
	IBOutlet UIActivityIndicatorView *activity;
	IBOutlet UIBarButtonItem *cmdCancel;
	IBOutlet UIBarButtonItem *cmdOK;
	ProcessSync *synchronization;
    
    PVOSync *pvoSync;
	
	BOOL downloadCustomItemLists;
}

@property (nonatomic) BOOL downloadCustomItemLists;

@property (nonatomic, retain) UITextView *tboxProgress;
@property (nonatomic, retain) ProcessSync *synchronization;
@property (nonatomic, retain) PVOSync *pvoSync;
@property (nonatomic, retain) UIActivityIndicatorView *activity;
@property (nonatomic, retain) UIBarButtonItem *cmdCancel;
@property (nonatomic, retain) UIBarButtonItem *cmdOK;

-(IBAction)cancelSync:(id)sender;
-(IBAction)okPressed:(id)sender;
-(void)syncCompleted;
-(void)syncError;

-(void)updateProgress:(NSString*)textToAdd;

-(BOOL)validateSettings;

@end
