//
//  BrotherOldSDKStructs.m
//  Survey
//
//  Created by Tony Brame on 2/6/15.
//
//

#import "BrotherOldSDKStructs.h"
#import "Prefs.h"
#import <BRPtouchPrinterKit/BRPtouchPrinterKit.h>
#import "BrotherPrinterChecker.h"
#import "SurveyAppDelegate.h"

@implementation PJ673PrintSettings

+(void)hasBrotherAttachedWithDelegate:(NSObject<PJ673PrintSettingsDelegate>*)delegate
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    PJ673PrintSettings *settings = [[PJ673PrintSettings alloc] init];
    [settings loadPreferences];
    
    if(settings.IPAddress != nil && settings.IPAddress.length > 0)
    {
        BrotherPrinterChecker *presenceChecker = [[BrotherPrinterChecker alloc] init];
        presenceChecker.delegate = delegate;
        
        [del.operationQueue addOperation:presenceChecker];
        
    }
    else
    {
        if(delegate != nil && [delegate respondsToSelector:@selector(pj673SettingsFoundReadyPrinter:)])
            [delegate pj673SettingsFoundReadyPrinter:[NSNumber numberWithBool:NO]];
    }
}

+(BRPtouchPrintInfo *)defaultPrintInfo
{
    BRPtouchPrintInfo *printInfo = [[BRPtouchPrintInfo alloc] init];
    
    NSDictionary *prefs = [Prefs brotherSettings];
    
    NSString *paperType = [prefs objectForKey:@"PaperType"];
    if(paperType == nil)
        printInfo.strPaperName = @"LETTER_Roll";
    else
        printInfo.strPaperName = paperType;
    
    printInfo.nPrintMode = PRINT_FIT;
    printInfo.nDensity = 10;
    printInfo.nOrientation = ORI_PORTRATE;
    printInfo.nHalftone = HALFTONE_ERRDIF;
    printInfo.nHorizontalAlign = ALIGN_CENTER;
    printInfo.nVerticalAlign = ALIGN_MIDDLE;
    printInfo.nPaperAlign = PAPERALIGN_LEFT;
    
    return printInfo;
}


-(void)loadPreferences
{
    NSDictionary *prefs = [Prefs brotherSettings];
    
    self.IPAddress = [prefs objectForKey:@"IPAddress"];
    self.strPaperType = [prefs objectForKey:@"PaperType"];
    if(self.strPaperType == nil)
        self.strPaperType = @"LETTER_Roll";
    
}

-(void)savePaperType:(NSString*)type
{
    NSMutableDictionary *prefs = [Prefs brotherSettings];
    
    self.strPaperType = type;
    [prefs setValue:type forKey:@"PaperType"];
    
    [Prefs setBrotherSettings:prefs];
}

-(void)saveIPAddress:(NSString*)address
{
    NSMutableDictionary *prefs = [Prefs brotherSettings];
    
    self.IPAddress = address;
    [prefs setValue:address forKey:@"IPAddress"];
    
    [Prefs setBrotherSettings:prefs];
}

@end
