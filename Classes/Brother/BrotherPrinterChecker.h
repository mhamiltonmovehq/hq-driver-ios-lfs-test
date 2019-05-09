//
//  BrotherPrinterChecker.h
//  Survey
//
//  Created by Tony Brame on 8/25/15.
//
//

#import <UIKit/UIKit.h>
#import "BrotherOldSDKStructs.h"

@interface BrotherPrinterChecker : NSOperation

@property (nonatomic, retain) NSObject<PJ673PrintSettingsDelegate> *delegate;

@end
