//
//  BrotherPrinterChecker.m
//  Survey
//
//  Created by Tony Brame on 8/25/15.
//
//

#import "BrotherPrinterChecker.h"
#import <BRPtouchPrinterKit/BRPtouchPrinterKit.h>

@interface BrotherPrinterChecker ()


@end

@implementation BrotherPrinterChecker


-(void)main
{
    BOOL printerFound = NO;
 
    @try {
        
        PJ673PrintSettings *settings = [[PJ673PrintSettings alloc] init];
        [settings loadPreferences];
        
        if(settings.IPAddress != nil && settings.IPAddress.length > 0)
        {
            BRPtouchPrinter	*ptp = [[BRPtouchPrinter alloc] initWithPrinterName:@"Brother PJ-673"];
            
            [ptp setIPAddress:settings.IPAddress];
            
            [ptp setPrintInfo:[PJ673PrintSettings defaultPrintInfo]];
            
            printerFound = [ptp isPrinterReady];            
        }
        
    }
    @finally {
        
        if(self.delegate != nil && [self.delegate respondsToSelector:@selector(pj673SettingsFoundReadyPrinter:)])
            [self.delegate performSelectorOnMainThread:@selector(pj673SettingsFoundReadyPrinter:) withObject:[NSNumber numberWithBool:printerFound] waitUntilDone:NO];
        
    }
    
}

-(void)dealloc
{
    self.delegate = nil;
}

@end
