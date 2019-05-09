//
//  TextCell.m
//  Survey
//
//  Created by Tony Brame on 5/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell

@synthesize tboxValue;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		self.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
}


@end
