//
//  CustomItemListParser.h
//  Survey
//
//  Created by Tony Brame on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomItemList.h"
#import "WCFParser.h"

@interface CustomItemListParser : WCFParser <NSXMLParserDelegate> {
    NSMutableArray *itemLists;
    id<NSXMLParserDelegate> parent;
    NSMutableString *currentString;
    BOOL storingData;
    CustomItemList *current;
}

@property (nonatomic, strong) id<NSXMLParserDelegate> parent;
@property (nonatomic, strong) NSMutableArray *itemLists;
@property (nonatomic, strong) CustomItemList *current;

@end
