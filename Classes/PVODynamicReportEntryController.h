
#import <UIKit/UIKit.h>
#import "SingleFieldController.h"
#import "EditDateController.h"
#import "PVODynamicReportSection.h"
#import "PVODynamicReportEntry.h"
#import "SelectObjectController.h"

@interface PVODynamicReportEntryController : UITableViewController <UITextFieldDelegate, SelectObjectControllerDelegate>

@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) PVODynamicReportSection *section;
@property (nonatomic, strong) PVODynamicReportEntry *editingEntry;
@property (nonatomic, strong) UITextField *currentTextBox;

-(IBAction)textFieldDoneEditing:(id)sender;
-(IBAction)updateValueWithField:(UITextField*)sender;

-(void)datesSaved:(NSDate*)fromDate withToDate:(NSDate*)toDate;

@end
