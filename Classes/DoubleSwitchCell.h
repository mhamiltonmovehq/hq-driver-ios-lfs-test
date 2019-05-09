//
//  DoubleSwitchCell.h
//  Survey
//
//  Created by Lee Zumstein on 3/3/14.
//
//

#import <UIKit/UIKit.h>

@interface DoubleSwitchCell : UITableViewCell {
    
    IBOutlet UILabel *label1;
    IBOutlet UILabel *label2;
    IBOutlet UISwitch *switch1;
    IBOutlet UISwitch *switch2;
}

@property (nonatomic, retain) IBOutlet UILabel *label1;
@property (nonatomic, retain) IBOutlet UILabel *label2;
@property (nonatomic, retain) IBOutlet UISwitch *switch1;
@property (nonatomic, retain) IBOutlet UISwitch *switch2;

@end
