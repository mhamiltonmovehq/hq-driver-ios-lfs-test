//
//  PVOBulkyData.h
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface PVOBulkyData : NSObject

@property (nonatomic) int pvoBulkyItemID;
@property (nonatomic) int dataEntryID;
@property (nonatomic) int intValue;
@property (nonatomic) double doubleValue;

@property (nonatomic, retain) NSString *textValue;
@property (nonatomic, retain) NSDate *dateValue;

-(void)flushToXML:(XMLWriter*)xml;

@end

