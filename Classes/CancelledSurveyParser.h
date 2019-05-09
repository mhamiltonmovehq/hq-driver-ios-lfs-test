//
//  CancelledSurveyParser.h
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CancelledSurveyParser : NSObject  {
	NSMutableString *currentString;
	NSMutableArray *ids;
	BOOL storingData;
}

@property (nonatomic, retain) NSMutableArray *ids;
@property (nonatomic, retain) NSMutableString *currentString;


@end
