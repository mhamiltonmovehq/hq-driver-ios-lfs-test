//
//  SwitchCell.m
//  Survey
//
//  Created by Tony Brame on 8/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SwitchCell.h"


@implementation SwitchCell

@synthesize labelHeader, switchOption;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}



@end
