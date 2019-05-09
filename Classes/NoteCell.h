//
//  NoteCell.h
//  Survey
//
//  Created by Tony Brame on 8/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"

@interface NoteCell : UITableViewCell {
    IBOutlet UIPlaceHolderTextView *tboxNote;
}

@property (nonatomic, strong) UIPlaceHolderTextView *tboxNote;

@end
