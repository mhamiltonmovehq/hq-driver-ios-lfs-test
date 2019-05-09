//
//  LabelTextCell.h
//  Survey
//
//  Created by Tony Brame on 9/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PVO_MOVE 20

@interface LabelTextCell : UITableViewCell {
    IBOutlet UITextField *tboxValue;
    IBOutlet UILabel *labelHeader;
}

@property (nonatomic, strong) UITextField *tboxValue;
@property (nonatomic, strong) UILabel *labelHeader;

-(void)setPVOView;

@end
