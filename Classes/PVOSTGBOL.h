//
//  PVOSTGBOL.h
//  Survey
//
//  Created by Brian Prescott on 10/17/17.
//
//

#import <Foundation/Foundation.h>

#define BOLDIRECTORY   @"BOL"

@interface PVOSTGBOL : NSObject
{
}

+ (void)checkForDirectory;
+ (NSString *)fullPathForCustomer:(NSInteger)customerID;

@end
