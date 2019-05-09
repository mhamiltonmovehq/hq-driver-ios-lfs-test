//
//  PopulateLabelTextCell.h
//  Survey
//
//  Created by Tony Brame on 9/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PopulateLabelTextCell : UITableViewCell {
	IBOutlet UITextField *tboxValue;
	IBOutlet UIButton *cmdPopulate;
	IBOutlet UILabel *labelHeader;
}

@property (nonatomic, retain) UITextField *tboxValue;
@property (nonatomic, retain) UIButton *cmdPopulate;
@property (nonatomic, retain) UILabel *labelHeader;

@end
