//
//  AdditionalEmailsTableViewCell.m
//  Survey
//
//  Created by Collin Sims on 1/17/17.
//
//

#import "EmailTableViewCell.h"

@implementation EmailTableViewCell
@synthesize emailInput, sendEmailBtn;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.emailInput.autocorrectionType = UITextAutocorrectionTypeNo;
        self.emailInput.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.emailInput.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailInput.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
