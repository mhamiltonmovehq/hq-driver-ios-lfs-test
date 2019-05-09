//
//  PopulateLabelTextCell.m
//  Survey
//
//  Created by Tony Brame on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PopulateLabelTextCell.h"


@implementation PopulateLabelTextCell

@synthesize tboxValue, labelHeader, cmdPopulate;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
