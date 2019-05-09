//
//  DoubleSwitchCell.m
//  Survey
//
//  Created by Lee Zumstein on 3/3/14.
//
//

#import "DoubleSwitchCell.h"

@implementation DoubleSwitchCell

@synthesize label1, label2, switch1, switch2;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
