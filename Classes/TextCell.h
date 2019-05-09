//
//  TextCell.h
//  Survey
//
//  Created by Tony Brame on 5/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextCell : UITableViewCell {
	IBOutlet UITextField *tboxValue; 
}

@property (nonatomic, strong) UITextField *tboxValue;

@end
