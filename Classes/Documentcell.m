//
//  DocumentCell.m
//  Survey
//
//  Created by DThomas on 8/11/14.
//
//

#import "DocumentCell.h"

@implementation DocumentCell

@synthesize tboxCheck, tboxDocuments, tboxDocumentsLabel;

//- (void)awakeFromNib
//{
//    // Initialization code
//}

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
