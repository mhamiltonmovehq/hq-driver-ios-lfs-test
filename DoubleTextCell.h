//
//  DoubleTextCell.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DoubleTextCell : UITableViewCell {
    IBOutlet UITextField *tboxLeft;
    IBOutlet UITextField *tboxRight;
}

@property (nonatomic, strong) UITextField *tboxLeft;
@property (nonatomic, strong) UITextField *tboxRight;

@end
