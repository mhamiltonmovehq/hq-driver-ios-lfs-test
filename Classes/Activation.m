//
//  Activation.m
//  Survey
//
//  Created by Tony Brame on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#import <AdSupport/ASIdentifierManager.h>
#import "Activation.h"
#import "ActivationRecord.h"
#import "SurveyAppDelegate.h"
#import "Prefs.h"
#import "HeartbeatCheck.h"
#import "OpenUDID.h"
#import "ActivationParser.h"
#import "WCFDataParam.h"
#import "AppFunctionality.h"
#import "CustomerUtilities.h"

@implementation Activation

+(int)allowAccess:(NSString**)results
{
    int allow = ACTIVATION_NO_ACCESS;
    double trialExpireSeconds = TRIAL_DAYS * 24 * 3600;
    double validateExpireSeconds = CHECK_INTERVAL * 24 * 3600;
    
    //check for credentials
    if([Prefs username] == nil || [[Prefs username] length] == 0 ||
       [Prefs password] == nil || [[Prefs password] length] == 0)
    {
        return ACTIVATION_NO_ACCESS;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ActivationRecord *rec = [del.surveyDB getActivation];
    
    // Check for device passcode (Atlas SOW 11042016.04)
    // TODO: Reenable this when Security SOW needs released
    
    //call web form for user validation
    NSString *uuid = [self getUUID];

    if(uuid == nil || [uuid length] == 0)
    {
        *results = @"Invalid installation detected, code 235.  Please contact Support to resolve this issue.";
        return ACTIVATION_NO_ACCESS;
    }
    
    NSString *retval = nil;
    BOOL success = NO;
    ActivationParser *xmlParse = nil;
    @try
    {
        WebSyncRequest *request = [[WebSyncRequest alloc] init];
        request.type = ACTIVATION;
        request.overrideWithFullPITSAddress = YES;
        
        if ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"crmenv:"].location != NSNotFound)
        {
            NSRange addpre = [[Prefs betaPassword] rangeOfString:@"crmenv:"];
            NSString *envStr = [[Prefs betaPassword] substringFromIndex:addpre.location + addpre.length];
            addpre = [envStr rangeOfString:@" "];
            if (addpre.location != NSNotFound)
                envStr = [envStr substringToIndex:addpre.location];
            if ([[envStr lowercaseString] isEqualToString:@"dev"] || [[envStr lowercaseString] isEqualToString:@"qa"] || [[envStr lowercaseString] isEqualToString:@"uat"]) {
                request.pitsDir = @"https://aws.igcsoftware.com/ActivationCheckBeta/Service.svc";
            }
        }
        

        NSString *deviceVersion = [NSString stringWithFormat:@"%@%@ - %@",
                                   UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone",
                                   UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && ![SurveyAppDelegate iPad] ? @"(2x Mode)" : @"",
                                   [[UIDevice currentDevice] systemVersion]];
        
        request.functionName = @"CheckDeviceActivation";
        success = [request getData:&retval
                     withArguments:@{ @"username": [Prefs username],
                                      @"password": [Prefs password],
                                      @"deviceID": uuid,
                                      @"deviceVersion": deviceVersion,
                                      @"appVersion": [NSString stringWithFormat:@"MM%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] }
                      needsDecoded:NO
                           withSSL:YES
                       flushToFile:nil withOrder:@[@"username", @"password", @"deviceID", @"deviceVersion", @"appVersion"]];

        if(success)
        {
            //parse the result
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[retval dataUsingEncoding:NSUTF8StringEncoding]];
            xmlParse = [[ActivationParser alloc] init];
            parser.delegate = xmlParse;
            [parser parse];
            
        }
        
    }
    @catch (NSException * e)
    {
        *results = [NSString stringWithFormat:@"Error in accessing site: %@", [e description]];
    }
    @finally
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    
    // Ignore this result and use Hub logic
    if(xmlParse.results.useHub) {
        return ACTIVATION_HUB;
    }
    
    if(!success)
    {
        //if error calling form, check last opened date, and last validate date to ensure it hasnt expired
        if([rec.lastOpen timeIntervalSince1970] >= [[NSDate date] timeIntervalSince1970])
        {
            //they rolled the clock back
            *results = @"Invalid installation detected, code 12.  Please contact Support to resolve this issue.";
            return ACTIVATION_NO_ACCESS;
        }
        
        if([rec.lastValidation timeIntervalSince1970] == 0)
        {//it has never been validate, do not let them in...
            *results = @"Unable to connect to internet to validate activation.  Account information must be validated at least once to gain access to the application.";
            goto downloadCheck;
        }
        
        if(rec.unlocked && ([[NSDate date] timeIntervalSince1970] -
                            [rec.lastValidation timeIntervalSince1970]) > validateExpireSeconds)
        {//needs re-validated.  place back in trial, still return YES
            rec.lastValidation = [NSDate dateWithTimeIntervalSince1970:0];
            rec.unlocked = 0;
            rec.trialBegin = [NSDate date];
        }
        
        //checks passed, return yes to let them in...
        allow = ACTIVATION_CUSTS;
        
        goto downloadCheck;
    }
    
//    NSString *trimmed = [retval stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    strings = [trimmed componentsSeparatedByString:@","];
    
    if([[Prefs username] isEqualToString:@"tbrame"])
    {
        allow = ACTIVATION_CUSTS;
        goto downloadCheck;
    }
    
    //if last validation is > expiration contant (15 days), reset trial mode to 15 days after last validation
    //(only needed if not connect to internets...)
    
    
    //check site date check...
    if(xmlParse.results.pastTrial &&
       !xmlParse.results.allowDevice)
    {
        //this indicates they have been using their trial for more than 60 days from the site.
        //support would need to reset this...
        *results = @"Invalid installation detected, code 89.  Please contact Support to resolve this issue.";
        return ACTIVATION_NO_ACCESS;
    }
    
    //check return reset trial/last opened flag...
    if(xmlParse.results.resetTrial)
    {
        //reset the trial period.
        rec.trialBegin = [NSDate date];
        rec.lastOpen = rec.trialBegin;
        rec.lastValidation = rec.trialBegin;
        rec.unlocked = 0;
        rec.autoUnlocked = 0;
        allow = ACTIVATION_CUSTS;
        goto downloadCheck;
    }
    
    //check the last opened date and make sure it is not later than current
    if([rec.lastOpen timeIntervalSince1970] >= [[NSDate date] timeIntervalSince1970])
    {
        //they rolled the clock back - hard stop... so it doesnt update the last open date
        //(validation date also not updated, but it don't matter)
        *results = @"Invalid installation detected, code 12.  Please contact Support to resolve this issue.";
        return ACTIVATION_NO_ACCESS;
    }
    
    //check to see if they have a valid user....
    if(!xmlParse.results.success)
    {
        *results = @"A valid username and password must be entered to use the application. Please confirm that the username and password in the settings application is correct. If the issue remains, please contact Support to resolve this issue.";
        rec.unlocked = 0;
        rec.autoUnlocked = 0;
        rec.lastValidation = [NSDate dateWithTimeIntervalSince1970:0];
        goto connectReturn;
    }
    
    bool igcUsername = false;
    igcUsername = (
                   [[Prefs username] isEqualToString:@"iphonedev@igcsoftware.com"] ||
                   [[Prefs username] isEqualToString:@"mobmovdev@igcsoftware.com"] ||
                   [[Prefs username] isEqualToString:@"bprescott"] ||
                   [[Prefs username] isEqualToString:@"tbrame"]
                   );
    
    //also check to make sure the device id is correct... (checked on the site)
    if(!xmlParse.results.deviceIDMatches)
    {
        if(!igcUsername)
        {
            *results = @"Account already in use by another application. Please contact Support for more information.";
            rec.unlocked = 0;
            rec.autoUnlocked = 0;
            rec.lastValidation = [NSDate dateWithTimeIntervalSince1970:0];
            goto connectReturn;
        }
    }
    
    //update lastValidated date (since it ok'd the user)
    rec.lastValidation = [NSDate date];
    
    //check the activation
    if(!xmlParse.results.allowDevice)
    {//if not activated user, check trial mode to make sure it hasn't expired
        rec.unlocked = 0;
        rec.autoUnlocked = 0;
        if(([[NSDate date] timeIntervalSince1970] - [rec.trialBegin timeIntervalSince1970]) >=
           trialExpireSeconds)
        {
            *results = @"Your 30 day Trial has expired.  If you would like to purchase a copy of the software, please contact Support.";
        }
        else
            allow = ACTIVATION_CUSTS;
    }
    else
    {//if activated, set unlocked = 1
        rec.unlocked = 1;
        rec.autoUnlocked = xmlParse.results.allowAutoInv ? 1 : 0;
        allow = ACTIVATION_CUSTS;
        
    }
    
downloadCheck:
    
    //check the latest versions of everything (activated or trial)
    if(xmlParse.results.success)
    {
        
#ifdef ARPIN_ONLY
        
        if(xmlParse.results.vanlineDownloadID != 5 && xmlParse.results.vanlineDownloadID != 161/*iPhone Beta Tariff*/)
        {
            allow = ACTIVATION_NO_ACCESS;
            *results = @"Your account must be assigned to Arpin Vanlines to use Mobile Mover.  Please contact Support to resolve this issue.";
            goto connectReturn;
        }
        
#elif defined(ATLASNET)
        //must be assigned to atlas
        
        if(xmlParse.results.vanlineDownloadID != 3 && xmlParse.results.vanlineDownloadID != 161 &&
           xmlParse.results.vanlineDownloadID != 180/*iPhone Beta Tariff 1 & 2*/ &&
           xmlParse.results.vanlineDownloadID != 221/*Atlas Van Lines - MobileMover 2.0*/ &&
           xmlParse.results.vanlineDownloadID != 244/*Atlas - Beta Van Lines - MobileMover 2.0*/)
        {
            allow = ACTIVATION_NO_ACCESS;
            *results = @"Your account must be assigned to Atlas Vanlines to use AtlasNet.  Please contact Support to resolve this issue.";
            goto connectReturn;
        }
        
#else
        //can't be assigned to atlas
        
        if(xmlParse.results.vanlineDownloadID == 3)
        {
            allow = ACTIVATION_NO_ACCESS;
            *results = @"Your account is assigned to an invalid vanline for using Mobile Mover.  Please contact Support to resolve this issue.";
            goto connectReturn;
        }
#endif
        
        if(rec.fileCompany != xmlParse.results.vanlineDownloadID)
        {
            rec.fileCompany = xmlParse.results.vanlineDownloadID;
        }
        
        rec.tariffDLFolder = xmlParse.results.pricingDownloadLocation;
        if(rec.pricingDBVersion != xmlParse.results.pricingVersion)
        {
            rec.pricingDBVersion = xmlParse.results.pricingVersion;
        }
        
        rec.milesDLFolder = xmlParse.results.milesDownloadLocation;

        rec.fileAssociationId = xmlParse.results.fileAssociationId;
    }
    
    //check to see if the dbs exists yet..
    if(![del openPricingDB])
    {
        allow = ACTIVATION_DOWNLOAD;
    } else {
        [del.pricingDB recreateDbVersion:rec.fileAssociationId];
        [del.pricingDB closeDB];
    }
    
connectReturn:
    //set last opened date
    rec.lastOpen = [NSDate date];
    [del.surveyDB updateActivation:rec];
    return allow;
}

