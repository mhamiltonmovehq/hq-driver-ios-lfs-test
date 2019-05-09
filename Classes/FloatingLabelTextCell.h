//
//  FloatingLabelTextCell.h
//  Survey
//
//  Created by Brian Prescott on 7/29/15.
//
//

#import <UIKit/UIKit.h>

#import "RPFloatingPlaceholderTextField.h"

@interface FloatingLabelTextCell : UITableViewCell
{
}

@property (nonatomic, strong) IBOutlet RPFloatingPlaceholderTextField *tboxValue;

@end
