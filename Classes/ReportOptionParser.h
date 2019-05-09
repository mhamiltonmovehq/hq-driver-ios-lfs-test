//
//  ReportOptionParser.h
//  Survey
//
//  Created by Tony Brame on 12/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReportOption.h"

@interface ReportOptionParser : NSObject  <NSXMLParserDelegate>
{
	ReportOption *option;
	NSString *address;
	NSMutableArray *entries;
	BOOL storingData;
	NSMutableString *currentString;
}

@property (nonatomic, retain) NSMutableArray *entries;
@property (nonatomic, retain) ReportOption *option;
@property (nonatomic, retain) NSString *address;

@end
