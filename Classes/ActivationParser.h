//
//  ActivationParser.h
//  Survey
//
//  Created by Tony Brame on 9/25/14.
//
//

#import <Foundation/Foundation.h>
#import "Activation.h"
#import "WCFParser.h"

@interface ActivationParser : WCFParser <NSXMLParserDelegate>
{
    NSMutableString *current;
}

@property (nonatomic, retain) Activation *results;

@end
