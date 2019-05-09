//
//  PVODrawer.h
//  Survey
//
//  Created by Lee Zumstein on 12/12/11.
//  Copyright 2011 IGC Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDrawer.h"
#import "PVORoomSummary.h"
#import "PVOItemDetail.h"
#import "PVOInventory.h"
#import "PVOInventoryLoad.h"

#define PVO_REPORT_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define PVO_REPORT_FONT_HALF [UIFont systemFontOfSize:TO_PRINTER(2.)]
#define PVO_REPORT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define PVO_REPORT_FIVEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(5.)]
#define SIXPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(6.)]
#define SIXPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(6.)]
#define SEVENPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(7.)]
#define SEVENPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(7.)]
#define EIGHTPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(8.)]
#define EIGHTPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(8.)]
#define NINEPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(9.)]
#define NINEPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(9.)]
#define TENPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(10.)]
#define TENPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(10.)]
#define THIRTEENPOINT_FONT [UIFont systemFontOfSize:TO_PRINTER(13.)]
#define THIRTEENPOINT_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(13.)]

#define ESIGN_FONT [UIFont systemFontOfSize:TO_PRINTER(11.)]
#define ESIGN_BOLD_FONT [UIFont boldSystemFontOfSize:TO_PRINTER(11.)]

#define SYSTEM_FONT(fontSize)       [UIFont systemFontOfSize:TO_PRINTER(fontSize)]
#define SYSTEM_BOLD_FONT(fontSize)  [UIFont boldSystemFontOfSize:TO_PRINTER(fontSize)]


#define APRIN_PVO_ESIGN_PROGRESS_PAGE1 1
#define APRIN_PVO_ESIGN_PROGRESS_PAGE2 2
#define APRIN_PVO_ESIGN_PROGRESS_PAGE3 3

#define PVO_REPORTS_PROGRESS_ITEMS_BEGIN 1

#define INVENTORY_SECTION_MPRO 0
#define INVENTORY_SECTION_SPRO 1
#define INVENTORY_SECTION_PACK_INV_HIGH_VALUE 2
#define INVENTORY_SECTION_PACK_INV_ALL_OTHER 3
#define INVENTORY_SECTION_HIGH_VALUE 4
#define INVENTORY_SECTION_ALL_OTHER 5
#define INVENTORY_SECTION_PACK_INV_MISSING 100
#define INVENTORY_SECTION_MISSING 101

#define RIDER_EXCEPTIONS_PROGRESS_BEGIN 1

@interface PVODrawer : MMDrawer {
    BOOL isOrigin;
    BOOL printingMissingItems;
    BOOL printingItemsInventoriedAfterSig;
    BOOL printingItemsInventoriedAfterSigLOT;
    BOOL hasItemsInventoriedAfterSig;
    BOOL printDamageCodeOnly;
    BOOL newPagePerLot;
    BOOL printDeclineCheckoffWaiver;
    BOOL processingMproSproItems;
    BOOL processingHighValueItems;
    BOOL processingPackersInvItems;
    
	int leftCurrentPageY;
    int custID;
    int pvoLoadID;
    int width;
    PVOItemDetail *myItem;
    NSMutableArray *currentPageItems;
    int countDelivered;
    BOOL whsCheck;
    BOOL dvrCheck;
    BOOL sprCheck;
    
    NSMutableDictionary *cpSummary;
    int cpSummaryTotal;
    NSMutableDictionary *pboSummary;
    int pboSummaryTotal;
    NSMutableDictionary *crateSummary;
    int crateSummaryTotal;
    
    PVORoomSummary *myRoom;
    
    BOOL hasPopulatedInventorySectionCounts;
    int mpro;
    int spro;
    int nonMproSpro;
    int packInvHV;
    int packInvNotHV;
    int packInvAfterSign;
    int packInvMissing;
    int allOtherHV;
    int allOtherNotHV;
    int allOtherAfterSign;
    int allOtherMissing;
    
    int riderExceptionLoadID;
}

-(BOOL)shouldSectionFinishPage:(int)section withInvData:(PVOInventory*)invData withLoads:(NSArray*)loads;

//e-sign
-(int)eSignPage1;
-(int)eSignPage2;
-(int)eSignPage3;

// inventory
-(int)addHeader:(BOOL)print;
-(int)invItemsStart;
-(int)invItem;
-(int)invItemStrikethrough;
-(int)blankInvItemRow;
-(int)blankInvItemRow:(BOOL)print;
-(PrintSection*)getBlankInvItemRowSection;
-(int)invItemsEnd;
-(int)invFooter:(BOOL)print;
-(int)invFooterNoCustSignature:(BOOL)print;
-(int)invFooter:(BOOL)print withCustSignatures:(BOOL)showCustSignatures;
-(int)printInvLineDescrip:(NSString*)descrip withItemNo:(NSString*)itemNo withFont:(UIFont*)font;
-(int)invItemsStartMpro;
-(int)invItemsEndMpro;
-(int)invItemsStartSpro;
-(int)invItemsEndSpro;
-(int)invItemsStartHighValue;
-(int)invItemsEndHighValue;
-(int)invItemsStartPacker;
-(int)invItemsPackerInitialCounts;
-(int)invItemsEndPacker;

-(int)printDeclineCheckoff;
-(int)printDeclineCheckoffOnNextPage;
-(int)declineCheckoff:(BOOL)print finishAllOnNextPage:(BOOL)finishOnNextPage;

//rider exceptions
-(int)addRiderHeader:(BOOL)print;
-(int)riderItem;
-(int)riderItemNone;
-(int)riderItem:(BOOL)isNone shouldPrint:(BOOL)print;
-(int)riderFinishPage;
-(int)riderNotesPrint;
-(int)riderNotes:(BOOL)print;
-(int)riderFooter:(BOOL)print;

//helpers
-(void)updateCurrentPageY;
-(int)findHighestHeight:(NSArray*) heights;
-(void)sortPVOItemDetailArray:(NSArray *)items accountForInvAfterSig:(BOOL)acctAfterInvSig;
-(void)sortPVOItemDetailArray:(NSMutableArray *)items accountForInvAfterSig:(BOOL)acctAfterInvSig afterSigOnBottom:(BOOL)afterSigOnBottom;
-(BOOL)hasNonHighValueItems:(NSArray*)items;
-(PVOInventoryLoad*)getRiderExceptionsWorkingLoad;
-(int)getTextWidth:(NSString*)text withFont:(UIFont*)font;

@end