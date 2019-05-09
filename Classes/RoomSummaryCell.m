//
//  RoomSummaryCell.m
//  Survey
//
//  Created by Tony Brame on 5/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RoomSummaryCell.h"
#include <QuartzCore/QuartzCore.h>

@implementation RoomSummaryCell
@synthesize imgPhoto;

@synthesize labelSummary, labelRoomName, cmdImages;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		
	}
	return self;
}

-(void)setImage:(UIImage *)image
{
    if(image == nil)
    {
        //reset the positions for everything
        labelRoomName.frame = CGRectMake(9, 2, 279, 21);
        labelSummary.frame = CGRectMake(16, 23, 272, 22);
        imgPhoto.hidden = YES;
    }
    else 
    {
        //reset the positions for everything
        labelRoomName.frame = CGRectMake(9 + 43, 2, 279 - 43, 21);
        labelSummary.frame = CGRectMake(16 + 43, 23, 272 - 43, 22);
        imgPhoto.hidden = NO;
        [imgPhoto setImage:image];
        imgPhoto.layer.cornerRadius = 5.0;
        imgPhoto.layer.masksToBounds = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}


@end
