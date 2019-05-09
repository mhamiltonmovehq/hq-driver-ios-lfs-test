//
//  PrinterIPController.h
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PrinterIPController : UITableViewController <UITextFieldDelegate> {
	NSString *ipAddress;
	UITextField *tboxCurrent;
	SEL sendMeThePrinter;
	NSObject *printerReceptacle;
}

@property (nonatomic, retain) NSString *ipAddress;
@property (nonatomic, retain) UITextField *tboxCurrent;
@property (nonatomic, retain) NSObject *printerReceptacle;
@property (nonatomic) SEL sendMeThePrinter;

@end
