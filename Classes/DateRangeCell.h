//
//  DateRangeCell.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DateRangeCell : UITableViewCell {
    IBOutlet UILabel *labelType;
    IBOutlet UILabel *labelFromDate;
    IBOutlet UILabel *labelToDate;
    IBOutlet UILabel *labelPreferDate;
    IBOutlet UILabel *labelStaticFromDate;
    IBOutlet UILabel *labelStaticToDate;
    IBOutlet UILabel *labelStaticPreferDate;
    IBOutlet UISwitch *switchNoDates;
}

@property (nonatomic, strong) UILabel *labelType;
@property (nonatomic, strong) UILabel *labelFromDate;
@property (nonatomic, strong) UILabel *labelToDate;
@property (nonatomic, strong) UILabel *labelPreferDate;
@property (nonatomic, strong) UILabel *labelStaticFromDate;
@property (nonatomic, strong) UILabel *labelStaticToDate;
@property (nonatomic, strong) UILabel *labelStaticPreferDate;
@property (nonatomic, strong) UISwitch *switchNoDates;

-(IBAction)switchNoDatesValueChanged:(id)sender;

@end
