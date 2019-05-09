//
//  PVOConfirmationDetails.h
//  Survey
//
//  Created by Tony Brame on 4/16/15.
//
//

#import <Foundation/Foundation.h>

@interface PVOConfirmationDetails : NSObject

@property (nonatomic) int navItemID;
@property (nonatomic, retain) NSString *confirmationText;
@property (nonatomic, retain) NSString *continueButtonText;
@property (nonatomic, retain) NSString *cancelButtonText;

@end
