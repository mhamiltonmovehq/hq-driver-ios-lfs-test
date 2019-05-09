//
//  PVOBarcodeValidation.h
//  Survey
//
//  Created by Lee Zumstein on 2/21/14.
//
//

#import <Foundation/Foundation.h>
#import "SurveyCustomer.h"

@interface PVOBarcodeValidation : NSObject

+(UIKeyboardType)getKeyboardTypeForLotNumber:(enum PRICING_MODE_TYPE)pricingMode withCurrentLotNum:(NSString*)lotNumber;
+(BOOL)validateLotNumber:(NSString*)lotNumber outError:(NSString**)error;
+(BOOL)validateItemNumber:(NSString*)itemNumber outError:(NSString**)error;
+(BOOL)validateBarcode:(NSString*)barcode outError:(NSString**)error;

@end
