//
//  MenuItemCell.m
//  RestaurantTemplate
//
//  Created by Tony Brame on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AutoSizeLabelCell.h"

@implementation AutoSizeLabelCell

@synthesize labelDescription, text;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

+(float)sizeOfCellForText:(NSString*)text;
{
    //desc label size is 23, total size is 296 x 37, desc label is 280 wide
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:17] 
                                 constrainedToSize:CGSizeMake(280, 6000) 
                                     lineBreakMode:NSLineBreakByWordWrapping];
    
    float toresize = 0;
    if(textSize.height > 23)
    {
        toresize = textSize.height - 23;
    }
    
    return 37 + toresize;
}

-(void)setText:(NSString *)newText
{
    if(text != newText)
    {
        text = newText;
        
        //resize view accordingly.  get height of description, and resize the difference of that 
        //height and the current height of the label (resize cell and label)
        CGSize textSize = [text sizeWithFont:labelDescription.font 
                           constrainedToSize:CGSizeMake(labelDescription.frame.size.width, 6000) 
                               lineBreakMode:NSLineBreakByWordWrapping];
        
        /*if(textSize.height > labelDescription.frame.size.height)
        {*///resize accordingly...
        //always resize
        //origsize should be one line...
        float oneLineHeight = [@"A" sizeWithFont:labelDescription.font 
                                         forWidth:labelDescription.frame.size.width
                                    lineBreakMode:NSLineBreakByWordWrapping].height;
    
        float toresize = textSize.height - labelDescription.frame.size.height;
        CGRect current = labelDescription.frame;
        current.size.height += toresize;
        labelDescription.frame = current;
        
        [labelDescription setNumberOfLines:round(current.size.height/oneLineHeight)]; 
        
        current = self.frame;
        current.size.height += toresize;
        self.frame = current;
        
        labelDescription.text = text;
        
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
