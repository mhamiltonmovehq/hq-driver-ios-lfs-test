//
//  WCFParser.h
//  Survey
//
//  Created by Tony Brame on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WCFParser : NSObject {

}

-(BOOL)thisElement:(NSString*)myElementName isElement:(NSString*)targetElementName;
+(NSDate*)dateFromString:(NSString*)datestring;
+(NSString*)stringFromDate:(NSDate*)date;

@end
