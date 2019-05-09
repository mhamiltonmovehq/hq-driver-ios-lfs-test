//
//  EnterCredentialsController.h
//  Survey
//
//  Created by Tony Brame on 4/14/15.
//
//

#import <UIKit/UIKit.h>

#define ENTER_CREDENTIALS_USERNAME 0
#define ENTER_CREDENTIALS_PASSWORD 1
#define ENTER_CREDENTIALS_BETAPASSWORD 2
#define ENTER_CREDENTIALS_RELOCRMUSERNAME 3
#define ENTER_CREDENTIALS_RELOCRMPASSWORD 4
#define ENTER_CREDENTIALS_RELOCRMENVIRONMENT 5

@interface EnterCredentialsController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *betaPassword;

@property (nonatomic, strong) NSString *reloCRMUsername;
@property (nonatomic, strong) NSString *reloCRMPassword;
@property (nonatomic) int selectedEnvironment;

@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic) BOOL isMoveHQSettings;
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NSDictionary *environments;

-(void)updateValueWithField:(UITextField*)tbox;

-(IBAction)cmdSaveClick:(id)sender;
-(IBAction)cmdDoneClick:(id)sender;

@end
