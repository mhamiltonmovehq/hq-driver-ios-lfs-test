//
//  ButtonCell.h
//  Survey
//
//  Created by Tony Brame on 6/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ButtonCell : UITableViewCell {
	SEL callback;
	NSObject *caller;
	IBOutlet UIButton *cmdButton;
}

@property (nonatomic) SEL callback;
@property (nonatomic, retain) NSObject *caller;
@property (nonatomic, retain) UIButton *cmdButton;

-(IBAction)buttonPress:(id)sender;

@end
