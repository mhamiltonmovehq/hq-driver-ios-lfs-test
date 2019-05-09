//
//  Inventory.h
//  Survey
//
//  Created by Tony Brame on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


enum PVO_LOAD_TYPES {
    COMMERCIAL = 1,
    HOUSEHOLD = 2,
    MILITARY = 3,
    SPECIAL_PRODUCTS = 4,
    DISPLAYS_EXHIBITS = 5,
    INTERNATIONAL = 6
};

enum PVO_COLORS {
    RED = 1,
    YELLOW = 2,
    GREEN = 3,
    ORANGE = 4,
    BLUE = 5,
    MULTI = 6
};

enum PVO_LOCATIONS {
    EXTRA_PICKUP = 1,
    OVERFLOW_LOC = 2,
    RESIDENCE = 3,
    SELF_STORAGE = 4,
    VAN_TO_VAN = 5,
    WAREHOUSE = 6,
    PACKER_INVENTORY = 7,
    VERIFY_INVENTORY = 8,
    COMMERCIAL_LOC = 9
};

enum PVO_PACKING_OPTION {
    PVO_PACK_NONE = 0,
    PVO_PACK_CUSTOM = 1,
    PVO_PACK_FULL = 2
};

enum PVO_VALUATION_TYPE {
    PVO_VALUATION_NONE = 0,
    PVO_VALUATION_FVP = 1,
    PVO_VALUATION_RELEASED = 2
};

@interface PVOInventory : NSObject {
	NSString *currentLotNum;
	int currentColor;
	BOOL usingScanner;
	int nextItemNum;
    int custID;
    int loadType;
    int valuationType;
    int currentLocation;
    BOOL noConditionsInventory;
    BOOL inventoryCompleted;
    BOOL deliveryCompleted;
    BOOL newPagePerLot;
    
    NSString *tractorNumber;
    NSString *trailerNumber;
    
    double weightFactor;
    
    BOOL lockLoadType;
    int mproWeight;
    int sproWeight;
    int consWeight;
}

@property (nonatomic, retain) NSString *currentLotNum;
@property (nonatomic, retain) NSString *confirmLotNum;
@property (nonatomic, retain) NSString *tractorNumber;
@property (nonatomic, retain) NSString *trailerNumber;
@property (nonatomic) double weightFactor;
@property (nonatomic) BOOL inventoryCompleted;
@property (nonatomic) BOOL deliveryCompleted;
@property (nonatomic) BOOL newPagePerLot;
@property (nonatomic) int currentColor;
@property (nonatomic) int currentLocation;
@property (nonatomic) int nextItemNum;
@property (nonatomic) int custID;
@property (nonatomic) BOOL usingScanner;
@property (nonatomic) int loadType;
@property (nonatomic) int valuationType;
@property (nonatomic) BOOL noConditionsInventory;

@property (nonatomic) BOOL packingOT;
@property (nonatomic) int packingType;

@property (nonatomic) BOOL lockLoadType;
@property (nonatomic, getter = getInventoryMPROWeight) int mproWeight;
@property (nonatomic, getter = getInventorySPROWeight) int sproWeight;
@property (nonatomic, getter = getInventoryConsWeight) int consWeight;

-(int)getInventoryMPROWeight;
-(int)getInventorySPROWeight;
-(int)getInventoryConsWeight;

@end
