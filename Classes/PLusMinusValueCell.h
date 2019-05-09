//
//  PLusMinusValueCell.h
//  Survey
//
//  Created by Tony Brame on 9/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PlusMinusValueCell : UITableViewCell {
	IBOutlet UILabel *labelValue;
	
	NSString *label;
	int val;
	
	id parent;
	SEL updateQuantity;
}

@property (nonatomic) int val;
@property (nonatomic) SEL updateQuantity;

@property (nonatomic, retain) id parent;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) UILabel *labelValue;

-(IBAction)buttonPressed:(id)sender;
-(void)updateValueLabel;

@end
