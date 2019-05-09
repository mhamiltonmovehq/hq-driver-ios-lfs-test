//
//  PVOBulkyInventoryItem.h
//  Survey
//
//  Created by Justin on 7/6/16.
//
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"
#import <sqlite3.h>

@interface PVOBulkyInventoryItem : NSObject

@property (nonatomic) int pvoBulkyItemID;
@property (nonatomic) int custID;
@property (nonatomic) int pvoBulkyItemTypeID;
@property (nonatomic) int wireframeTypeID;

-(PVOBulkyInventoryItem*)initWithStatement:(sqlite3_stmt*)stmnt;
-(void)flushToXML:(XMLWriter*)xml;
-(NSString*)getFormattedDetails;

@end
