//
//  ViewPrintersController.h
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrinterSelectMethodController.h"

@interface ViewPrintersController : UITableViewController {
    NSArray *printers;
    PrinterSelectMethodController *psmController;
}

@property (nonatomic, strong) NSArray *printers;
@property (nonatomic, strong) PrinterSelectMethodController *psmController;

@end
