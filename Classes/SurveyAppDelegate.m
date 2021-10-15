//
//  SurveyAppDelegate.m
//  Survey
//
//  Created by Tony Brame on 4/30/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
@import Firebase;
#include "TargetConditionals.h"
#import <AudioToolbox/AudioServices.h>
#import "SurveyAppDelegate.h"
#import	"SplashViewController.h"
#import "CustomerUtilities.h"
#import "RestoreDatabasesView.h"
#import "Prefs.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "AppFunctionality.h"
#import "CHCSVParser.h"
#import "HTMLReportGenerator.h"
#import "PVOItemDetailController.h"
#import "DriverDataController.h"
#import "EditDateController.h"
#import "EditAgentController.h"
#import "EditAddressController.h"
#import "EditPhoneController.h"
#import "NoteViewController.h"
#import "PVOWeightTicketController.h"
#import "RootViewController.h"
#import <Crashlytics/Crashlytics.h>
#if defined(ATLASNET)
#import <ScanbotSDK/ScanbotSDK.h>
#endif

@implementation SurveyAppDelegate

@synthesize window;
@synthesize navController;
@synthesize surveyDB;
@synthesize splashView, currentSocketListener, socketScanAPI, socketConnected;
@synthesize singleFieldController, socketTimer;
@synthesize customerID, currentPVOClaimID;
//@synthesize locationID;
@synthesize operationQueue, activationController, downloadDBs;
@synthesize singleDateController, pricingDB, pickerView, doubleDecFormatter; //, milesDB;
@synthesize dashCalcQueue, tablePicker, viewType;

@synthesize pvoDamageHolder;
@synthesize lastPackerInitials;
@synthesize activationError;

@synthesize debugController;

+(BOOL)hasInternetConnection
{
    return [self hasInternetConnection:FALSE];
}

+(BOOL)hasInternetConnection:(BOOL)testExternal
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    BOOL hasInternet = FALSE;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                hasInternet = FALSE;
            }
            else if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                hasInternet = TRUE;
            }
            else if (((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) &&
                     ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0))
                     
            {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                
                /*if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {*/
                    // ... and no [user] intervention is needed
                    hasInternet = TRUE;
                //}
            }
            else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                hasInternet = TRUE;
            }
        }
        //CFRelease(reachability);
    }
    
    if (hasInternet && testExternal)
    {//test external connection.  timeout of 10 seconds
        NSHTTPURLResponse *resp = nil;
        NSData *respData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://print.moverdocs.com/"]
                                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                                timeoutInterval:10.0]
                                                 returningResponse:&resp error:nil];
        
        hasInternet = (resp != nil && respData != nil);
        
        //if (resp != nil) [resp release];
        //if (respData != nil) [respData release];
    }
    
    return hasInternet;
}

+(BOOL)iPad
{
	//return FALSE;
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+(BOOL)iOS7OrNewer
{
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0);
}

+(BOOL)iOS8OrNewer
{
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);
}

+(BOOL)isRetina4
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    BOOL isRetinaHeight = rect.size.height == 568 || rect.size.height == 812;
    CGFloat scale = [[UIScreen mainScreen] scale];
    BOOL isRetinaScale = scale == 2 || scale == 3;
	return  isRetinaHeight && isRetinaScale;
}

+(NSString*)getLastTwoPathComponents:(NSString*)filePath
{
    NSArray* pathComponents = [filePath pathComponents];
    
    if ([pathComponents count] > 2) {
        NSArray* lastTwoArray = [pathComponents subarrayWithRange:NSMakeRange([pathComponents count]-2,2)];
        NSString* retval = [NSString pathWithComponents:lastTwoArray];
        return retval;
    }
}

+(UIImage*)resizeImage:(UIImage*)originalImage withNewSize:(CGSize)newSize
{
	UIGraphicsBeginImageContext(newSize);// a CGSize that has the size you want
	[originalImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	//image is the original UIImage
	UIImage* retval = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return retval;
}

+(UIImage*)resizeImage:(UIImage*)originalImage withNewWidth:(int)newWidth withNewImagePath:(NSString*)toPath
{
    CGImageRef imgRef = originalImage.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > newWidth || height > newWidth) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = newWidth;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = newWidth;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    // Calculate new size given scale factor.
    // Scale the original image to match the new size.
    UIGraphicsBeginImageContext(bounds.size);
    [originalImage drawInRect:CGRectMake(0, 0, bounds.size.width, bounds.size.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self saveNewImageToPath:compressedImage withNewImagePath:toPath];
}

+(void)resizeImageToScale:(UIImage *)originalImage scale:(CGFloat)scale withNewImagePath:(NSString*)toPath
{
    // Calculate new size given scale factor.
    CGSize originalSize = originalImage.size;
    CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);
    
    // Scale the original image to match the new size.
    UIGraphicsBeginImageContext(newSize);
    [originalImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self saveNewImageToPath:compressedImage withNewImagePath:toPath];
}

+(void)saveNewImageToPath:(UIImage *)image withNewImagePath:(NSString*)toPath
{
    NSData *data = UIImageJPEGRepresentation(image, 1.0f);
    NSString *filePath = toPath;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager createFileAtPath:filePath contents:data attributes:nil])
    {
#ifdef TARGET_IPHONE_SIMULATOR
        NSLog(@"error compressing photo");
#endif
    }
    
}

+(UIImage*) scaleAndRotateImage:(UIImage *)image withOrientation:(UIImageOrientation)orient  
{  
    int kMaxResolution = 300; // Or whatever  
	
	CGImageRef imgRef = image.CGImage;  
	
	CGFloat width = CGImageGetWidth(imgRef);  
	CGFloat height = CGImageGetHeight(imgRef);  
	
	CGAffineTransform transform = CGAffineTransformIdentity;  
	CGRect bounds = CGRectMake(0, 0, width, height);  
	if (width > kMaxResolution || height > kMaxResolution) {  
		CGFloat ratio = width/height;  
		if (ratio > 1) {  
			bounds.size.width = kMaxResolution;  
			bounds.size.height = bounds.size.width / ratio;  
		}  
		else {  
			bounds.size.height = kMaxResolution;  
			bounds.size.width = bounds.size.height * ratio;  
		}  
	}  
	
	CGFloat scaleRatio = bounds.size.width / width;  
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));  
	CGFloat boundHeight;  
	//UIImageOrientation orient = image.imageOrientation;  
	switch(orient) {  
			
		case UIImageOrientationUp: //EXIF = 1  
			transform = CGAffineTransformIdentity;  
			break;  
			
		case UIImageOrientationUpMirrored: //EXIF = 2  
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);  
			transform = CGAffineTransformScale(transform, -1.0, 1.0);  
			break;  
			
		case UIImageOrientationDown: //EXIF = 3  
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);  
			transform = CGAffineTransformRotate(transform, M_PI);  
			break;  
			
		case UIImageOrientationDownMirrored: //EXIF = 4  
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);  
			transform = CGAffineTransformScale(transform, 1.0, -1.0);  
			break;  
			
		case UIImageOrientationLeftMirrored: //EXIF = 5  
			boundHeight = bounds.size.height;  
			bounds.size.height = bounds.size.width;  
			bounds.size.width = boundHeight;  
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);  
			transform = CGAffineTransformScale(transform, -1.0, 1.0);  
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
			break;  
			
		case UIImageOrientationLeft: //EXIF = 6  
			boundHeight = bounds.size.height;  
			bounds.size.height = bounds.size.width;  
			bounds.size.width = boundHeight;  
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);  
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
			break;  
			
		case UIImageOrientationRightMirrored: //EXIF = 7  
			boundHeight = bounds.size.height;  
			bounds.size.height = bounds.size.width;  
			bounds.size.width = boundHeight;  
			transform = CGAffineTransformMakeScale(-1.0, 1.0);  
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
			break;  
			
		case UIImageOrientationRight: //EXIF = 8  
			boundHeight = bounds.size.height;  
			bounds.size.height = bounds.size.width;  
			bounds.size.width = boundHeight;  
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);  
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
			break;  
			
		default:  
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];  
			
	}  
	
	UIGraphicsBeginImageContext(bounds.size);  
	
	CGContextRef context = UIGraphicsGetCurrentContext();  
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {  
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);  
		CGContextTranslateCTM(context, -height, 0);  
	}  
	else {  
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);  
		CGContextTranslateCTM(context, 0, -height);  
	}
	
	CGContextConcatCTM(context, transform);  
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);  
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();  
	UIGraphicsEndImageContext();  
	
	return imageCopy;  
}

