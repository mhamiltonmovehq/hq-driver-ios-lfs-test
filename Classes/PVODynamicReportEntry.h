//
//  PVODynamicReportEntry.h
//  Survey
//
//  Created by Tony Brame on 5/1/14.
//
//

#import <Foundation/Foundation.h>


typedef enum : int {
    RDT_TEXT = 1,
    RDT_DATE = 2,
    RDT_TIME = 3,
    RDT_DATE_TIME = 4,
    RDT_ON_OFF = 5,
    RDT_INTEGER = 6,
    RDT_DOUBLE = 7,
    RDT_MULTIPLE_CHOICE = 8,
    RDT_TEXT_LONG = 9,
    RDT_TEXT_NUMERIC = 10,
    RDT_TEXT_CAPS = 11
} REPORT_DATA_TYPES;


@interface PVODynamicReportEntry : NSObject

@property (nonatomic) int reportID;
@property (nonatomic) int dataSectionID;
@property (nonatomic) int dataEntryID;
@property (nonatomic) int dateTimeGroup;
@property (nonatomic) REPORT_DATA_TYPES entryDataType;
@property (nonatomic, strong) NSString *entryName;
@property (nonatomic, strong) NSString *defaultValue;

@end
