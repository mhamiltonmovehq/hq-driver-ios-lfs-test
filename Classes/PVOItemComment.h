//
//  PVOItemComment.h
//  Survey
//
//  Created by Justin Little on 7/7/14.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "XMLWriter.h"

#define COMMENT_TYPE_LOADING 0
#define COMMENT_TYPE_UNLOADING 1

@interface PVOItemComment : NSObject
{
    NSString *comment;
    int commentType;
}

@property (nonatomic, strong) NSString *comment;
@property (nonatomic) int commentType;

-(void)flushToXML:(XMLWriter*)retval;

@end