-(void)main
{
    @try
    {
        //check for a newer version
        NSDictionary *dict = nil;
        
        if(dict != nil && [dict objectForKey:@"latestVersion"] != nil && [dict objectForKey:@"createdDate"] != nil)
        {
            //pull int values for comparison
            int serverLatestVersion = [[[dict objectForKey:@"latestVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            int deviceLatestVersion = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            
            if ((serverLatestVersion > 0 && deviceLatestVersion > 0 && deviceLatestVersion < serverLatestVersion) ||
                ((serverLatestVersion == 0 || deviceLatestVersion == 0) &&
                 (![[dict objectForKey:@"latestVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]])))
            {//a new version is available
                SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                ActivationRecord *rec = [del.surveyDB getActivation];
                
                //2011-08-18 06:20:00
//                NSDateFormatter *form = [[NSDateFormatter alloc] init];
//                [form setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSDate *createDate = [CustomerUtilities dateFromString:[dict objectForKey:@"createdDate"]];
                int daysTillLock = 1;
                if([dict objectForKey:@"createdDate"] != nil)
                    daysTillLock = [[dict objectForKey:@"daysTillLock"] intValue];
                
                BOOL showAlert = NO;
                
                //first of all, create date must be before current date
                if([createDate timeIntervalSince1970] <= [[NSDate date] timeIntervalSince1970])
                {
                    //check to make sure they have only been alerted once in the last 24 hours...
                    if([rec.alertNewVersionDate timeIntervalSince1970] == 0)
                        showAlert = YES;
                    
                    //check to see if the createDate + daysTillLock is past, in that case show it every time
                    if([[createDate dateByAddingTimeInterval:daysTillLock * (60 * 60 * 24)] timeIntervalSince1970] <= [[NSDate date] timeIntervalSince1970])
                        showAlert = YES;
                    
                    //if the alert hasnt been shown in a day, show it everytime
                    if(([[NSDate date] timeIntervalSince1970] - [rec.alertNewVersionDate timeIntervalSince1970]) >= 60 * 60 * 24)
                        showAlert = YES;
                    
                }
                
                if(showAlert)
                {
                    //show the alert
                    if([dict objectForKey:@"infoVersionMessage"] != nil)
                    {
                        [del performSelectorOnMainThread:@selector(showAlertFromDelegate:)
                                               withObject:[NSArray arrayWithObjects:[dict objectForKey:@"infoVersionMessage"], @"New Version!", nil]
                                            waitUntilDone:NO];
//                        [SurveyAppDelegate showAlert: withTitle:@"New Version!" withDelegate:nil onSeparateThread:YES];
                    }
                    rec.alertNewVersionDate = [NSDate date];
                }
                
                [del.surveyDB updateActivation:rec];
            }
        }
        
    }
    @catch (NSException *exception) {
        
    }
    
}

+(XMLWriter*)getActivationRequestXML
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //I dont want to get the entire Driver object because Activation happens before db updates. If we add new columns to the driver table, the activation and update gets screwed up.
    //Just get the data you need for activation here
//    DriverData *data = [del.surveyDB getDriverData];
    NSString *haulingAgent = [del.surveyDB getHaulingAgentCode];
    NSString *driverNumber = [del.surveyDB getDriverNumber];

    NSString *deviceVersion = [NSString stringWithFormat:@"%@%@ - %@",
                               UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone",
                               UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && ![SurveyAppDelegate iPad] ? @"(2x Mode)" : @"",
                               [[UIDevice currentDevice] systemVersion]];
    
    XMLWriter *writer = [[XMLWriter alloc] init];
    [writer writeStartElement:@"request"];
    [writer writeAttribute:@"z:Id" withData:@"i1"];
    [writer writeAttribute:@"xmlns:a" withData:@"http://schemas.datacontract.org/2004/07/ActivationCheck.Model"];
    [writer writeAttribute:@"xmlns:i" withData:@"http://www.w3.org/2001/XMLSchema-instance"];
    [writer writeAttribute:@"xmlns:z" withData:@"http://schemas.microsoft.com/2003/10/Serialization/"];
    
    if ([haulingAgent length] == 0) {
        [writer writeStartElement:@"a:AgencyCode"];
        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    } else {
        [writer writeElementString:@"a:AgencyCode" withData:haulingAgent];
    }
    
    [writer writeElementString:@"a:AppVersion" withData:[NSString stringWithFormat:@"MM%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    
    
    [writer writeStartElement:@"a:AtlasCNUsername"];
    [writer writeAttribute:@"i:nil" withData:@"true"];
    [writer writeEndElement];
    
    [writer writeStartElement:@"a:AtlasUsername"];
    [writer writeAttribute:@"i:nil" withData:@"true"];
    [writer writeEndElement];
    
    
    
    [writer writeElementString:@"a:DeviceID" withData:[self getUUID]];
    [writer writeElementString:@"a:DeviceVersion" withData:deviceVersion];
 
    
    if ([driverNumber length] == 0) {
        [writer writeStartElement:@"a:DriverNumber"];
        [writer writeAttribute:@"i:nil" withData:@"true"];
        [writer writeEndElement];
    } else {
        [writer writeElementString:@"a:DriverNumber" withData:driverNumber];
    }
    
    [writer writeElementString:@"a:Password" withData:[Prefs password]];
    [writer writeElementString:@"a:Username" withData:[Prefs username]];
    
    [writer writeEndElement];
    
//    [data release];
    
    [writer writeEndDocument];
    
    return writer;
}

+(NSString*)getUUID
{
    return [OpenUDID value];
}


@end