+(uint64_t)getFreeDiskspace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        //        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        //        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %@", [error domain], [error code]);
        return 0;
    }
    
    return totalFreeSpace;
}

+(NSString*)getDocsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	return documentsDirectory;
}

+(NSString*)getAttachDocTempDirectory
{
    return [[self getDocsDirectory] stringByAppendingPathComponent:@"tempAttachDocImages"];
}

+(void)handleException:(NSException *)exc
{
	NSString *str = [[NSString alloc] initWithFormat: @"error %@", exc];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

+(void)soundAlert
{
    [SurveyAppDelegate playSound:@"alert" musicType:@"wav"];
}

+(void)playSound: (NSString *) fileName musicType: (NSString *) fileType {
	SystemSoundID pmph; 
	
    NSString *sndpath = [[NSBundle mainBundle] pathForResource:fileName ofType: fileType];
    NSURL *baseURL = [[NSURL alloc] initFileURLWithPath:sndpath];
    CFURLRef url = CFBridgingRetain(baseURL);
	OSStatus error = AudioServicesCreateSystemSoundID(url, &pmph);
    
	if (error != kAudioServicesNoError) { // failed
		NSLog(@"Error %d loading sound", (int)error);
	}
	
	AudioServicesPlaySystemSound(pmph);
    
    CFRelease(url);
}

+(void)showAlert:(NSString *)message withTitle: (NSString*)title
{
	[SurveyAppDelegate showAlert:message withTitle:title withDelegate:nil];
}

+(void)showAlert:(NSString *)message withTitle: (NSString*)title withDelegate:(NSObject*)delegate
{
	[SurveyAppDelegate showAlert:message withTitle:title withDelegate:delegate onSeparateThread:NO];
}

+(void)showAlert:(NSString *)message withTitle: (NSString*)title withDelegate:(NSObject*)delegate onSeparateThread:(BOOL)throwExc
{
	if(throwExc)
	{
        [NSException raise:title format:@"%@", message];
	}
	else 
	{
       dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
		[alert show];
       });
	}

}

+(void)scrollTableToTextField:(UITextField*) field withTable:(UITableView*)tv atRow:(int)row
{
	
	CGRect frame = field.frame;
	CGFloat rowHeight = tv.rowHeight;
	frame.origin.y += rowHeight * row;
	
	CGFloat viewHeight = tv.frame.size.height;
	CGFloat halfHeight = viewHeight / 2;
	CGFloat midpoint = frame.origin.y + (field.frame.size.height / 2);
	if (midpoint < halfHeight)
	{
		frame.origin.y = 0;
		frame.size.height = midpoint;
	}
	else
	{
		frame.origin.y = midpoint;
		frame.size.height = midpoint;
	}
	[tv scrollRectToVisible:frame animated:YES];	
	
}

+(NSString*)formatCurrency:(double)number
{
	return [SurveyAppDelegate formatCurrency:number withCommas:FALSE];
}

+(NSString*)formatCurrency:(double)number withCommas:(BOOL)commas
{
	if(!commas)
		return [NSString stringWithFormat:@"$ %@", [SurveyAppDelegate formatDouble:number]];
	else
	{
		NSNumber *aNumber = [NSNumber numberWithDouble:number];
		
		NSNumberFormatter *frmtr = [[NSNumberFormatter alloc] init];
		[frmtr setGroupingSize:3];
		[frmtr setGroupingSeparator:@","];
		[frmtr setUsesGroupingSeparator:YES];
		[frmtr setMinimumFractionDigits:2];
		[frmtr setMaximumFractionDigits:2];
		NSString *commaString = [frmtr stringFromNumber:aNumber];
		
		return [NSString stringWithFormat:@"$ %@", commaString];
	}
}

+(NSString*)formatDouble:(double)number
{
	return [SurveyAppDelegate formatDouble:number withPrecision:2];
}

+(BOOL)isHighRes
{
	return FALSE;
	//return [[UIScreen mainScreen] scale] == 2.0;
}

+(NSString*)formatDouble:(double)number withPrecision:(int)decimals
{
	NSMutableString *string = [[NSMutableString alloc] initWithFormat:@"0%@", decimals > 0 ? @"." : @""];
	for(int i = 0; i < decimals; i++)
		[string appendString:@"0"];
	
	SurveyNumFormatter *formatter = [[SurveyNumFormatter alloc] init];
	[formatter setPositiveFormat:string];
	NSString *retval = [formatter stringFromDouble:number];

	return retval;
}

//gets a date from a month/day/year string
+(NSDate*)prepareDate:(NSString*)passed
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSDate *date = [dateFormatter dateFromString:passed];
	
	return date;
}

+(BOOL)dateAfter:(NSDate*)date year:(int)yr month:(int)mon day:(int)dy
{
	NSDate *newDate = [SurveyAppDelegate prepareDate:[NSString stringWithFormat:@"%d/%d/%d", mon, dy, yr]];
	
	return [date compare:newDate] == NSOrderedDescending;
}

//gets a date from a month/day/year string
+(NSString*)formatDate:(NSDate*)passed
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSString *date = [dateFormatter stringFromDate:passed];
	return date;
}

+(NSString*)formatTime:(NSDate*)passed
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"hh:mm a"];
	NSString *date = [dateFormatter stringFromDate:passed];
	return date;
}

+(NSString*)formatDateAndTime:(NSDate*)passed
{
    return [SurveyAppDelegate formatDateAndTime:passed asGMT:YES]; //default to YES
}

+(NSString*)formatDateAndTime:(NSDate*)passed asGMT:(BOOL)asGMT
{
    return [SurveyAppDelegate formatDateAndTime:passed withDateFormat:@"MM/dd/yyyy' 'hh:mm a" asGMT:asGMT];
}

+(NSString*)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString*)format
{
    return [SurveyAppDelegate formatDateAndTime:passed withDateFormat:format asGMT:YES]; //default to YES
}

+(NSString*)formatDateAndTime:(NSDate *)passed withDateFormat:(NSString*)format asGMT:(BOOL)asGMT
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (asGMT)
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateFormat:format];
	NSString *date = [dateFormatter stringFromDate:passed];
	return date;
}

+(NSString*)stringFromBytes:(long long)bytes
{
	NSString *retval;
	
	if(bytes > ONE_MB)
	{
		retval = [[NSString alloc] initWithFormat:@"%@ %@",
				  [SurveyAppDelegate formatDouble:(bytes/(double)ONE_MB) withPrecision:2],
				  MB_STRING];
	}
	else if(bytes > ONE_KB)
	{
		retval = [[NSString alloc] initWithFormat:@"%lld %@", (bytes/ONE_KB), KB_STRING];
	}
	else 
	{//just bytes
		retval = [[NSString alloc] initWithFormat:@"%lld %@", bytes, BYTE_STRING];
	}

	
	return retval;
    
}

+(void)setupViewForCartonContent:(UIView*)view withTableView:(UITableView*)tableView
{
    if (view != nil)
        [view setBackgroundColor:[SurveyAppDelegate getCartonContentBackgroundColor]];
    if (tableView != nil)
        [tableView setBackgroundView:nil];
}

+(UIColor*)getCartonContentBackgroundColor
{
    //return [UIColor colorWithRed:167.0/255.0 green:137.0/255.0 blue:85.0/255.0 alpha:100]; //original color
    return [UIColor colorWithRed:212.0/255.0 green:172.0/255.0 blue:103.0/255.0 alpha:100]; //my color (a little lighter)
}

+(UIColor*)getiOSBlueButtonColor
{
    return [UIColor colorWithRed:(3.0/255.0) green:(122.0/255.0) blue:(255.0/255.0) alpha:100];
}

+(void)removeCartonContentColorFromView:(UIView*)view
{
    UIColor *defaultColor = [UIColor whiteColor];
    if (view != nil)
        [view setBackgroundColor:defaultColor];
}

