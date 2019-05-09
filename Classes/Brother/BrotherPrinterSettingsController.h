//
//  BrotherPrinterSettingsController.h
//  Survey
//
//  Created by Tony Brame on 7/15/15.
//
//

#import <UIKit/UIKit.h>
#import "BrotherOldSDKStructs.h"
#import "SelectObjectController.h"

@interface BrotherPrinterSettingsController : UITableViewController <SelectObjectControllerDelegate, UITextFieldDelegate>

@property (nonatomic, retain) PJ673PrintSettings *settings;
@property (nonatomic, retain) NSArray *paperTypes;
@property (nonatomic, retain) UITextField *tboxCurrent;

@end
