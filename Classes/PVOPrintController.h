//
//  PVOPrintController.h
//  Survey
//
//  Created by Tony Brame on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOSignatureController.h"

enum PVO_PRINT_OPTIONS {
    INVENTORY = 1,
    EXTRA_PU_INV = 2,
    CARTON_DETAIL = 3,
    GYPSY_MOTH = 4,
    EXTRA_DELIVERY = 5,
    DELIVERY_INVENTORY = 6,
    EXCEPTIONS = 7,
    LOAD_HIGH_VALUE = 8,
    DEL_HIGH_VALUE = 9,
    ESIGN_AGREEMENT = 10,
    LOAD_HVI_INSTRUCTIONS = 11,
    HVI_CUST_RESPONSIBILITIES = 12,
    LOAD_HVI_AND_CUST_RESPONSIBILITIES = 13,
    
    //HVI became a mess with Atlas, they want to do the following (reference email from Joab 11/17/11):
    /*
     1. show a separate hvi instrcutions page/option for the driver to user for themselves
     2. when printing origin hvi, print hvi form AND customer responsibilities
     3. when uploading origin hvi, uypload only hvi as one doc, then cust resp as a separate doc
     4. when displaying dest hvi, only show the hvi form (rather than both that and cust resp)
     */
    
    CLAIMS_FORM = 14,
    ROOM_CONDITIONS = 15,
    PRIORITY_INVENTORY = 16,
    HARDWARE_INVENTORY = 17,
    VIEW_BOL = 18,
    PACKING_SERVICES = 19,
    PACK_PER_INVENTORY = 20,
    WEIGHT_TICKET = 21,
    ORIGIN_ASPOD = 22,
    DESTINATION_ASPOD = 23,
    DELIVER_ALL_CONFIRM = 24,
    RIDER_EXCEPTIONS = 25,
    GENERATE_BOL = 26,
    DECLARATION_OF_VALUE = 27,
    /* ID 28 is being used by Legacy BOL */
    UNPACKING_SERVICES = 29,
    DEST_ROOM_CONDITIONS = 30,
    AUTO_INVENTORY_ORIG = 31,
    AUTO_INVENTORY_DEST = 32,
    AUTO_BOL_ORIG = 33,
    AUTO_BOL_DEST = 34,
    BULKY_INVENTORY_ORIG = 410,
    BULKY_INVENTORY_DEST = 411
};

#define PVO_PRINT_PREVIEW 0
#define PVO_PRINT_FINAL 1

@interface PVOPrintController : UITableViewController <PVOSignatureControllerDelegate> {
    NSDictionary *options;
    NSArray *keys;
    PVOSignatureController *signature;
    NSString *signatureName;
}

@property (nonatomic, retain) NSDictionary *options;
@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) PVOSignatureController *signature;
@property (nonatomic, retain) NSString *signatureName;

-(IBAction)valueEntered:(NSString*)value;

@end