+(void)adjustTableViewForiOS7:(UITableView *)tableView
{
    if ([self iOS7OrNewer])
    {
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, 4.0f)];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, 4.0f)];
    }
}

-(id)init
{
	
	if ((self = [super init])) {
		
		//open the global database
		
		self.dashCalcQueue = [[NSOperationQueue alloc] init];
		self.operationQueue = [[NSOperationQueue alloc] init];
		
        if(![self debugCodeValid])//debug mode, don't open databases.
            [self initDBs];
		
		self.doubleDecFormatter = [[SurveyNumFormatter alloc] init];
		[doubleDecFormatter setPositiveFormat:@"0.00"];
		
        //need to add logic to be driven from website database.
		viewType = OPTIONS_PVO_VIEW;// OPTIONS_PVO_VIEW; OPTIONS_STANDARD_VIEW
        
        dummySocketReceiver = [[SocketDummyReceiver alloc] init];
        
        lineaDel = [[LineaDummyDelegate alloc] init];
	}
	return self;
	
}

-(void)initDBs
{
    [self initDBsWithBackups:nil];
}

-(void)initDBsWithBackups:(NSArray*)backupArray
{
    self.pricingDB = [[PricingDB alloc] init];
    self.surveyDB  = [[SurveyDB alloc] initDB:[self.pricingDB vanline]];
    
    
    if([backupArray count] > 0)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for(BackupRecord *b in backupArray)
        {
            [del.surveyDB saveNewBackup:b];
        }
    }
    
    if([backupArray count] > 0)
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        for(BackupRecord *b in backupArray)
        {
            [del.surveyDB saveNewBackup:b];
}
    }
}

-(BOOL)openPricingDB
{
	if(![pricingDB openDB])
		return FALSE;
	
	return TRUE;
}

-(BOOL)debugCodeValid
{
    
    //code = [a][AA(this could be anywhere in the string)][B][CCC][D][EEE]
    //a - string idx of A
    //A - remainder of yyyyMMdd / 99
    //B - index of character to check in username, < idx 10
    //C - ascii of character at idx B
    //D - index of character to check in username, < idx 10 (different from B)
    //E - ascii of character at idx D
    
    if([Prefs betaPassword] == nil || [Prefs betaPassword].length != 11 || [Prefs username] == nil)
        return NO;
    
    NSMutableString *code = [NSMutableString stringWithString:[Prefs betaPassword]];
    
    BOOL success = YES;
    
    int remainderIdx = [[code substringToIndex:1] intValue];
    NSString *remainderString = [code substringWithRange:NSMakeRange(remainderIdx, 2)];
    
    NSDate *refdate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    int dateNumber = [[formatter stringFromDate:refdate] intValue];
    int dateRemainder = dateNumber % 99;
    
    if(dateRemainder != [remainderString intValue])
        success = NO;
    
    [code replaceCharactersInRange:NSMakeRange(remainderIdx, 2) withString:@""];
    [code replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
    
    int char1Idx = [[code substringWithRange:NSMakeRange(0, 1)] intValue];
    int char1Ascii = [[code substringWithRange:NSMakeRange(1, 3)] intValue];
    
    if(char1Idx >= [Prefs username].length)
        success = NO;
    else if(char1Ascii != [[Prefs username] characterAtIndex:char1Idx])
        success = NO;
    
    [code replaceCharactersInRange:NSMakeRange(0, 4) withString:@""];
    
    int char2Idx = [[code substringWithRange:NSMakeRange(0, 1)] intValue];
    int char2Ascii = [[code substringWithRange:NSMakeRange(1, 3)] intValue];
    
    if(char2Idx >= [Prefs username].length)
        success = NO;
    else if(char2Ascii != [[Prefs username] characterAtIndex:char2Idx])
        success = NO;
    
    return success;
    
}

//-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
//{
//    if([url isFileURL] && [[url path] rangeOfString:@".zip"].location != NSNotFound)
//        return YES;
//    else
//        return NO;
//}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if([url isFileURL])
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSString *path = [url path];
        NSString *lastPath = [path lastPathComponent];
        NSString *fileExtension = [lastPath pathExtension];
        
        if (fileExtension != nil && [[fileExtension lowercaseString] isEqualToString:@"pdf"])
        {
            //load document
            if ([AppFunctionality disableDocumentsLibrary])
                [SurveyAppDelegate showAlert:@"Document Library not supported" withTitle:@"Error"];
            else
            {
                DocLibraryEntry *docEntry = [[DocLibraryEntry alloc] init];
                docEntry.docEntryType = DOC_LIB_TYPE_GLOBAL;
                docEntry.url = @"";
                docEntry.docName = [lastPath stringByDeletingPathExtension];
                
                NSData *pdfData = [NSData dataWithContentsOfFile:path];
                
                [docEntry saveDocument:pdfData];
                [SurveyAppDelegate showAlert:@"This document has been saved to Documents" withTitle:@"Saved"];
            }
        }
        else if (fileExtension != nil && [[fileExtension lowercaseString] isEqualToString:@"csv"])
        {
            if ([AppFunctionality disableCSVImport])
                [SurveyAppDelegate showAlert:@"CSV import not supported" withTitle:@"Error"];
            else
            {
                [self processCSVFile:url];
//                [navController viewWillAppear:YES]; //DONT DO THIS EVER AGAIN
                return YES;
            }
        }
        else
        {
            //restore backup
            RootViewController *rootController = nil;
            for (id view in [del.navController viewControllers]) {
                if([view isKindOfClass:[RootViewController class]])
                    rootController = view;
            }
            [del.navController popToViewController:rootController animated:YES];
            
            
            RestoreDatabasesView *view = [[RestoreDatabasesView alloc] init];
            view.rootController = rootController;
            
            [view restoreDatabases:url];
            
            if(rootController != nil)
            {
                [rootController viewWillAppear:NO];
            }
            
            //
        }
    }
    
    return YES;
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    if(activationError)
    {
        [self showHideVC:splashView withHide:activationController];
        activationError = NO;
    }
    
    Activation *act = [[Activation alloc] init];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [del.operationQueue addOperation:act];
    
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available(iOS 15, *)){
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorNamed:@"navBarColor"];
            [UINavigationBar appearance].standardAppearance = appearance;
            [UINavigationBar appearance].scrollEdgeAppearance = appearance;
        }
    
    [FIRApp configure];

    if([SurveyAppDelegate isRetina4] || [SurveyAppDelegate iPad])
        [window setFrame:[[UIScreen mainScreen] bounds]];
    
    window.backgroundColor = [UIColor blackColor];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        [application setStatusBarStyle:UIStatusBarStyleDefault];
    }
    
    splashView = [[SplashViewController alloc] initWithNibName:@"SplashView" bundle:nil];
	

    [SurveyAppDelegate setupScanbot];

    //check beta password for debug code.  if present, go to debug view instead.
    if([self debugCodeValid])
    {
        self.debugController = [[DebugController alloc] initWithNibName:@"DebugView" bundle:nil];
        [window setRootViewController:self.debugController];
    }
    else
    {
        [window setRootViewController:splashView];
    }
    
    [window makeKeyAndVisible];
    
#if !(TARGET_IPHONE_SIMULATOR)
    [self setCurrentSocketListener:dummySocketReceiver];
#endif
    
    //moved into plist, left here for future reference
//    [self createDynamicShortcutItems];
    
    
    UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
    
    if (shortcutItem != nil)
    {
        [self handleShortcutItem:shortcutItem];
    }
    
    self.linea = [DTDevices sharedDevice];
    [self.linea addDelegate:lineaDel];
    [self.linea connect];
    
//    NSString *filename = @"insert_cn_civ.sql";
//    NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
//    NSError *err = nil;
//    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:fullPath encoding:NSUnicodeStringEncoding error:&err];
//    if (err){
//        NSLog(@"error:%@", err.localizedDescription);
//    }
//    NSArray *lines = [[fileContents componentsSeparatedByString:@"\n"] retain];
//    [lines release];
    
    return YES;
}

