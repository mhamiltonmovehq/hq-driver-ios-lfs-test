//
//  SurveyNumFormatter.h
//  Survey
//
//  Created by Tony Brame on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SurveyNumFormatter : NSNumberFormatter {

}

-(NSString*)stringFromDouble:(double)number;
-(NSString*)stringFromInt:(int)number;

@end
