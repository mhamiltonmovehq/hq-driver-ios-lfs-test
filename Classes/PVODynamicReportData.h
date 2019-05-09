//
//  PVODynamicReportData.h
//  Survey
//
//  Created by Tony Brame on 1/2/15.
//
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface PVODynamicReportData : NSObject

@property (nonatomic) int custID;
@property (nonatomic) int reportID;
@property (nonatomic) int dataEntryID;
@property (nonatomic) int dataSectionID;
@property (nonatomic) int intValue;
@property (nonatomic) double doubleValue;

@property (nonatomic, retain) NSString *textValue;
@property (nonatomic, retain) NSDate *dateValue;

-(void)flushToXML:(XMLWriter*)xml;

@end
