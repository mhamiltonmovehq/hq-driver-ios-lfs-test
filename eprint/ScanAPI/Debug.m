//
//  Debug.m
//  ScannerSettings
//
//  Created by Eric Glaenzer on 7/18/11.
//  Copyright 2011 Socket Mobile, Inc. All rights reserved.
//

#import "Debug.h"


@implementation Debug
+(void)Msg:(Debuglevel)level Text:(NSString *)text{
    
#ifndef NDEBUG
    NSString* szLevel=@"Info";
    switch(level){
        case kLevelTrace:szLevel=@"Traces:";break;
        case kLevelWarning:szLevel=@"Warning:";break;
        case kLevelError:szLevel=@"Error!:";break;
    }
    NSLog(@"%@:%@",szLevel,text);
#endif
}
@end
