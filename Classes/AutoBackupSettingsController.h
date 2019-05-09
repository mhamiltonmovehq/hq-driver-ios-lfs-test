//
//  AutoBackupSettingsController.h
//  Survey
//
//  Created by Tony Brame on 2/5/13.
//
//

#import <UIKit/UIKit.h>
#import "AutoBackupSchedule.h"

#define AUTO_BACKUP_TIME_TYPE_MINUTES 0
#define AUTO_BACKUP_TIME_TYPE_HOURS 1
#define AUTO_BACKUP_TIME_TYPE_DAYS 2

#define AUTO_BACKUP_MAX_TIME 59

#define AUTO_BACKUP_PICKER_TIME 0
#define AUTO_BACKUP_PICKER_TYPE 1

@interface AutoBackupSettingsController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIPickerView *pickerInterval;
@property (retain, nonatomic) UITextField *tboxCurrent;
@property (retain, nonatomic) AutoBackupSchedule *settings;

@property (retain, nonatomic) NSMutableArray *timeTypes;
@property (retain, nonatomic) NSMutableArray *times;

-(void)updateValueWithField:(UITextField*)field;
-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)switchChanged:(id)sender;

-(int)getTimeTypeMultiplier:(int)type;

@end
