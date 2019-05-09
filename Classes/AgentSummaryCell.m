//
//  AgentSummaryCell.m
//  Survey
//
//  Created by Tony Brame on 7/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AgentSummaryCell.h"


@implementation AgentSummaryCell

@synthesize labelCity, labelCode, labelName, labelHeader;

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
