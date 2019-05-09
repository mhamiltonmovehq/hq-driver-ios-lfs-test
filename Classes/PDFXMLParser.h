//
//  PDFXMLParser.h
//  Survey
//
//  Created by mm-dev-ak on 5/15/17.
//
//

#import <Foundation/Foundation.h>

@interface PDFXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) BOOL parseIsSuccessful;
@property (nonatomic) BOOL success;
@property (nonatomic, strong) NSString *output;

@end
