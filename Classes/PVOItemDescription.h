//
//  PVOItemDescription.h
//  Survey
//
//  Created by Tony Brame on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PVOItemDescription : NSObject
{
    int pvoItemDescriptionID;
    int pvoItemID;
    NSString *descriptionCode;
    NSString *description;
}

@property (nonatomic) int pvoItemDescriptionID;
@property (nonatomic) int pvoItemID;

@property (nonatomic, strong) NSString *descriptionCode;
@property (nonatomic, strong) NSString *description;

-(NSString*)listItemDisplay;

@end
