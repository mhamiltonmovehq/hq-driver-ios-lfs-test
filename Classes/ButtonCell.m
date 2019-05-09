//
//  ButtonCell.m
//  Survey
//
//  Created by Tony Brame on 6/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ButtonCell.h"


@implementation ButtonCell

@synthesize callback, caller, cmdButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		
	}
	return self;
}


-(IBAction)buttonPress:(id)sender
{
	if([caller respondsToSelector:callback])
	{
		[caller performSelector:callback];
		//[caller performSelector:callback withObject:item];
	}
	
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
