//
//  DateRangeCell.m
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DateRangeCell.h"


@implementation DateRangeCell

@synthesize labelType, labelFromDate, labelToDate, labelPreferDate, switchNoDates, labelStaticToDate, labelStaticFromDate, labelStaticPreferDate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        labelPreferDate.hidden = YES;
        labelStaticPreferDate.hidden = YES;
    }
    return self;
}

-(IBAction)switchNoDatesValueChanged:(id)sender
{
    labelFromDate.hidden = !switchNoDates.on;
    labelToDate.hidden = !switchNoDates.on;
    labelPreferDate.hidden = !switchNoDates.on;
    labelStaticFromDate.hidden = !switchNoDates.on;
    labelStaticToDate.hidden = !switchNoDates.on;
    labelStaticPreferDate.hidden = !switchNoDates.on;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
