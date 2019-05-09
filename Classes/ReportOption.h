//
//  ReportOption.h
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#define HTML_FILES_LOCATION @"ReportBundles"


@interface ReportOption : NSObject
{
	NSString *reportName;
	NSString *reportLocation;
	int reportID;
}

@property (nonatomic, retain) NSString *reportName;
@property (nonatomic, retain) NSString *reportLocation;
@property (nonatomic) int reportID;
@property (nonatomic) int reportTypeID;
@property (nonatomic) int pageSize;

@property (nonatomic) BOOL htmlSupported;
@property (nonatomic) int htmlRevision;
@property (nonatomic, retain) NSString *htmlBundleLocation;
@property (nonatomic, retain) NSString *htmlTargetFile;
@property (nonatomic) BOOL htmlSupportsImages;

@end
