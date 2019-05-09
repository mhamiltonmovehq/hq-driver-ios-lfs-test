//
//  TextWithHeaderCell.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextWithHeaderCell : UITableViewCell {
	IBOutlet UILabel *labelHeader;
	IBOutlet UILabel *labelText;
}

@property (nonatomic, strong) UILabel *labelHeader;
@property (nonatomic, strong) UILabel *labelText;

@end
