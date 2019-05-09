//
//  CustomerCell.h
//  Survey
//
//  Created by Tony Brame on 7/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomerCell : UITableViewCell {
    IBOutlet UILabel *labelName;
    IBOutlet UILabel *labelDate;
}

@property (nonatomic, strong) UILabel *labelName;
@property (nonatomic, strong) UILabel *labelDate;

@end
