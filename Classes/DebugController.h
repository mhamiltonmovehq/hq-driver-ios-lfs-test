//
//  DebugController.h
//  Survey
//
//  Created by Tony Brame on 5/14/14.
//
//

#import <UIKit/UIKit.h>

#define DEBUG_CLEAN_INSTALL 1
#define DEBUG_RESTORE_FROM_BACKUP 2

@interface DebugController : UIViewController <UIAlertViewDelegate>

- (IBAction)cmdContinue:(id)sender;
- (IBAction)cmdCleanInstall:(id)sender;
- (IBAction)cmdRestoreFromBackup:(id)sender;

@end
