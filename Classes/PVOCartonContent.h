//
//  PVOCartonContent.h
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PVOCartonContent : NSObject {
    int contentID;
    NSString *description;
    int cartonContentID;
    int pvoItemID;
}

@property (nonatomic, retain) NSString *description;
@property (nonatomic) int contentID;
@property (nonatomic) int cartonContentID;
@property (nonatomic) int pvoItemID;
@property (nonatomic) int isHidden;

+(NSMutableDictionary*) getDictionaryFromContentList: (NSArray*)items;

@end
