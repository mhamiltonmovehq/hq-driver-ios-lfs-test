//
//  PVOSTGBOLParser.h
//  Survey
//
//  Created by Brian Prescott on 10/13/17.
//
//

#import <Foundation/Foundation.h>

@interface PVOSTGBOLParser : NSObject
{
}

@property (nonatomic, retain) NSString *stgBolXml;

- (void)parseXml:(NSString *)xml;
- (void)writeXmlToFile:(NSInteger)customerID;

@end
