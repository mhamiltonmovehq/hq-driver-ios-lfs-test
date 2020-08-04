//
//  PVOImageParser.h
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCFParser.h"

@interface PVOImageParser : WCFParser <NSXMLParserDelegate>
{	
	NSMutableString *currentString;
	BOOL storingData;
    int surveyedItemID;
    int roomID;
    int locationID;
    
    NSData *currentImageData;
    
    BOOL isWCF;
}

@property (nonatomic) int surveyedItemID;
@property (nonatomic) BOOL isWCF;
@property (nonatomic) int roomID;
@property (nonatomic) int locationID;

-(void) parseJson:(NSDictionary*) jsonDictionary;


@end
