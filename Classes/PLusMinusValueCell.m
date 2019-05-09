//
//  PLusMinusValueCell.m
//  Survey
//
//  Created by Tony Brame on 9/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlusMinusValueCell.h"


@implementation PlusMinusValueCell

@synthesize labelValue;
@synthesize label;
@synthesize val, parent, updateQuantity;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)buttonPressed:(id)sender
{
    UISegmentedControl *segmentedCtl = sender;
    int incrementBy = 1;
    if(segmentedCtl.selectedSegmentIndex == 1)
        val++;
    else
    {
        if(val > 0)
        {
            incrementBy = -1;
            val--;
        }
        else
            incrementBy = 0;
    }
    
    [self updateValueLabel];
    
    if([parent respondsToSelector:updateQuantity])
    {
        [parent performSelector:updateQuantity 
                     withObject:[NSNumber numberWithInt:incrementBy]
                     withObject:[NSNumber numberWithInt:self.tag] ];
    }
}

-(void)updateValueLabel
{
    labelValue.text = [NSString stringWithFormat:@"%d %@", val, label];
}



@end
