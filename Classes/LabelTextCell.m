//
//  LabelTextCell.m
//  Survey
//
//  Created by Tony Brame on 9/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LabelTextCell.h"


@implementation LabelTextCell

@synthesize tboxValue, labelHeader;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
    }
    return self;
}

-(void)setPVOView
{
    CGRect myframe = tboxValue.frame;
    myframe.origin.x -= PVO_MOVE;
    myframe.size.width += PVO_MOVE;
    tboxValue.frame = myframe;
    
    myframe = labelHeader.frame;
    myframe.size.width -= PVO_MOVE;
    labelHeader.frame = myframe;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
