//
//  CommonNote.h
//  Survey
//
//  Created by Tony Brame on 8/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CommonNote : NSObject {
    int recID;
    int type;
    NSString *note;
}

@property (nonatomic) int recID;
@property (nonatomic) int type;
@property (nonatomic, strong) NSString *note;

@end
