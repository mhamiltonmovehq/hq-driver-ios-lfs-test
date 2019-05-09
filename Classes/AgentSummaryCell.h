//
//  AgentSummaryCell.h
//  Survey
//
//  Created by Tony Brame on 7/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AgentSummaryCell : UITableViewCell {
	IBOutlet UILabel *labelHeader;
	IBOutlet UILabel *labelName;
	IBOutlet UILabel *labelCode;
	IBOutlet UILabel *labelCity;
}

@property (nonatomic, retain) UILabel *labelHeader;
@property (nonatomic, retain) UILabel *labelCity;
@property (nonatomic, retain) UILabel *labelCode;
@property (nonatomic, retain) UILabel *labelName;

@end
