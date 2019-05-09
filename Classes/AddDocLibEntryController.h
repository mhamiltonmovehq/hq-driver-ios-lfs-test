//
//  AddDocLibEntryController.h
//  Survey
//
//  Created by Tony Brame on 5/23/13.
//
//

#import <UIKit/UIKit.h>
#import "DocLibraryEntry.h"
#import "SmallProgressView.h"

#define ADD_DOC_DOC_NAME 0
#define ADD_DOC_URL 1

@interface AddDocLibEntryController : UITableViewController <UITextFieldDelegate, NSURLConnectionDelegate, DocumentLibraryEntryDelegate>

@property (nonatomic, retain) DocLibraryEntry *current;
@property (nonatomic, retain) UITextField *tboxCurrent;

-(void)updateValueWithField:(UITextField*)tbox;

-(IBAction)cmdSaveClick:(id)sender;
-(IBAction)cmdCancelClick:(id)sender;
-(IBAction)textFieldDoneEditing:(id)sender;

@end
