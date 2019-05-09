//
//  LoadCustomItemLists.h
//  Survey
//
//  Created by Tony Brame on 3/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProcessSync.h"
#import "WebSyncRequest.h"

@interface LoadCustomItemLists : NSObject {
    ProcessSync *caller;
    WebSyncRequest *req;
}

@property (nonatomic, strong) ProcessSync *caller;

-(BOOL)runItemListsSync;
-(BOOL)downloadItemLists;


@end
