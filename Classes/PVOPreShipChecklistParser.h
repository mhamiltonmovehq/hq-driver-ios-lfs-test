//
//  PVOPreShipChecklistParser.h
//  Survey
//
//  Created by Justin Little on 11/2/2015
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVOPreShipChecklistParser : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentString;
    BOOL storingData;
    NSMutableArray *checkListItems;
//    NSString *currentItem;
}

@property (nonatomic, retain) NSMutableArray *checkListItems;
//@property (nonatomic, retain) NSString *currentItem;

@end
