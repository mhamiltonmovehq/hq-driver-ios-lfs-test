//
//  EditDateCell.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EditDateCell : UITableViewCell {
	IBOutlet UILabel *labelHeader;
	IBOutlet UILabel *labelDate;
}

@property (nonatomic, retain) UILabel *labelHeader;
@property (nonatomic, retain) UILabel *labelDate;


@end
