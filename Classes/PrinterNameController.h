//
//  PrinterNameController.h
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoredPrinter.h"

@interface PrinterNameController : UITableViewController <UITextFieldDelegate> {
	StoredPrinter *printer;
	UITextField *tboxCurrent;
}

@property (nonatomic, retain) StoredPrinter *printer;
@property (nonatomic, retain) UITextField *tboxCurrent;

@end
