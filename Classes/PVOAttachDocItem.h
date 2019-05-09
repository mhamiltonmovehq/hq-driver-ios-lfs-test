//
//  PVOAttachDocItem.h
//  Survey
//
//  Created by Lee Zumstein on 8/19/14.
//
//

#import <Foundation/Foundation.h>

@interface PVOAttachDocItem : NSObject

@property (nonatomic) int attachDocID;
@property (nonatomic) int navItemID;
@property (nonatomic, strong) NSString *description;
@property (nonatomic) int driverType;

@end
