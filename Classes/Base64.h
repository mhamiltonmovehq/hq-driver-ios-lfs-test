//
//  Base64.h
//  Survey
//
//  Created by Tony Brame on 7/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Base64 : NSObject {

}

+ (NSString *) encode64: (NSString *)data;
+ (NSData *) decode64:(NSString *)string;
+ ( NSString *) encode64WithData: (NSData *)data;

@end
