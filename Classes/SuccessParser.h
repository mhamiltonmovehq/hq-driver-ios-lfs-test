//
//  SuccessParser.h
//  Survey
//
//  Created by Tony Brame on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuccessParser : NSObject <NSXMLParserDelegate>  {
    NSMutableString *currentString;
    BOOL success;
    NSString *errorString;
    //used in post survey return
    int surveyID;
    BOOL storingData;
}

@property (nonatomic) BOOL success;
@property (nonatomic) int surveyID;

@property (nonatomic, strong) NSString *errorString;
@property (nonatomic, strong) NSMutableString *currentString;


@end
