//
//  FloatingLabelTextCell.m
//  Survey
//
//  Created by Brian Prescott on 7/29/15.
//
//

#import "FloatingLabelTextCell.h"

@implementation FloatingLabelTextCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self commonInit];
        
        self.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tboxValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
    
    self.tboxValue.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tboxValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [super awakeFromNib];
}

- (void)commonInit
{
//    METHOD_LOG;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


@end
