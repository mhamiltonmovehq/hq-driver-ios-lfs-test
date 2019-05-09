//
//  PVOBarcodeValidation.m
//  Survey
//
//  Created by Lee Zumstein on 2/21/14.
//
//

#import "PVOBarcodeValidation.h"
#import "CustomerUtilities.h"
#import "SurveyAppDelegate.h"
#import "SurveyCustomer.h"

@implementation PVOBarcodeValidation

+(UIKeyboardType)getKeyboardTypeForLotNumber:(enum PRICING_MODE_TYPE)pricingMode withCurrentLotNum:(NSString*)lotNumber
{
    return UIKeyboardTypeASCIICapable;
}

+(BOOL)validateLotNumber:(NSString*)lotNumber outError:(NSString**)error;
{
    BOOL isValid = YES;
    *error = nil;
    if (lotNumber == nil || [lotNumber length] == 0)
    {
        isValid = NO;
        *error = @"Lot Number must contain a value.";
    }
#ifdef ATLASNET
    else
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
        if (cust.pricingMode == INTERSTATE)
        {
            if ([lotNumber length] > 7)
            {
                isValid = NO;
                *error = @"Lot Number cannot exceed 7 characters in length.";
            }
            else
            {
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                if ([del.pricingDB vanline] != ARPIN)
                {
                    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
                    [numFormatter setAllowsFloats:NO];
                    NSString *lotNumToValidate = [NSString stringWithString:lotNumber];
                    if (lotNumToValidate.length > 0)
                        lotNumToValidate = [lotNumToValidate substringFromIndex:1];
                    if ([lotNumToValidate length] > 0 && [numFormatter numberFromString:lotNumToValidate] == nil)
                    {
                        isValid = NO;
                        *error = @"Lot Number may only contain numeric characters after first character.";
                    }
                    [numFormatter release];
                }
            }
        }
    }
#endif
    return isValid;
}

+(BOOL)validateItemNumber:(NSString*)itemNumber outError:(NSString**)error;
{
    BOOL isValid = YES;
    *error = nil;
    if (itemNumber == nil || [itemNumber length] == 0)
    {
        isValid = NO;
        *error = @"Item Number must contain a value.";
    }
    else
    {
        NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setAllowsFloats:NO];
        if ([itemNumber length] != 3 || [numFormatter numberFromString:itemNumber] == nil)
        {
            isValid = NO;
            *error = @"Item Number must be 3 numeric characters.";
        }
    }
    return isValid;
}

+(BOOL)validateBarcode:(NSString*)barcode outError:(NSString**)error;
{
    BOOL isValid = NO;
    *error = nil;
    
    NSString *lotNumber = nil, *itemNumber = nil;
    if (barcode != nil && [barcode length] >= 3)
    {
        itemNumber = [barcode substringFromIndex:[barcode length]-3];
        if ([barcode length] > 3)
            lotNumber = [barcode substringToIndex:[barcode length]-3];
        else
            lotNumber = nil;
    }
    NSString *err = nil;
    if (![PVOBarcodeValidation validateLotNumber:lotNumber outError:&err])
        *error = err;
    else if (![PVOBarcodeValidation validateItemNumber:itemNumber outError:&err])
        *error = err;
    else
        isValid = YES; //both of em passed
    
    return isValid;
}

@end
