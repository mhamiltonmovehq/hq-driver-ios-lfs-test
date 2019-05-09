//
//  Room.h
//  Survey
//
//  Created by Tony Brame on 5/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Room : NSObject {
    int roomID;
    NSString *roomName;
}

@property (nonatomic) int roomID;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *CNItemCode;
@property (nonatomic) int isHidden;

+(NSMutableDictionary*) getDictionaryFromRoomList: (NSArray*)rooms;

@end
