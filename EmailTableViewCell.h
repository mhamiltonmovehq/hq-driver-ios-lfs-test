//
//  AdditionalEmailsTableViewCell.h
//  Survey
//
//  Created by Collin Sims on 1/17/17.
//
//

#import <UIKit/UIKit.h>
#import "RPFloatingPlaceholderTextField.h"

@interface EmailTableViewCell : UITableViewCell {
    IBOutlet UIButton *sendEmailBtn;
    IBOutlet RPFloatingPlaceholderTextField *emailInput;
}

@property (nonatomic, retain) UIButton *sendEmailBtn;
@property (nonatomic, retain) RPFloatingPlaceholderTextField *emailInput;

@end
