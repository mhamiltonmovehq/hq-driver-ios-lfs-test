//
//  CustomerCell.m
//  Survey
//
//  Created by Tony Brame on 7/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CustomerCell.h"


@implementation CustomerCell

@synthesize labelDate, labelName;

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
