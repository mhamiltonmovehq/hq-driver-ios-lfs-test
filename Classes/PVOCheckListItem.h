//
//  PVOCheckListItem.h
//  Survey
//
//  Created by David Yost on 9/14/15.
//
//

#import <Foundation/Foundation.h>

@interface PVOCheckListItem : NSObject
{
    int vehicleCheckListID;
    int checkListItemID;
    int customerID;
    NSString *agencyCode;
    int vehicleID;
    
    NSString *description;
    
    BOOL isChecked;
}

@property (nonatomic) int vehicleCheckListID;
@property (nonatomic) int checkListItemID;
@property (nonatomic) int customerID;
@property (nonatomic) int vehicleID;
@property (nonatomic, strong) NSString *agencyCode;

@property (nonatomic, strong) NSString *description;
@property (nonatomic) BOOL isChecked;

@end
