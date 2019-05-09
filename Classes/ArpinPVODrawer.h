//
//  AtlasPVODrawer.h
//  Survey
//
//  Created by Lee Zumstein on 12/12/11.
//  Copyright 2011 IGC Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDrawer.h"
#import "PVORoomSummary.h"
#import "PVOItemDetail.h"

#define ARPIN_PVO_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define ARPIN_PVO_FONT_HALF [UIFont systemFontOfSize:TO_PRINTER(2.)]
#define ARPIN_PVO_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define ARPIN_PVO_BOLD_FONT_HALF [UIFont boldSystemFontOfSize:TO_PRINTER(2.)]
#define ARPIN_PVO_FIVEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(5.)]
#define SIXPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(6.)]
#define SIXPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(6.)]
#define SEVENPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define SEVENPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define EIGHTPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(8.)]
#define EIGHTPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(8.)]
#define NINEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(9.)]
#define NINEPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(9.)]

#define ESIGN_FONT [UIFont systemFontOfSize:TO_PRINTER(11.)]
#define ESIGN_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(11.)]

#define HIGH_VALUE_HEADER_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(13.)]

#define ARPIN_PVO_DRAFT_FONT [UIFont systemFontOfSize:TO_PRINTER(20.)]


#define ARPIN_PVO_PROGRESS_ITEMS_BEGIN 1

#define APRIN_PVO_ESIGN_PROGRESS_PAGE1 1
#define APRIN_PVO_ESIGN_PROGRESS_PAGE2 2
#define APRIN_PVO_ESIGN_PROGRESS_PAGE3 3

#define ARPIN_PVO_HIGH_VALUE_HEADER 1
#define ARPIN_PVO_HIGH_VALUE_ITEMS_HEADER 2
#define ARPIN_PVO_HIGH_VALUE_ITEMS_BEGIN 3

@interface ArpinPVODrawer : MMDrawer {
    BOOL isOrigin;
    BOOL printingPackersInventory;
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
    
    NSMutableDictionary *cpSummary;
    int cpSummaryTotal;
    NSMutableDictionary *pboSummary;
    int pboSummaryTotal;
}

// inventory
-(int)addHeader:(BOOL)print;
-(int)invItemsStart;
-(int)invItem;
-(int)invItemsEnd;
-(int)invFooter:(BOOL)print;

//e-sign
-(int)eSignPage1;
-(int)eSignPage2;
-(int)eSignPage3;

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