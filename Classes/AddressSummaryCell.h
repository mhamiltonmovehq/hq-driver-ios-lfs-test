//
//  AddressSummaryCell.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AddressSummaryCell : UITableViewCell {
    IBOutlet UILabel *labelName;
    IBOutlet UILabel *labelAddress;
}

@property (nonatomic, strong) UILabel *labelName;
@property (nonatomic, strong) UILabel *labelAddress;

@end
