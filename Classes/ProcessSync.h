//
//  ProcessSync.h
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSyncRequest.h"
#import "XMLWriter.h"
#import "SurveyDownloadXMLParser.h"

@interface ProcessSync : NSOperation {
    NSObject *updateWindow;
    SEL updateCallback;
    SEL completedCallback;    
    SEL errorCallback;    
    WebSyncRequest *req;
    
    BOOL downloadCustomItemLists;
}

@property (nonatomic) SEL updateCallback;
@property (nonatomic) SEL completedCallback;
@property (nonatomic) SEL errorCallback;
@property (nonatomic) BOOL downloadCustomItemLists;

@property (nonatomic, strong) NSObject *updateWindow;

-(void)updateProgress:(NSString*)updateString;
-(void)completed;
-(void)error;

@end
