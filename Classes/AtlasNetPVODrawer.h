//
//  AtlasPVODrawer.h
//  Survey
//
//  Created by Lee Zumstein on 12/12/11.
//  Copyright 2011 IGC Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDrawer.h"
//#import "PVORoomSummary.h"
#import "PVOItemDetail.h"

#define PVO_REPORT_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define PVO_REPORT_FONT_HALF [UIFont systemFontOfSize:TO_PRINTER(2.)]
#define PVO_REPORT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define PVO_REPORT_FIVEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(5.)]
#define SIXPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(6.)]
#define SEVENPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define SEVENPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define SIXPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(6.)]
#define EIGHTPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(8.)]
#define EIGHTPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(8.)]
#define NINEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(9.)]
#define NINEPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(9.)]

#define PVO_REPORTS_PROGRESS_ITEMS_BEGIN 1

#define SYSTEM_FONT(fontSize)       [UIFont systemFontOfSize:TO_PRINTER(fontSize)]
#define SYSTEM_BOLD_FONT(fontSize)  [UIFont boldSystemFontOfSize:TO_PRINTER(fontSize)]

#define PVO_HIGH_VALUE_HEADER 1
#define PVO_HIGH_VALUE_ITEMS_HEADER 2
#define PVO_HIGH_VALUE_ITEMS_BEGIN 3

@interface AtlasNetPVODrawer : MMDrawer {
    BOOL isOrigin;
    BOOL printingMissingItems;
    BOOL printDamageCodeOnly;
	int leftCurrentPageY;
    int custID;
    int pvoLoadID;
    int width;
    //PVORoomSummary *myRoom;
    PVOItemDetail *myItem;
    NSMutableArray *lotNums;
    NSMutableArray *tapeColors;
    NSMutableArray *numsFrom;
    NSMutableArray *numsTo;
    int countDelivered;
    BOOL whsCheck;
    BOOL dvrCheck;
    BOOL sprCheck;
    
    int highValueRecordCounter;
    double highValueTotal;
}

@property (nonatomic, retain) NSMutableArray *highValueItems;
@property (nonatomic) BOOL isDeliveryHighValueDisconnectedReport;

// inventory
-(int)addHeader:(BOOL)print;
-(int)invItemsStart;
-(int)invItem;
-(int)blankInvItemRow;
-(int)getBlankInvItemRowHeight;
-(int)invItemsEnd;
-(int)invFooter:(BOOL)print;

//high value
-(int)addHighValueHeader;
-(int)highValueItemsHeader;
-(int)highValueItem;
-(int)getHighValueItemHeight;
-(int)highValueFooter:(BOOL)print;

//helpers
-(void)updateCurrentPageY;
-(int)findHighestHeight:(NSArray*) heights;

@end