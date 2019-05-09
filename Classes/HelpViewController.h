//
//  HelpViewController.h
//  MoveManager
//
//  Created by David Yost on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDetailsSegment 0
#define kActionSegment 1

@interface HelpViewController : UIViewController {
	IBOutlet UIImageView *imageViewDetails;
	IBOutlet UIImageView *imageViewAction;
}

@property (nonatomic, retain) UIImageView *imageViewDetails;
@property (nonatomic, retain) UIImageView *imageViewAction;

- (IBAction)toggleDetailsAction:(id)sender;

-(IBAction)closeHelp:(id)sender;

@end
