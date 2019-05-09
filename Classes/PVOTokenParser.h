//
//  PVOInventoryParser.h
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVOTokenParser : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentString;
    NSString *token;
    BOOL storingData;
}

@property (nonatomic, retain) NSString *token;

@end
