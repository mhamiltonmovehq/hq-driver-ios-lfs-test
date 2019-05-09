//
//  NoteCell.m
//  Survey
//
//  Created by Tony Brame on 8/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NoteCell.h"


@implementation NoteCell

@synthesize tboxNote;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        tboxNote.placeholder = nil;
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
