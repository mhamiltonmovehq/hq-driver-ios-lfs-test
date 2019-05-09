//
//  SingleDateCell.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SingleDateCell : UITableViewCell {
    IBOutlet UILabel *labelType;
    IBOutlet UILabel *labelDate;
}

@property (nonatomic, strong) UILabel *labelType;
@property (nonatomic, strong) UILabel *labelDate;

@end
