//
//  PVOBulkyEntry.h
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import <Foundation/Foundation.h>
#import "PVODynamicReportEntry.h"


@interface PVOBulkyEntry : NSObject

@property (nonatomic) int bulkyTypeID;
@property (nonatomic) int dataEntryID;
@property (nonatomic) REPORT_DATA_TYPES entryDataType;
@property (nonatomic, strong) NSString *entryName;

@end
