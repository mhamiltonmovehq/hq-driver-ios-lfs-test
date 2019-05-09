//
//  SwitchCell.h
//  Survey
//
//  Created by Tony Brame on 8/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SwitchCell : UITableViewCell {
	IBOutlet UILabel *labelHeader;
	IBOutlet UISwitch *switchOption;
}

@property (nonatomic, retain) UILabel *labelHeader;
@property (nonatomic, retain) UISwitch *switchOption;

@end
