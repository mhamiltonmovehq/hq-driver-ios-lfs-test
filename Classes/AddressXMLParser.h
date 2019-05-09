//
//  AddressXMLParser.h
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SurveyLocation.h"

@interface AddressXMLParser : NSObject <NSXMLParserDelegate> {
	SurveyLocation *location;
	NSString *nodeName;
	NSObject <NSXMLParserDelegate> *parent;
	NSMutableString *currentString;
	SEL callback;
	BOOL storingData;
}

@property (nonatomic) SEL callback;

@property (nonatomic, retain) NSString *nodeName;
@property (nonatomic, retain) SurveyLocation *location;
@property (nonatomic, retain) NSObject *parent;


@end