//used to show alerts from a separate thread... idx 0 is message, 1 is title
-(void)showAlertFromDelegate:(NSArray*)alertdata
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:[alertdata objectAtIndex:1] message:[alertdata objectAtIndex:0] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}

+(void)setupScanbot {
#ifdef ATLASNET
    // Scanbot key refresh process (Atlas-only)
    
    // Current Scanbot keys, these should be updated any time the license is renewed
    // They are used as a failback if both NSUserDefaults and the web do not produce keys
    NSString *latestEnterpriseKey =
    @"J+054TuEV8fZpa6UMyWppkHy3KgPfr"
    "dBkPgPyElJNTUFTNaCsUf4QAGzby3V"
    "iHGDO2eWfGvUctOUeuCBLimtdmrTdl"
    "3xdmVP7S4FY/pkbF5mPDLeDdssS8Ar"
    "zPgQICKBUVQAQ+xpHH7Z+P0R0nGgOT"
    "ZG2RBxHnm6/LnjJeCqmKMgynKngrnN"
    "Rn2SSt8b/NKLmc4vWNQieNbAcvzIyT"
    "4GJkXZ8qW9wwznZbe/9oMIhEg0JP0Z"
    "wAS95BxwufiAdkBk6PzkbqtMWfQExX"
    "UlLFa9bcbk7zJ46FGtYl3QFybPDZQH"
    "MvO9bdPqaPklqc1ApPfdFroPVqoPwq"
    "xYXJhKv4t72g==\nU2NhbmJvdFNESw"
    "pjb20uaWdjc29mdHdhcmUuZW50ZXJw"
    "cmlzZS5hdGxhc25ldAoxNTc1NDE3NT"
    "k5CjU5MAox\n";
    
    NSString *latestProdKey =
    @"ElWhhpjeOextIxXfVBDyIOAP6ubNxT"
    "85NGnFrM+uOHH7DCbCW2AQT9RN3ql8"
    "/wc3BmIMJiu6QBbG0XS5yPqMRRwORp"
    "lXxL090PsBE2RpeGzRIitKmjcBfMt6"
    "9xfpXl+KPT/sgVU3rXWLcjsV3Wg89g"
    "6tUdw9bGSHf5otJlkwUDyUVUHYdaId"
    "sGnw0ZsHS3RjrA1Jo1dj5w+kVuIAZU"
    "vPUD12w18P6skVmX2ZxMCOb+sH24y0"
    "rDDUBRQHtMSaldlTFLTCx3M1013OOu"
    "nSDAHnsfoyLDOxZulDE4WT93GUHuSa"
    "FP/82H9iZX4UAvMYkVv96oy5xDWzFT"
    "SnwlhzvAlf4Q==\nU2NhbmJvdFNESw"
    "pjb20uYXRsYXN3b3JsZGdyb3VwLmF0"
    "bGFzbmV0CjE1NzU0MTc1OTkKNTkwCj"
    "E=\n";
    
    // Step 1. Attempt to pull existing keys from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *enterpriseKey = [defaults stringForKey:@"ScanbotEnterpriseKey"];
    NSString *prodKey = [defaults stringForKey:@"ScanbotProdKey"];
    
    // Step 2. Attempt to fetch the keys from the web
    NSString *baseURL = @"http://update.mobilemover.com/Atlas/ScanbotKeys/";
    
    // Fetch Enterprise key
    NSString * result = nil;
    NSError *err = nil;
    NSURL * url = [NSURL URLWithString:[baseURL stringByAppendingString:@"iosEnterprise.txt"]];
    if(url) {
        result = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    }
    if(err){
        NSLog(@"An error occurred fetching the Enterprise Scanbot key: %@",err);
    }
    
    if(result != nil) {
        result = [result stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        
        if(enterpriseKey == nil || ![result isEqualToString:enterpriseKey]) {
            enterpriseKey = result;
            // Update NSUserDefaults
            [defaults setObject:enterpriseKey forKey:@"ScanbotEnterpriseKey"];
        }
    }
    
    // Fetch Prod key
    result = nil;
    err = nil;
    url = [NSURL URLWithString:[baseURL stringByAppendingString:@"iosProd.txt"]];
    if(url) {
        result = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    }
    if(err){
        NSLog(@"An error occurred fetching the Prod Scanbot key: %@",err);
    }
    
    if(result != nil) {
        result = [result stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        
        if(prodKey == nil || ![result isEqualToString:prodKey]) {
            prodKey = result;
            // Update NSUserDefaults
            [defaults setObject:prodKey forKey:@"ScanbotProdKey"];
        }
    }
    
    // Step 3. If no keys were produced from steps 1 and 2, use the hardcoded keys as a failback
    if(enterpriseKey == nil) {
        NSLog(@"Enterprise Scanbot key could not be fetched, using failback hardcoded key");
        enterpriseKey = latestEnterpriseKey;
    }
    
    if(prodKey == nil) {
        NSLog(@"Prod Scanbot key could not be fetched, using failback hardcoded key");
        prodKey = latestProdKey;
    }
#endif
    
#if defined(ATLASNET)
#if defined(ATLAS_ENTERPRISE)
    @try {
        [ScanbotSDK setLicense:enterpriseKey];
    } @catch (NSException* e) {
        //Eat this for now.  Not sure how we should handle the case where this crashes.
    }
#else
    @try {
        [ScanbotSDK setLicense:prodKey];
    } @catch (NSException* e) {
        //Eat this for now.  Not sure how we should handle the case where this crashes.
    }
#endif
#endif
}

-(void)handleShortcutItem:(UIApplicationShortcutItem*)shortcutItem
{
    NSLog(@"%@", shortcutItem.type);
    
    BOOL canLaunchShortcut = true;
    
    //Check to see if rootView is already loaded, if its already visible, viewDidAppear will not fire
    RootViewController *rootViewController = nil;
    
    for (id view in [self.navController viewControllers]) {
        if([view isKindOfClass:[PVOItemDetailController class]])
        {
            NSLog(@"Found %@, Abort shortcut", NSStringFromClass([view class]));
            canLaunchShortcut = false;
            break;
        }
        else if([view isKindOfClass:[RootViewController class]])
        {
            rootViewController = view;
        }
    }
    
    if (canLaunchShortcut)
    {
        id view = [[self.navController viewControllers] lastObject];
        if([view respondsToSelector:@selector(viewHasCriticalDataToSave)] && [view viewHasCriticalDataToSave])
        {
            NSLog(@"Found %@, Abort shortcut", NSStringFromClass([view class]));
            canLaunchShortcut = false;
        }
    }
    
    if(!canLaunchShortcut)
    {
        [SurveyAppDelegate showAlert:@"In order to prevent data loss, the new customer shortcut is disabled." withTitle:@"Error"];
        return;
    }
    
    
    if (rootViewController != nil)
    {
        if([shortcutItem.type isEqualToString:@"CreateNewShortcut"]){
            
            //not sure why i get these warnings, probably a better way to handle this?
            if ([rootViewController respondsToSelector:@selector(createNewCustomer)]) {
                NSLog(@"Found RootView and Create New Customer Method");
                [self.navController popToViewController:rootViewController animated:NO];
                if ([rootViewController viewHasAppeared])
                    [rootViewController createNewCustomer];
                else
                    self.launchedShortcutItem = shortcutItem;
            }
            
        } else if ([shortcutItem.type isEqualToString:@"DownloadShortcut"]) {
            
            if ([rootViewController respondsToSelector:@selector(handleDownloadCustomer)])
            {
                NSLog(@"Found RootView and Download Customer Method");
                [self.navController popToViewController:rootViewController animated:YES];
                
                if ([rootViewController viewHasAppeared])
                    [rootViewController handleDownloadCustomer];
                else
                    self.launchedShortcutItem = shortcutItem;
            }
            
        } else {
            //some other shortcut
            NSLog(@"Other ShortCut");
            self.launchedShortcutItem   = shortcutItem;
        }
    }
    
    return;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self handleShortcutItem:shortcutItem];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)notification
{
    int orientation = [[notification.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey] intValue];
    
    int w = [[UIScreen mainScreen] bounds].size.width;
    int h = [[UIScreen mainScreen] bounds].size.height;
    switch (orientation) {
        case 4:
            self.window.frame =  CGRectMake(0,20,w,h);
            break;
        case 3:
            self.window.frame =  CGRectMake(-20,0,w-20,h+20);
            break;
        case 2:
            self.window.frame =  CGRectMake(0,-20,w,h);
            break;
        case 1:
            self.window.frame =  CGRectMake(20,0,w-20,h+20);
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
//	[kscan DisconnectDevice];
}

- (void)applicationWillTerminate:(UIApplication *)application{
    
//	[kscan DisconnectDevice];
    [self.linea disconnect];
}

-(void)pushSingleFieldController:(NSString*)value 
					 clearOnEdit:(BOOL)clear 
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder 
					  withCaller:(NSObject*)caller 
					 andCallback:(SEL)callback 
			   dismissController:(BOOL)dismiss
{
	[self pushSingleFieldController:value 
						clearOnEdit:clear 
					   withKeyboard:kb 
					withPlaceHolder:placeholder 
						 withCaller:caller 
						andCallback:callback 
				  dismissController:dismiss 
				   andNavController:navController];
}

-(void)pushSingleFieldController:(NSString*)value
					 clearOnEdit:(BOOL)clear
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder
					  withCaller:(NSObject*)caller
					 andCallback:(SEL)callback
			   dismissController:(BOOL)dismiss
				andNavController:(UINavigationController*)navctl
{
    [self pushSingleFieldController:value
                        clearOnEdit:clear
                       withKeyboard:kb
                    withPlaceHolder:placeholder
                         withCaller:caller
                        andCallback:callback
                  dismissController:dismiss
                requireValueForSave:NO
                   andNavController:navctl];
}

-(void)pushSingleFieldController:(NSString*)value
					 clearOnEdit:(BOOL)clear
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder
					  withCaller:(NSObject*)caller
					 andCallback:(SEL)callback
			   dismissController:(BOOL)dismiss
             requireValueForSave:(BOOL)requireValue
				andNavController:(UINavigationController*)navctl
{
    [self pushSingleFieldController:value
                        clearOnEdit:clear
                       withKeyboard:kb
                    withPlaceHolder:placeholder
                         withCaller:caller
                        andCallback:callback
                  dismissController:dismiss
                requireValueForSave:requireValue
              andAutoCapitalization:UITextAutocapitalizationTypeNone
                   andNavController:navctl];
}

-(void)pushSingleFieldController:(NSString*)value 
					 clearOnEdit:(BOOL)clear 
					withKeyboard:(UIKeyboardType)kb
				 withPlaceHolder:(NSString*)placeholder 
					  withCaller:(NSObject*)caller 
					 andCallback:(SEL)callback 
			   dismissController:(BOOL)dismiss
             requireValueForSave:(BOOL)requireValue
           andAutoCapitalization:(UITextAutocapitalizationType)autocapitalizationType
				andNavController:(UINavigationController*)navctl
{
	if(singleFieldController == nil)
	{
		singleFieldController = [[SingleFieldController alloc] initWithStyle:UITableViewStyleGrouped];
	}
	
	singleFieldController.caller = caller;
	singleFieldController.callback = callback;
	singleFieldController.destString = value;
	singleFieldController.placeholder = placeholder;
	singleFieldController.clearOnEdit = clear;
	singleFieldController.keyboard = kb;
	singleFieldController.dismiss = dismiss;
    singleFieldController.requireValue = requireValue;
    singleFieldController.autocapitalizationType = autocapitalizationType;
	
	[navctl pushViewController:singleFieldController animated:YES];
	
}


-(void)pushNoteViewController:(NSString*)value
				 withKeyboard:(UIKeyboardType)kb
				 withNavTitle:(NSString*)navTitle
			  withDescription:(NSString*)description 
				   withCaller:(NSObject*)caller 
				  andCallback:(SEL)callback 
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
{
	
	[self pushNoteViewController:value 
					withKeyboard:kb 
					withNavTitle:navTitle 
				 withDescription:description 
					  withCaller:caller
					 andCallback:callback 
			   dismissController:dismiss 
						noteType:noteType 
				andNavController:navController
                   maxNoteLength:-1];
	
}

-(void)pushNoteViewController:(NSString*)value
				 withKeyboard:(UIKeyboardType)kb
				 withNavTitle:(NSString*)navTitle
			  withDescription:(NSString*)description
				   withCaller:(NSObject*)caller
				  andCallback:(SEL)callback
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
                maxNoteLength:(int)maxNoteLength
{
    [self pushNoteViewController:value
					withKeyboard:kb
					withNavTitle:navTitle
				 withDescription:description
					  withCaller:caller
					 andCallback:callback
			   dismissController:dismiss
						noteType:noteType
				andNavController:navController
                   maxNoteLength:maxNoteLength];
}

-(void)pushNoteViewController:(NSString*)value
                 withKeyboard:(UIKeyboardType)kb
                 withNavTitle:(NSString*)navTitle
              withDescription:(NSString*)description
                   withCaller:(NSObject*)caller
                  andCallback:(SEL)callback
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
			 andNavController:(UINavigationController*)navctl
{
    [self pushNoteViewController:value
					withKeyboard:kb
					withNavTitle:navTitle
				 withDescription:description
					  withCaller:caller
					 andCallback:callback
			   dismissController:dismiss
						noteType:noteType
				andNavController:navctl
                   maxNoteLength:-1];
}

-(void)pushNoteViewController:(NSString*)value
					withKeyboard:(UIKeyboardType)kb
					withNavTitle:(NSString*)navTitle
				 withDescription:(NSString*)description 
					  withCaller:(NSObject*)caller 
					 andCallback:(SEL)callback 
			dismissController:(BOOL)dismiss
					 noteType:(int)noteType
			 andNavController:(UINavigationController*)navctl
                maxNoteLength:(int)maxNoteLength
{
	
	if(noteViewController == nil)
	{
		noteViewController = [[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped];
	}
	
	noteViewController.caller = caller;
	noteViewController.callback = callback;
	noteViewController.destString = value;
	noteViewController.description = description;
	noteViewController.navTitle = navTitle;
	noteViewController.keyboard = kb;
	noteViewController.dismiss = dismiss;
	noteViewController.noteType = noteType;
    noteViewController.maxLength = maxNoteLength;
	
	[navctl pushViewController:noteViewController animated:YES];
	
}


-(void)pushSingleDateViewController:(NSDate*)value
				 withNavTitle:(NSString*)navTitle
				   withCaller:(NSObject*)caller 
				  andCallback:(SEL)callback 
{
	[self pushSingleDateViewController:value 
						  withNavTitle:navTitle 
							withCaller:caller 
						   andCallback:callback 
					  andNavController:navController];
}

-(void)pushSingleDateViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl
{
    [self pushSingleDateViewController:value
						  withNavTitle:navTitle
							withCaller:caller
						   andCallback:callback
					  andNavController:navctl
                      usingOldCallback:FALSE];
}

-(void)pushSingleDateViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller 
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl
                   usingOldCallback:(BOOL)oldCallback
{
	if(singleDateController == nil)
	{
		self.singleDateController = [[EditDateController alloc] initWithNibName:@"EditDateView" bundle:nil];
	}
	
	singleDateController.fromDate = value;
	singleDateController.title = navTitle;
	singleDateController.caller = caller;
	singleDateController.callback = callback;
	singleDateController.editingMode = EDIT_DATE_SINGLE;
    singleDateController.useOldMethodCallback = oldCallback;
	
	[navctl pushViewController:singleDateController animated:YES];
	
}

-(void)pushSingleDateTimeViewController:(NSDate*)value
                           withNavTitle:(NSString*)navTitle
                             withCaller:(NSObject*)caller
                            andCallback:(SEL)callback
                       andNavController:(UINavigationController*)navctl
                       usingOldCallback:(BOOL)oldCallback
{
	if(singleDateController == nil)
	{
		self.singleDateController = [[EditDateController alloc] initWithNibName:@"EditDateView" bundle:nil];
	}
	
	singleDateController.fromDate = value;
	singleDateController.title = navTitle;
	singleDateController.caller = caller;
	singleDateController.callback = callback;
	singleDateController.editingMode = EDIT_DATE_TIME_SINGLE;
    singleDateController.useOldMethodCallback = oldCallback;
	
	[navctl pushViewController:singleDateController animated:YES];
	
}

-(void)pushSingleTimeViewController:(NSDate*)value
					   withNavTitle:(NSString*)navTitle
						 withCaller:(NSObject*)caller
						andCallback:(SEL)callback
				   andNavController:(UINavigationController*)navctl
{
	if(singleDateController == nil)
	{
		self.singleDateController = [[EditDateController alloc] initWithNibName:@"EditDateView" bundle:nil];
	}
	
	singleDateController.fromDate = value;
	singleDateController.title = navTitle;
	singleDateController.caller = caller;
	singleDateController.callback = callback;
	singleDateController.editingMode = EDIT_TIME_SINGLE;
	
	[navctl pushViewController:singleDateController animated:YES];
	
}

-(void)pushPickerViewController:(NSString*)title
					withObjects:(NSDictionary*)objects
		   withCurrentSelection:(NSNumber*)selection
					 withCaller:(NSObject*)caller 
					andCallback:(SEL)callback 
{
	[self pushPickerViewController:title 
					   withObjects:objects 
			  withCurrentSelection:selection 
						withCaller:caller 
					   andCallback:callback 
				  andNavController:navController];
}

-(void)pushPickerViewController:(NSString*)title
					withObjects:(NSDictionary*)objects
		   withCurrentSelection:(NSNumber*)selection
					 withCaller:(NSObject*)caller 
					andCallback:(SEL)callback
			   andNavController:(UINavigationController*)navctl
{
	
	if(pickerView == nil)
	{
		self.pickerView = [[PickerViewController alloc] initWithNibName:@"PickerView" bundle:nil];
	}
	
	pickerView.options = objects;
	pickerView.title = title;
	pickerView.caller = caller;
	pickerView.callback = callback;
	pickerView.currentSelection = selection;
	
	[navctl pushViewController:pickerView animated:YES];
	
}

//either takes in a nsnumber and nsdictionary, or a nsstring and nsarray
-(void)pushTablePickerController:(NSString*)title
					 withObjects:(id)objects
			withCurrentSelection:(id)selection
					  withCaller:(id)caller 
					 andCallback:(SEL)callback
                 dismissOnSelect:(BOOL)dismiss
				andNavController:(UINavigationController*)navctl
{
	
	if(tablePicker == nil)
	{
		self.tablePicker = [[TablePickerController alloc] initWithStyle:UITableViewStylePlain];
	}
	
	tablePicker.objects = objects;
	tablePicker.title = title;
	tablePicker.caller = caller;
	tablePicker.callback = callback;
	tablePicker.currentValue = selection;
    tablePicker.showingModal = FALSE;
    tablePicker.selectOnCheck = dismiss;
	
	[navctl pushViewController:tablePicker animated:YES];
	
}

-(void)popTablePickerController:(NSString*)title
                    withObjects:(id)objects
           withCurrentSelection:(id)selection
                     withCaller:(id)caller 
                    andCallback:(SEL)callback
                dismissOnSelect:(BOOL)dismiss
              andViewController:(UIViewController*)view
           skipInventoryProcess:(BOOL)skipInv
{
	if(tablePicker == nil)
	{
		self.tablePicker = [[TablePickerController alloc] initWithStyle:UITableViewStylePlain];
	}
	
	tablePicker.objects = objects;
	tablePicker.title = title;
	tablePicker.caller = caller;
	tablePicker.callback = callback;
	tablePicker.currentValue = selection;
    tablePicker.showingModal = TRUE;
    tablePicker.selectOnCheck = dismiss;
    tablePicker.skipInventoryProcess = skipInv;
    
    PortraitNavController *newnav = [[PortraitNavController alloc] initWithRootViewController:tablePicker];
    //UINavigationController *newnav = [[UINavigationController alloc] initWithRootViewController:tablePicker];
    
    if(skipInv){
        [self.navController pushViewController:tablePicker animated:YES];
    } else {
    [view presentViewController:newnav animated:YES completion:nil];
}
}

//either takes in a nsnumber and nsdictionary, or a nsstring and nsarray
-(void)popTablePickerController:(NSString*)title
                    withObjects:(id)objects
           withCurrentSelection:(id)selection
                     withCaller:(id)caller 
                    andCallback:(SEL)callback
                dismissOnSelect:(BOOL)dismiss
              andViewController:(UIViewController*)view
{
    [self popTablePickerController:title
                       withObjects:objects
              withCurrentSelection:selection
                        withCaller:caller
                       andCallback:callback
                   dismissOnSelect:dismiss
                 andViewController:view
              skipInventoryProcess:NO];
}


-(void)hideSplashShowActivationError:(NSString*)results
{
	if(activationController == nil)
	{
        activationController = [[ActivationErrorController alloc] initWithNibName:@"ActivationErrorView" bundle:nil];
	}
	
	activationController.message = results;
	
	activationError = YES;
    
    PortraitNavController *newnav = [[PortraitNavController alloc] initWithRootViewController:activationController];
	[self showHideVC:newnav withHide:splashView];
}

-(void)hideDownloadShowCustomers
{
    [surveyDB upgradeDBForVanline:[pricingDB vanline]];
	
    [self showHideVC:navController withHide:downloadDBs];
	
}

-(void)hideSplashShowCustomers
{
    [surveyDB upgradeDBForVanline:[pricingDB vanline]];
    [self showHideVC:navController withHide:splashView];
	
}

-(void)hideSplashShowDownload
{
	if(downloadDBs != nil)
    {
        downloadDBs = nil;
    }
        
    downloadDBs = [[DownloadController alloc] initWithNibName:@"DownloadView" bundle:nil];
	
	PortraitNavController *newnav = [[PortraitNavController alloc] initWithRootViewController:downloadDBs];
	[self showHideVC:newnav withHide:splashView];
}

-(void)showHideVC:(UIViewController*)show withHide:(UIViewController*)hide
{    
	[UIView beginAnimations:@"View Flip" context:nil];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	
	
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlUp forView:window cache:YES];
    
    [window setRootViewController:show];
    
//	[show viewWillAppear:YES];
//	[hide viewWillDisappear:YES];
//	
//	[hide.view removeFromSuperview];
//	[window	addSubview:show.view];
//	
//	[hide viewDidDisappear:YES];
//	[show viewDidAppear:YES];
	
	[UIView commitAnimations];
}

- (void)dealloc {
    self.debugController = nil;
}




-(void)showPVODamageController:(PortraitNavController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID
{
    [self showPVODamageController:nav forItem:item showNextItemButton:showNextItem pvoLoadID:pvoLoadID withDelegate:nil];
}

-(void)showPVODamageController:(PortraitNavController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID
                  withDelegate:(id<PVODamageControllerDelegate>)del
{
    
    [self showPVODamageController:nav forItem:item showNextItemButton:showNextItem pvoLoadID:pvoLoadID withWireframeOption: NO withDelegate:nil];
}

-(void)showPVODamageController:(PortraitNavController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                     pvoLoadID:(int)pvoLoadID
           withWireframeOption:(BOOL)withWireframe
                  withDelegate:(id<PVODamageControllerDelegate>)del
{
    if(pvoDamageHolder == nil)
        pvoDamageHolder = [[PVODamageViewHolder alloc] init];
    
    pvoDamageHolder.nav = nav;
    pvoDamageHolder.item = item;
    pvoDamageHolder.delegate = del;
    pvoDamageHolder.withWireframe = withWireframe;
    [pvoDamageHolder show:showNextItem withLoadID:pvoLoadID];
}

-(void)showPVODamageController:(PortraitNavController*)nav
                       forItem:(PVOItemDetail*)item
            showNextItemButton:(BOOL)showNextItem
                   pvoUnloadID:(int)pvoUnloadID
{
    if(pvoDamageHolder == nil)
        pvoDamageHolder = [[PVODamageViewHolder alloc] init];
    
    pvoDamageHolder.nav = nav;
    pvoDamageHolder.item = item;
    [pvoDamageHolder show:showNextItem withUnloadID:pvoUnloadID];
}


-(void)onTimer: (NSTimer*)theTimer
{
    if(theTimer==socketTimer)
    {
        [socketScanAPI doScanApiReceive];
    }
}

- (void)processCSVFile:(NSURL *)url
{
    NSString *filename = [url path];
    
    // read the file into an array
    NSArray *csvArray = [NSArray arrayWithContentsOfCSVURL:url];
    if ([csvArray count] > 0)
    {
        NSArray *headings = csvArray[0];
        if ([headings count] == 40 && [headings[0] isEqualToString:@"Customer Last Name"])
        {
            NSString *message = [self processCSVItemList:csvArray];
            if ([message length] > 0)
                [SurveyAppDelegate showAlert:message withTitle:@"Customer Import"];
            else
                [SurveyAppDelegate showAlert:@"Error During Import" withTitle:@"Customer Import"];
        }
    }
    
    // delete the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filename error:&error];
    if (!success)
    {
        NSLog(@"File delete error: %@", error.localizedDescription);
    }
}

- (NSString*)processCSVItemList:(NSArray *)csvArray
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableString *message = [[NSMutableString alloc] init];
    for (int i = 1; i < [csvArray count]; i++)
    {
        NSArray *lineArray = csvArray[i];
        if ([lineArray count] == 40)
        {
            int idx = 0;
            //Customer info
            NSString *customerLastName = lineArray[idx];
            NSString *customerFirstName = lineArray[++idx];
            NSString *customerCompanyName = lineArray[++idx];
            NSString *customerEmail = lineArray[++idx];
            NSString *customerWeight = lineArray[++idx];
            NSString *orderNumber = lineArray[++idx];
            NSString *gblNumber = lineArray[++idx];
            NSString *pricingMode = lineArray[++idx];
            NSString *primaryPhone = lineArray[++idx];
            //Origin Location
            NSString *originAddress1 = lineArray[++idx];
            NSString *originAddress2 = lineArray[++idx];
            NSString *originCity = lineArray[++idx];
            NSString *originState = lineArray[++idx];
            NSString *originZip = lineArray[++idx];
            //Origin Phones
            NSString *originHomePhone = lineArray[++idx];
            NSString *originMobilePhone = lineArray[++idx];
            NSString *originWorkPhone = lineArray[++idx];
            NSString *originOtherPhone = lineArray[++idx];
            //Dest Location
            NSString *destinationAddress1 = lineArray[++idx];
            NSString *destinationAddress2 = lineArray[++idx];
            NSString *destinationCity = lineArray[++idx];
            NSString *destinationState = lineArray[++idx];
            NSString *destinationZip = lineArray[++idx];
            //Dest Phones
            NSString *destinationHomePhone = lineArray[++idx];
            NSString *destinationMobilePhone = lineArray[++idx];
            NSString *destinationWorkPhone = lineArray[++idx];
            NSString *destinationOtherPhone = lineArray[++idx];
            //Agents
            NSString *bookingAgentCode = lineArray[++idx];
            NSString *originAgentCode = lineArray[++idx];
            NSString *destinationAgentCode = lineArray[++idx];
            //Dates
            NSString *packFromDate = lineArray[++idx];
            NSString *packToDate = lineArray[++idx];
            NSString *packPreferredDate = lineArray[++idx];
            NSString *loadFromDate = lineArray[++idx];
            NSString *loadToDate = lineArray[++idx];
            NSString *loadPreferredDate = lineArray[++idx];
            NSString *deliverFromDate = lineArray[++idx];
            NSString *deliverToDate = lineArray[++idx];
            NSString *deliverPreferredDate = lineArray[++idx];
            //CustomerNote
            NSString *customerNote = lineArray[++idx];
            
            
            //Customer Basic info
            SurveyCustomer *newCust = [[SurveyCustomer alloc] init];
            newCust.lastName = customerLastName;
            newCust.firstName = customerFirstName;
            newCust.account = customerCompanyName;
            newCust.email = customerEmail;
            newCust.estimatedWeight = [customerWeight intValue];
            newCust.pricingMode = ([pricingMode isEqualToString:@"Interstate"] || [pricingMode isEqualToString:@"0"] ? 0 : 1);
            
            SurveyCustomerSync *sync = [[SurveyCustomerSync alloc] init];
            sync.createdOnDevice = false;
            sync.generalSyncID = orderNumber;
            
            ShipmentInfo *info = [[ShipmentInfo alloc] init];
            info.orderNumber = orderNumber;
            info.gblNumber = gblNumber;
            
            newCust.custID = [del.surveyDB insertNewCustomer:newCust withSync:sync andShipInfo:info];
 
            //Agents
            //Default agents are inserted when customer is created
            NSMutableDictionary *agentCodes = [[NSMutableDictionary alloc] init];
            if ([bookingAgentCode length] > 0)
                [agentCodes setObject:bookingAgentCode forKey:[NSNumber numberWithInt:AGENT_BOOKING]];
            
            if ([originAgentCode length] > 0)
                [agentCodes setObject:originAgentCode forKey:[NSNumber numberWithInt:AGENT_ORIGIN]];
            
            if ([destinationAgentCode length] > 0)
                [agentCodes setObject:destinationAgentCode forKey:[NSNumber numberWithInt:AGENT_DESTINATION]];
            
            SurveyAgent *agent;
            for (id key in agentCodes)
            {
                NSString *value = [agentCodes objectForKey:key];
                agent = [del.pricingDB getAgent:[value uppercaseString]];
                if ([agent.code length] > 0)
                {
                    agent.agencyID = [key intValue];
                    agent.itemID = newCust.custID;
                    [del.surveyDB saveAgent:agent];
                    
                }
            }
            
            //Dates
            SurveyDates *dates = [[SurveyDates alloc] init];  //Default dates are inserted when customer is created
            dates.custID = newCust.custID;
            [dates setToToday];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterLongStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];
            [formatter setLenient:YES];
            
            
            if ([packFromDate length] > 0)
                dates.packFrom = [formatter dateFromString:packFromDate];
            
            if ([packToDate length] > 0)
                dates.packTo = [formatter dateFromString:packToDate];
            
            if ([packPreferredDate length] > 0)
                dates.packPrefer = [formatter dateFromString:packPreferredDate];
            
            if ([loadFromDate length] > 0)
                dates.loadFrom = [formatter dateFromString:loadFromDate];
            
            if ([loadToDate length] > 0)
                dates.loadTo = [formatter dateFromString:loadToDate];
            
            if ([loadPreferredDate length] > 0)
                dates.loadPrefer = [formatter dateFromString:loadPreferredDate];
            
            if ([deliverFromDate length] > 0)
                dates.deliverFrom = [formatter dateFromString:deliverFromDate];
            
            if ([deliverToDate length] > 0)
                dates.deliverTo = [formatter dateFromString:deliverToDate];
            
            if ([deliverPreferredDate length] > 0)
                dates.deliverPrefer = [formatter dateFromString:deliverPreferredDate];
            
            [del.surveyDB updateDates:dates];
            
            //Origin Location
            //Orig location is inserted when customer is created
            if ([originZip length] > 0)
            {
                SurveyLocation *originLocation = [del.surveyDB getCustomerLocation:newCust.custID withType:ORIGIN_LOCATION_ID];
                originLocation.locationType = ORIGIN_LOCATION_ID;
                originLocation.custID = newCust.custID;
                originLocation.address1 = originAddress1;
                originLocation.address2 = originAddress2;
                originLocation.city = originCity;
                originLocation.state = originState;
                originLocation.zip = originZip;
                originLocation.isOrigin = YES;
                
                [del.surveyDB updateLocation:originLocation];
                
                //Origin Phones
                NSMutableArray *originPhones = [[NSMutableArray alloc] init];
                SurveyPhone *phone;
                if ([primaryPhone length] > 0)
                {//primary phone, no location
                    phone = [[SurveyPhone alloc] init];
                    phone.number = primaryPhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.phoneTypeID = 2;
                    phone.locationTypeId = -1;
                    [originPhones addObject:phone];
                }
                
                if ([originHomePhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = originHomePhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Home";
                    phone.type.phoneTypeID = 2;
                    phone.locationTypeId = ORIGIN_LOCATION_ID;
                    [originPhones addObject:phone];
                }
                
                if ([originMobilePhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = originMobilePhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Mobile";
                    phone.type.phoneTypeID = 1;
                    phone.locationTypeId = ORIGIN_LOCATION_ID;
                    [originPhones addObject:phone];
                }
                
                if ([originWorkPhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = originWorkPhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Work";
                    phone.type.phoneTypeID = 3;
                    phone.locationTypeId = ORIGIN_LOCATION_ID;
                    [originPhones addObject:phone];
                }
                
                if ([originOtherPhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = originOtherPhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Other";
                    phone.type.phoneTypeID = 4;
                    phone.locationTypeId = ORIGIN_LOCATION_ID;
                    [originPhones addObject:phone];
                }
                
                for (SurveyPhone *p in originPhones)
                {
                    p.custID = newCust.custID;
                    [del.surveyDB insertPhone:p];
                }
            }
            
            //Destination Location
            //Dest location is inserted when customer is created
            if ([destinationZip length] > 0)
            {
                SurveyLocation *destLocation = [del.surveyDB getCustomerLocation:newCust.custID withType:DESTINATION_LOCATION_ID];
                destLocation.locationType = DESTINATION_LOCATION_ID;
                destLocation.custID = newCust.custID;
                destLocation.address1 = destinationAddress1;
                destLocation.address2 = destinationAddress2;
                destLocation.city = destinationCity;
                destLocation.state = destinationState;
                destLocation.zip = destinationZip;
                destLocation.isOrigin = NO;
                
                [del.surveyDB updateLocation:destLocation];
                
                //Phones
                NSMutableArray *destPhones = [[NSMutableArray alloc] init];
                SurveyPhone *phone;
                if ([destinationHomePhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = destinationHomePhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Home";
                    phone.type.phoneTypeID = 2;
                    phone.locationTypeId = DESTINATION_LOCATION_ID;
                    [destPhones addObject:phone];
                }
                
                if ([destinationMobilePhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = destinationMobilePhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Mobile";
                    phone.type.phoneTypeID = 1;
                    phone.locationTypeId = DESTINATION_LOCATION_ID;
                    [destPhones addObject:phone];
                }
                
                if ([destinationWorkPhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = destinationWorkPhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Work";
                    phone.type.phoneTypeID = 3;
                    phone.locationTypeId = DESTINATION_LOCATION_ID;
                    [destPhones addObject:phone];
                }
                
                if ([destinationOtherPhone length] > 0)
                {
                    phone = [[SurveyPhone alloc] init];
                    phone.number = destinationOtherPhone;
                    phone.type = [[PhoneType alloc] init];
                    phone.type.name = @"Other";
                    phone.type.phoneTypeID = 4;
                    phone.locationTypeId = DESTINATION_LOCATION_ID;
                    [destPhones addObject:phone];
                }
                
                for (SurveyPhone *p in destPhones)
                {
                    p.custID = newCust.custID;
                    [del.surveyDB insertPhone:p];
                }
                
                //Customer note
                [del.surveyDB updateCustomerNote:newCust.custID withNote:customerNote];
            }
            [message appendString:[NSString stringWithFormat:@"%@ imported%@", customerLastName, (i + 1 < [csvArray count] ? @",\r\n" : @"")]];
        }
    }
    
    return message;
    
}

-(void)setCurrentSocketListener:(id<ScanApiHelperDelegate>) newSocketListener
{
    
#if !(TARGET_IPHONE_SIMULATOR)
    
    if(currentSocketListener != newSocketListener)
    {
        if(newSocketListener != nil)
        {
            if(socketScanAPI==nil)
                socketScanAPI = [[ScanApiHelper alloc] init];
                
            currentSocketListener = newSocketListener;
            
            [socketScanAPI setDelegate:currentSocketListener];
            [socketScanAPI open];
            self.socketTimer = [NSTimer scheduledTimerWithTimeInterval:.2 
                                                                target:self 
                                                              selector:@selector(onTimer:) 
                                                              userInfo:nil 
                                                               repeats:YES];
            
        }
        else
        {
            [socketScanAPI setDelegate:dummySocketReceiver];
            currentSocketListener = dummySocketReceiver;
        }
        
    }
    
#endif
    
}

-(void)setTitleAndSubtitleForNavigationItem:(UINavigationItem*)item
                          forTitle:(NSString*)title
                      withSubtitle:(NSString*)subtitle
{
    if (item.titleView == nil)
    {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -2, 0, 0)];
        titleLabel.font = [UIFont boldSystemFontOfSize:20];
        titleLabel.text = title;
        [titleLabel sizeToFit];
    
        UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 0, 0)];
        subTitleLabel.font = [UIFont systemFontOfSize:12];
        subTitleLabel.text = subtitle;
        [subTitleLabel sizeToFit];
    
        UIView *twoLineTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(subTitleLabel.frame.size.width, titleLabel.frame.size.width), 30)];
        [twoLineTitleView addSubview:titleLabel];
        [twoLineTitleView addSubview:subTitleLabel];
    
        float widthDiff = subTitleLabel.frame.size.width - titleLabel.frame.size.width;
    
        if (widthDiff > 0) {
            CGRect frame = titleLabel.frame;
            frame.origin.x = widthDiff / 2;
            titleLabel.frame = CGRectIntegral(frame);
        } else {
            CGRect frame = subTitleLabel.frame;
            frame.origin.x = fabsf(widthDiff) / 2;
            subTitleLabel.frame = CGRectIntegral(frame);
        }
    
        item.titleView = twoLineTitleView;
        
    } else {
        UIView* curNavView = (UIView*)item.titleView;
        
        UILabel* titleLabel = (UILabel*)[curNavView.subviews objectAtIndex:0];
        titleLabel.font = [UIFont boldSystemFontOfSize:20];
        titleLabel.text = title;
        [titleLabel sizeToFit];
        
        UILabel* subTitleLabel = (UILabel*)[curNavView.subviews objectAtIndex:1];
        subTitleLabel.font = [UIFont systemFontOfSize:12];
        subTitleLabel.text = subtitle;
        [subTitleLabel sizeToFit];
    }
}

-(void)setTitleForDriverOrPackerNavigationItem:(UINavigationItem*)item
                        forTitle:(NSString*)title
{
    if ([AppFunctionality disablePackersInventory])
    {
        item.title = title;
    }
    else
    {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        DriverData *driverData = [del.surveyDB getDriverData];
        
        [self setTitleAndSubtitleForNavigationItem:item forTitle:title
                                      withSubtitle:(driverData.driverType != PVO_DRIVER_TYPE_PACKER) ? @"Driver" : @"Packer"];
    }
    
}

+ (void)minimizeTableHeaderAndFooterViews:(UITableView *)theTable
{
    [self setTableHeaderAndFooterViewsHeight:theTable withHeight:4.0f];
}

+ (void)eliminateTableHeaderAndFooterViews:(UITableView *)theTable
{
    [self setTableHeaderAndFooterViewsHeight:theTable withHeight:0.1f];
}

+ (void)setTableHeaderAndFooterViewsHeight:(UITableView *)theTable withHeight:(CGFloat)h
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        theTable.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, theTable.bounds.size.width, h)];
        theTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, theTable.bounds.size.width, h)];
    }
}

+ (void)setDefaultBackButton:(UIViewController*)controller
{
    //NOTE: per Tony this is not a safe option for fixing the back button text, leaving this code/note here for future reference since we use the same code elsewhere in the app...
    //fix back button if not already present
    /*controller.navigationItem.leftBarButtonItem = nil;
    if (controller.navigationItem.backBarButtonItem == nil)
        controller.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];*/
    
    controller.title = @"Back";
}

// This method will return true is the device has a passcode, otherwise false (SOW 11042016.04)
+(BOOL) deviceHasPasscode {
    NSData* secret = [@"Device has passcode set?" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService: @"LocalDeviceServices",  (__bridge id)kSecAttrAccount: @"NoAccount", (__bridge id)kSecValueData: secret, (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly };
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if (status == errSecSuccess) { // item added okay, passcode has been set
        SecItemDelete((__bridge CFDictionaryRef)attributes);
        
        return true;
    }
    
    return false;
}

@end
