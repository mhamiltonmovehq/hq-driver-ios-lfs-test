//
//  CustomItemListParser.m
//  Survey
//
//  Created by Tony Brame on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomItemListParser.h"


@implementation CustomItemListParser

@synthesize itemLists, parent, current;

-(id)init
{
    if( self = [super init] )
    {
        currentString = [[NSMutableString alloc] init];
        itemLists = [[NSMutableArray alloc] init];
    }
    return self;
}



#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {

    if([self thisElement:elementName isElement:@"ItemList"])
    {
        self.current = [[CustomItemList alloc] init];
    }
    else if([self thisElement:elementName isElement:@"ItemListID"] || 
            [self thisElement:elementName isElement:@"Username"] || 
            [self thisElement:elementName isElement:@"ItemListName"])
    {
        //all root data
        storingData = YES;
        [currentString setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if([self thisElement:elementName isElement:@"ItemList"])
    {
        [itemLists addObject:current];
    }
    else if(storingData && [self thisElement:elementName isElement:@"ItemListID"]){
        current.customItemListID = [currentString intValue];
    }
    else if(storingData && [self thisElement:elementName isElement:@"ItemListName"]){
        current.itemListName = [NSString stringWithString:currentString];
    }
    
    storingData = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    @throw parseError;
    // Handle errors as appropriate for your application.
}

@end
