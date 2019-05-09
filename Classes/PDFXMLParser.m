//
//  PDFXMLParser.m
//  Survey
//
//  Created by mm-dev-ak on 5/15/17.
//
//

#import "PDFXMLParser.h"

@interface PDFXMLParser () 
@property (nonatomic, strong) NSMutableString *currentString;
@property (nonatomic) BOOL storingData;
@end

@implementation PDFXMLParser
-(id)init
{
    if( self = [super init] )
    {
        _currentString = [[NSMutableString alloc] init];
        _success = NO;
        _parseIsSuccessful = NO;
    }
    return self;
}



#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"GetPDFByRequestResult"])
    {
        [self.currentString setString:@""];
    } else if ([elementName isEqualToString:@"a:success"]) {
        [self.currentString setString:@""];
        self.storingData = YES;
    } else if ([elementName isEqualToString:@"a:byteStream"]) {
        [self.currentString setString:@""];
        self.storingData = YES;
    } else {
        self.storingData = YES;
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if([elementName isEqualToString:@"GetPDFByRequestResult"])
    {
        self.storingData = NO;
        self.parseIsSuccessful = YES;
    } else if ([elementName isEqualToString:@"a:success"]) {
        NSString *successString = self.currentString;
        self.success = [successString rangeOfString:@"true"].location != NSNotFound;
        self.storingData = NO;
    } else if ([elementName isEqualToString:@"a:byteStream"]) {
        self.output = [self.currentString copy];
        self.storingData = NO;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.storingData == YES)
        [self.currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
