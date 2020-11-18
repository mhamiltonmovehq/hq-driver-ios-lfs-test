//
//  CustomerUtilities.m
//  Survey
//
//  Created by Tony Brame on 9/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CustomerUtilities.h"
#import "SurveyAppDelegate.h"
#import "ZipArchive.h"
#import "WebSyncRequest.h"
#import "Base64.h"
#import "Prefs.h"
#import "DriverData.h"
//#define Printer ePrint_Printer
#import "ePrint.h"
#import "ePrintDraw.h"
#import "AppFunctionality.h"
//#undef Printer

@implementation CustomerUtilities


+(double)getTotalCustomerWeight
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	RoomSummary *rs = [CustomerUtilities getTotalSurveyedSummary];
	SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
	int weight = 0;
	if(cust.estimatedWeight > 0)
		weight = cust.estimatedWeight;
	else
		weight = rs.weight;
		
	return weight;
}


+(double)getTotalCustomerCuFt
{
	RoomSummary *rs = [CustomerUtilities getTotalSurveyedSummary];
	int cuft = rs.cube;
		
	return cuft;
}


+(RoomSummary*)getTotalSurveyedSummary
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	return [CustomerUtilities getTotalSurveyedSummary:del.customerID];
}

+(RoomSummary*)getTotalSurveyedSummary:(int)custid
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	CubeSheet *cs = [del.surveyDB openCubeSheet:custid];
	
    NSArray *summaries = [del.surveyDB getRoomSummaries:cs customerID:custid];
	
	RoomSummary *rs = [RoomSummary totalRoomSummary:summaries];
	
    
	return rs;
}

+(NSDictionary*)getPricingModes
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    if ([del.pricingDB vanline] == ARPIN)
    {
        [dict setObject:@"AVL Registered" forKey:[NSNumber numberWithInt:INTERSTATE]];
        
    }
    else
    {
        
	[dict setObject:@"Interstate" forKey:[NSNumber numberWithInt:INTERSTATE]];
        
    }
    //local tariff
    [dict setObject:@"Local" forKey:[NSNumber numberWithInt:LOCAL]];
    
    //if canada? only opening this up to atlas and UVLC for now
    if ([AppFunctionality enableCanadianPricingModes])
    {
        [dict setObject:@"Canada Non-Gov't" forKey:[NSNumber numberWithInt:CNCIV]];
        [dict setObject:@"Canada Gov't" forKey:[NSNumber numberWithInt:CNGOV]];
    }
    
    return dict;
}

+(NSDictionary*)getInventoryTypes
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:@"Standard" forKey:[NSNumber numberWithInt:0]];
    [dict setObject:@"Auto" forKey:[NSNumber numberWithInt:1]];
    [dict setObject:@"Standard/Auto" forKey:[NSNumber numberWithInt:2]];
    
    return dict;
}

+(NSMutableDictionary*)getEstimateTypes
{
	NSMutableDictionary *estimateTypes = [[NSMutableDictionary alloc] init];
	
	[estimateTypes setObject:@" - No Estimate Type Selection - " forKey:[NSNumber numberWithInt:EST_NONE]];

    [estimateTypes setObject:@"Binding" forKey:[NSNumber numberWithInt:BINDING]];
    [estimateTypes setObject:@"Not To Exceed" forKey:[NSNumber numberWithInt:NOT_TO_EXCEED]];
    [estimateTypes setObject:@"Non Binding" forKey:[NSNumber numberWithInt:NON_BINDING]];
	
	
	return estimateTypes;
}

+(NSMutableDictionary*)getJobStatuses
{
	NSMutableDictionary *jobStatuses = [[NSMutableDictionary alloc] init];	
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	ShipmentInfo *info = [del.surveyDB getShipInfo:del.customerID];
	
	if(info.isOA)
	{
		[jobStatuses setObject:@"OA" forKey:[NSNumber numberWithInt:OA]];
	}
	else
	{
		[jobStatuses setObject:@"Estimate" forKey:[NSNumber numberWithInt:ESTIMATE]];
		[jobStatuses setObject:@"Booked" forKey:[NSNumber numberWithInt:BOOKED]];
		[jobStatuses setObject:@"Lost" forKey:[NSNumber numberWithInt:LOST]];
		[jobStatuses setObject:@"Closed" forKey:[NSNumber numberWithInt:CLOSED]];
		[jobStatuses setObject:@"OA" forKey:[NSNumber numberWithInt:OA]];
	}
		
	return jobStatuses;
}

