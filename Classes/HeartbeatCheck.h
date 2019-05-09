//
//  PVOSync.h
//  Survey
//
//  Created by Tony Brame on 9/6/11
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSyncRequest.h"
#import "XMLWriter.h"
#import "SurveyDownloadXMLParser.h"


@interface HeartbeatCheck : NSOperation {
    NSObject *updateWindow;
    SEL updateCallback;
    SEL completedCallback;
    SEL errorCallback;
    WebSyncRequest *req;
}

@property (nonatomic) SEL updateCallback;
@property (nonatomic) SEL completedCallback;
@property (nonatomic) SEL errorCallback;

@property (nonatomic, strong) NSObject *updateWindow;

-(void)updateProgress:(NSString*)updateString;
-(void)completed;
-(void)error;
-(BOOL)checkActivation;


@end
