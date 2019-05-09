//
//  GetPrinterController.h
//  Survey
//
//  Created by Tony Brame on 6/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#define Printer ePrint_Printer
#import "ePrint.h"
//#undef Printer
#import "StoredPrinter.h"
#import "PrinterIPController.h"

@interface GetPrinterController : UITableViewController {
	ePrintDiscoverPrinter *discoverPrinter;
	BOOL discovered;
	BOOL searching;
	NSTimer *timer;
	StoredPrinter *selectedPrinter;
	PrinterIPController *ipController;
}

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) StoredPrinter *selectedPrinter;
@property (nonatomic, retain) PrinterIPController *ipController;

- (void)discoveryTimedOut;
-(void)beginSearch;
- (void)bonjourDiscoveryDidEndNotification:(NSNotification *)notification;
-(void)sendMeAPrinter:(StoredPrinter*)printer;

-(IBAction)cancel:(id)sender;

@end