#pragma mark Backups

+(NSArray*)allBackupFolders
{
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
	
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSError *err;
	
	BOOL isDir;
	if(![mgr fileExistsAtPath:backupDir isDirectory:&isDir])
	{
		if(![mgr createDirectoryAtPath:backupDir withIntermediateDirectories:YES attributes:nil error:&err])
		{
			[SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error creating Directory"];
			return [[NSArray alloc] init];
		}
	}
	
	NSArray *contents = [mgr contentsOfDirectoryAtPath:backupDir error:&err];
	
	return contents;
}

+(void)deleteBackup:(NSString*)path
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
	
	NSError *err;
	
	NSString *fullDir = [backupDir stringByAppendingPathComponent:path];
	
	if(![mgr removeItemAtPath:fullDir error:&err])
	{
		[SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Deleting File"];
	}
	
}

+(BOOL)restoreBackup:(NSString*)path
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
	
	NSError *err;
	
	NSString *fullDir = [backupDir stringByAppendingPathComponent:path];
	NSString *newDBPath = [fullDir stringByAppendingPathComponent:SURVEY_DB_NAME];
	
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *oldDBPath = [del.surveyDB fullDBPath];
	[del.surveyDB closeDB];
	
    
	if(![mgr removeItemAtPath:oldDBPath error:&err])
	{
		[SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Deleting Existing DBs"];
		return NO;
	}
	
    BOOL error = NO;
    
	if(![mgr copyItemAtPath:newDBPath toPath:oldDBPath error:&err])
	{
        error = YES;
		[SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
	}
    
    if([mgr fileExistsAtPath:[fullDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY]])
    {
        [mgr removeItemAtPath:[docsDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY] error:&err];
        if(![mgr copyItemAtPath:[fullDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY]
                         toPath:[docsDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY] error:&err])
        {
            error = YES;
            [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
        }
    }
    
    if([mgr fileExistsAtPath:[fullDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY]])
    {
        [mgr removeItemAtPath:[docsDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY] error:&err];
        if(![mgr copyItemAtPath:[fullDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY]
                         toPath:[docsDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY] error:&err])
        {
            error = YES;
            [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
        }
    }
    
    if(!error)
		[SurveyAppDelegate showAlert:@"Successfully restored databases." withTitle:@"Success!"];
	
    [del.surveyDB openDB:[del.pricingDB vanline]];
    
    
    //rebuild backups table based off of folder structure...
    //haveto do this since the restore won't list all backups,
    //and I don't want just pulling folders for the backup list (to retain database integrity)....
    
    [del.surveyDB updateDB:@"DELETE FROM Backups"];
    
    NSArray *backups = [CustomerUtilities allBackupFolders];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //11-19-2009 12:51 PM
    for (NSString *folder in backups) {
//        if(folder.length == 17)
//            [formatter setDateFormat:@"MM-dd-yyyy hmm a"];
//        else if(folder.length == 18)
//            [formatter setDateFormat:@"MM-dd-yyyy hhmm a"];
//        else
        //[formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss a"];
        NSDate *theDate = [CustomerUtilities dateFromString:folder];
        [del.surveyDB updateDB:[NSString stringWithFormat:@"INSERT INTO Backups(BackupDate,BackupFolder) VALUES(%f,'%@')",
                                [theDate timeIntervalSince1970], folder]];
    }
    
    //reset backup date...
    AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
    sched.lastBackup = [NSDate date];
    [del.surveyDB saveBackupSchedule:sched];
    
    return !error;
}

+(NSString*)backupDatabases:(BOOL)includeImages withSuppress:(BOOL)suppressAlert appDelegate:(SurveyAppDelegate *)del
{
    BOOL success = NO;
    return [CustomerUtilities backupDatabases:includeImages withSuppress:suppressAlert success:&success appDelegate:del];
}

+(NSString*)backupDatabases:(BOOL)includeImages withSuppress:(BOOL)suppressAlert success:(BOOL*)success appDelegate:(SurveyAppDelegate *)del
{	
	//per defect 783, from Dave Milner and Steve F - don't allow them to continue if there is low space on the device.
    if((([SurveyAppDelegate getFreeDiskspace]/1024ll)/1024ll) <= 10)
    {
        return @"Warning - device is dangerously low on memory storage. You will not be allowed to "
        "continue with this shipment. Data will not be saved until more memory storage is made available.";
    }
    
	AutoBackupSchedule *sched = [del.surveyDB getBackupSchedule];
    
    
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	//11-19-2009 12:51 PM
	[formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss a"];
	
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
	
	NSError *err;
	
    BackupRecord *rec = [[BackupRecord alloc] init];
    rec.backupDate = [NSDate date];
    rec.backupFolder = [formatter stringFromDate:rec.backupDate];
	NSString *fullDir = [backupDir stringByAppendingPathComponent:rec.backupFolder];
	
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL isDir;
	
	if(![mgr fileExistsAtPath:fullDir isDirectory:&isDir])
	{
		if(![mgr createDirectoryAtPath:fullDir withIntermediateDirectories:YES attributes:nil error:&err])
		{
            if(suppressAlert)
                return [err localizedDescription];
			[SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error creating backup Directory"];
			return nil;
		}
	}
	else
	{
        if(suppressAlert)
            return @"Unable to backup databases. Directory already exists, please wait one minute and try again.";
		[SurveyAppDelegate showAlert:@"Unable to backup databases. Directory already exists, please wait one minute and try again." withTitle:@"Error"];
		return nil;
	}
    
    
    [mgr removeItemAtPath:[[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"] error:nil];
    
	//now copy the surveydb to that dir...
	NSString *surveyDBPath = [del.surveyDB fullDBPath];
	[del.surveyDB closeDB];
	
    del.surveyDB = nil;
    
	NSString *newSurveyDBPath = [fullDir stringByAppendingPathComponent:SURVEY_DB_NAME];
	
    NSString *retval = nil;
    
    *success = FALSE;
    
	if(![mgr copyItemAtPath:surveyDBPath toPath:newSurveyDBPath error:&err])
	{
        if(suppressAlert)
            retval = [err localizedDescription];
        else
            [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
        
        goto exit;
	}
    
    //now copy images and pvoimages (images optional, pvo sigs not)
    if(includeImages && [mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY]])
    {
        //compress the images for the backup...
        if(![mgr copyItemAtPath:[docsDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY] toPath:[fullDir stringByAppendingPathComponent:IMG_ROOT_DIRECTORY] error:&err])
        {
            if(suppressAlert)
                retval = [err localizedDescription];
            else
                [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
            
            goto exit;
        }
    }
    
    if([mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY]])
    {
        if(![mgr copyItemAtPath:[docsDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY] toPath:[fullDir stringByAppendingPathComponent:IMG_PVO_DIRECTORY] error:&err])
        {
            if(suppressAlert)
                retval = [err localizedDescription];
            else
                [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Copying File"];
            
            goto exit;
        }
    }
    
    //for some reason (couldn't figure why), this backup caused the original db to become locked, so remove that db and replace with copy
    //(this will resolve the error)
    
    [mgr removeItemAtPath:surveyDBPath error:nil];
    [mgr copyItemAtPath:newSurveyDBPath toPath:surveyDBPath error:&err];
    
    *success = YES;
    
    
exit:
    
    del.surveyDB = [[SurveyDB alloc] initDB:[del.pricingDB vanline]];
	
	if(*success)
    {
        //check for old backups, save new.
        NSArray *allBacks = [del.surveyDB getAllBackups];
        
        if([allBacks count] >= sched.numBackupsToRetain)
        {
            for (int i = [allBacks count] - 1; i >= sched.numBackupsToRetain - 1; i--)
                [del.surveyDB deleteBackup:[allBacks objectAtIndex:i]];
        }
        
        [del.surveyDB saveNewBackup:rec];
        sched.lastBackup = rec.backupDate;
        [del.surveyDB saveBackupSchedule:sched];
    }
	
	
    
    return retval;
}

+(void)sendBackupToSupport:(NSString*)path
{//zip and send to support
	
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	NSString *backupDir = [docsDir stringByAppendingPathComponent:BACKUP_DIR];
	
	
	NSString *fullDir = [backupDir stringByAppendingPathComponent:path];
	NSString *filePath = [fullDir stringByAppendingPathComponent:SURVEY_DB_NAME];
	
	//have the file, now zip it, and send it.
	ZipArchive *zipper = [[ZipArchive alloc] init];
	
	NSString *archive = [fullDir stringByAppendingPathComponent:@"survey.zip"];
	
	[zipper CreateZipFile2:archive];
	[zipper addFileToZip:filePath newname:SURVEY_DB_NAME];
	[zipper CloseZipFile2];
	
	
	//now send it up...
	WebSyncRequest *req = [[WebSyncRequest alloc] init];
	req.serverAddress = @"ws.igcsoftware.com";
	req.type = FILE_UPLOAD;
	req.functionName = @"StoreFile";
	
	NSString *retval;
	
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	NSData *data = [NSData dataWithContentsOfFile:archive];
	
	WebSyncParam *param = [[WebSyncParam alloc] init];
	param.paramName = @"key";
	param.paramValue = @"AGN$&)*GPVUSDNFG";
	[args setValue:param forKey:[NSNumber numberWithInt:1].stringValue];
	
	param = [[WebSyncParam alloc] init];
	param.paramName = @"file";
	param.paramValue = [Base64 encode64WithData:data];
	[args setValue:param forKey:[NSNumber numberWithInt:2].stringValue];
	
	/*[args setValue:[Base64 encode64WithData:data] forKey:@"file"];
     [args setValue:[Base64 encode64WithData:data] forKey:@"file"];	*/
	[req sendFile:&retval withArguments:args needsDecoded:NO withSSL:NO];
	
	[SurveyAppDelegate showAlert:retval withTitle:@"File Store"];
	
}

#pragma mark printing

+(NSDictionary*)getPrintSettings:(StoredPrinter*)printer
{
	NSMutableDictionary		*dictionary = [[NSMutableDictionary alloc] init];
	
	if (printer.isBonjour) {
		[dictionary setObject:printer.bonjourSettings forKey:ePrintParameterBonjourInformation];
		[dictionary setObject:[NSNumber numberWithBool:YES] forKey:ePrintParameterBonjourMode];
	}
	else {
		[dictionary setObject:printer.address forKey:ePrintParameterPrinterAddress];
		[dictionary setObject:[NSNumber numberWithBool:NO] forKey:ePrintParameterBonjourMode];
		
		// <<< add HP Port9100 >>>
		[dictionary setObject:[NSNumber numberWithInteger:1]
					   forKey:ePrintParameterPrinterPort];
		[dictionary setObject:[NSNumber numberWithInteger:9100]
					   forKey:ePrintParameterPort9100Number];
	}
	
	//per email from ritsuko to tyson 11/15/10, hard coded ePrintPrinterKindPCL3GUI
	[dictionary setObject:[NSNumber numberWithInt:ePrintPrinterKindPCL3GUI/*printer.printerKind*/] forKey:ePrintParameterPrinterKind];
	
	[dictionary setObject:[NSNumber numberWithBool:NO] forKey:ePrintParameterColor];
	
	[dictionary setObject:[NSNumber numberWithInt:0] forKey:ePrintParameterOrientation];
	
	[dictionary setObject:[NSNumber numberWithBool:NO] forKey:ePrintParameterDuplex];
	
	/*  isSepia  */
	[dictionary setObject:[NSNumber numberWithInt:0] forKey:ePrintParameterEffect];
	
	/*  Draft Quality == 0, normal 1, high 2  */
	[dictionary setObject:[NSNumber numberWithInt:printer.quality] forKey:ePrintParameterQuality];
	
	/*if ( layout ) {
	 [dictionary setObject:layout forKey:ePrintParameterLayout];
	 }*/
	
	[dictionary setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:ePrintA4], nil]
													  forKeys:[NSArray arrayWithObjects:@"Code", nil]]
				   forKey:ePrintParameterPaperCode];	// Set the paperkind dictionary.
	
	/*  Plain Paper  */
	[dictionary setObject:[NSNumber numberWithInt:0] forKey:ePrintParameterMedia];
	
	return dictionary;
}

+(BOOL)printDisconnectedSupported
{
	return [[Prefs betaPassword] isEqualToString:BETA_PASS];
}

#pragma mark PVO

+(BOOL)roomConditionsEnabled
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *driverData = [del.surveyDB getDriverData];
    return driverData.enableRoomConditions;
}

+(NSMutableDictionary*)arpinSyncPreferences
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setObject:@"By Driver #/Pass" forKey:[NSNumber numberWithInt:PVO_ARPIN_SYNC_BY_DRIVER]];
	[dict setObject:@"By Agent #" forKey:[NSNumber numberWithInt:PVO_ARPIN_SYNC_BY_AGENT]];
	
	return dict;
}


+(BOOL)customerSourcedFromServer
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    ShipmentInfo *info = [del.surveyDB getShipInfo:del.customerID];
    return info.sourcedFromServer;
}

+(int)customerPricingMode
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    int pricingMode = cust.pricingMode;
    
    return pricingMode;
}

+(NSDate*)dateFromString:(NSString*)d
{
    if(d.length == 0){
        return nil;
    }
    
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    NSDate *o;
    
    [f setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    o = [f dateFromString:d];
    if(o != nil){
        return o;
    }
    
    [f setDateFormat:@"MM-dd-yyyy HH:mm:ss a"];
    o = [f dateFromString:d];
    if(o != nil){
        return o;
    }
    
    [f setDateFormat:@"MM-dd-yyyy hmm a"];
    o = [f dateFromString:d];
    if(o != nil){
        return o;
    }
    
    [f setDateFormat:@"MM-dd-yyyy hhmm a"];
    o = [f dateFromString:d];
    if(o != nil){
        return o;
    }
}

+(SurveyPhone*)setupContactPhone:(SurveyPhone*)phone withPhoneTypeId:(NSInteger)typeId {
    if (phone == nil) {
        phone = [[SurveyPhone alloc] init];
        phone.number = @"";
        phone.locationTypeId = ORIGIN_LOCATION_ID;
        phone.isPrimary = 0;
        phone.type.phoneTypeID = typeId;
    }
    return phone;
}

+(NSMutableString *)formatPhoneString:(NSMutableString *)str {
    NSMutableString *newString = [[NSMutableString alloc] init];
    if ([str length] > 10) {
        //do nothing
        [newString appendString:str];
    } else if ([str length] > 7) {//(xxx) xxx-xxxx format
        [newString appendString:@"("];
        
        for (int i = 0; i < 3; i++) {
            [newString appendFormat:@"%C", [str characterAtIndex:i]];
        }
        
        [newString appendString:@") "];
        
        for (int i = 3; i < 6; i++) {
            [newString appendFormat:@"%C", [str characterAtIndex:i]];
        }
        
        [newString appendString:@"-"];
        
        for (int i = 6; i < [str length]; i++) {
            [newString appendFormat:@"%C", [str characterAtIndex:i]];
        }
    } else {//xxx-xxxx format
        for (int i = 0; i < 3; i++) {
            if([str length] > i) {
                [newString appendFormat:@"%C", [str characterAtIndex:i]];
            }
        }
        
        if ([str length] > 3) {
            [newString appendString:@"-"];
        }
        
        for (int i = 3; i < [str length]; i++) {
            [newString appendFormat:@"%C", [str characterAtIndex:i]];
        }
    }
    return newString;
}


@end
