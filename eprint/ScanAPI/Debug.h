//
//  Debug.h
//  ScannerSettings
//
//  Created by Eric Glaenzer on 7/18/11.
//  Copyright 2011 Socket Mobile, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    kLevelTrace,
    kLevelWarning,
    kLevelError
}Debuglevel;

@interface Debug : NSObject {
}
+(void)Msg:(Debuglevel)level Text:(NSString*)text;
@end
