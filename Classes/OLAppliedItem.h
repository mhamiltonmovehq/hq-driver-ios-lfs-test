//
//  OLAppliedItem.h
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"


@interface OLAppliedItem : NSObject {
    int appliedItemId;
    int opListID;
    int customerID;
    int sectionID;
    int questionID;
    NSString *textResponse;
    BOOL yesNoResponse;
    NSDate *dateResponse;
    double qtyResponse;
    NSString *multChoiceResponse;
    NSString *serverListID;
    int vehicleId;
}

@property (nonatomic) int appliedItemId;
@property (nonatomic) int opListID;
@property (nonatomic) int customerID;
@property (nonatomic) int sectionID;
@property (nonatomic) int questionID;
@property (nonatomic, retain) NSString *textResponse;
@property (nonatomic) BOOL yesNoResponse;
@property (nonatomic, retain) NSDate *dateResponse;
@property (nonatomic) double qtyResponse;
@property (nonatomic, retain) NSString *multChoiceResponse;
@property (nonatomic, retain) NSString *serverListID;
@property (nonatomic) int vehicleId;

@end
