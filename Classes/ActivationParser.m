//
//  ActivationParser.m
//  Survey
//
//  Created by Tony Brame on 9/25/14.
//
//

#import "ActivationParser.h"

@implementation ActivationParser


-(id)init
{
    if(self = [super init])
    {
        current = [[NSMutableString alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.results = nil;
}


#pragma mark - NSXMLParserDelegate methods



- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [current setString:@""];
    if([elementName isEqualToString:@"CheckDeviceActivationResult"] || [elementName isEqualToString:@"CheckDeviceActivationForRequestResult"])
        self.results = [[Activation alloc] init];
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([self thisElement:elementName isElement:@"Success"])
        self.results.success = [current isEqualToString:@"true"];
    else if([self thisElement:elementName isElement:@"AllowDevice"])
        self.results.allowDevice = [current isEqualToString:@"true"];
    else if([self thisElement:elementName isElement:@"DeviceID"])
        self.results.deviceID = [NSString stringWithString:current];
    else if([self thisElement:elementName isElement:@"DeviceIDMatches"])
        self.results.deviceIDMatches = [current isEqualToString:@"true"];
    else if([self thisElement:elementName isElement:@"VanlineDownloadID"])
        self.results.vanlineDownloadID = [current intValue];
    else if([self thisElement:elementName isElement:@"PricingVersion"])
        self.results.pricingVersion = [current intValue];
    else if([self thisElement:elementName isElement:@"PricingDownloadLocation"])
        self.results.pricingDownloadLocation = [NSString stringWithString:current];
    else if([self thisElement:elementName isElement:@"MilesVersion"])
        self.results.milesVersion = 0; //[current intValue];
    else if([self thisElement:elementName isElement:@"MilesDownloadLocation"])
        self.results.milesDownloadLocation = [NSString stringWithString:current];
    else if([self thisElement:elementName isElement:@"PastTrial"])
        self.results.pastTrial = [current isEqualToString:@"true"];
    else if([self thisElement:elementName isElement:@"ResetTrial"])
        self.results.resetTrial = [current isEqualToString:@"true"];
    else if([self thisElement:elementName isElement:@"ActivatedFunctionality"])
        self.results.activatedFunctionality = [NSString stringWithString:current];
    else if([self thisElement:elementName isElement:@"IgnoreUpdates"])
        self.results.resetTrial = [current isEqualToString:@"true"];
    else if ([self thisElement:elementName isElement:@"EnableAutoInv"])
        self.results.allowAutoInv = [current isEqualToString:@"true"];
    else if ([self thisElement:elementName isElement:@"PricingVanlineID"])
        self.results.fileAssociationId = [current intValue];
    else if ([self thisElement:elementName isElement:@"UseHub"])
        self.results.useHub = [current isEqualToString:@"true"];
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [current appendString:string];
}
//- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end
