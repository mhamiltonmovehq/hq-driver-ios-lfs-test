//
//  SyncGlobals.h
//  Survey
//
//  Created by Tony Brame on 10/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"
#import "SurveyDownloadXMLParser.h"

@interface SyncGlobals : NSObject {

}

+(BOOL)flushCustomerToDB:(SurveyDownloadXMLParser*)parser appDelegate:(SurveyAppDelegate *)del;
+(BOOL)mergeCustomerToDB:(SurveyDownloadXMLParser*)parser appDelegate:(SurveyAppDelegate *)del;
+(XMLWriter*)buildCustomerXML:(int)custID isAtlas:(BOOL)atlas;
+(XMLWriter*)buildCustomerXML:(int)custID withNavItemID:(int)navItemID isAtlas:(BOOL)atlas;
+(void)getPVOInfo:(XMLWriter*)retval navItemID:(int)navItemID;
+(UIImage*)removeUnusedImageSpace:(UIImage*)source;

@end
