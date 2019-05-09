//
//  PrinterBonjourController.h
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#define Printer ePrint_Printer
#import "ePrint.h"
//#undef Printer

@interface PrinterBonjourController : UITableViewController {
	ePrintDiscoverPrinter *discoverPrinter;
	BOOL discovered;
}

- (void)bonjourDiscoveryDidEndNotification:(NSNotification *)notification;

@end
