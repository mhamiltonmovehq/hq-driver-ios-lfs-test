//
//  WebSyncRequest.h
//  Survey
//
//  Created by Tony Brame on 7/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RPT_WEB_SERVICE_PATH @"/IGCReportingService.asmx"
#define RPT_WEB_SERVICE_XMLNS @"http://igcsoftware.com/PrinterInTheSky/"
#define RPT_USER_AGENT @"WebReports iPhone"

#define ATLAS_WEB_SERVICE_PATH @"/AtlasSurveySync/AtlasSyncService.asmx"
#define ATLAS_WEB_SERVICE_XMLNS @"AtlasSurveySync"
#define ATLAS_USER_AGENT @"AtlasSync iPhone"
#define ATLAS_CANADA_WEB_SERVICE_PATH @"/AtlasCNSync/IGCWebSyncService.asmx"
#define ATLAS_CANADA_WEB_SERVICE_PATH_BETA @"/AtlasCNSyncBeta/IGCWebSyncService.asmx"
//#define ATLAS_CANADA_WEB_SERVICE_PATH_DEV @"/IGCWebSync/IGCWebSyncService.asmx"
//#define ATLAS_CANADA_WEB_SERVICE_PATH_DEV @"/AtlasSyncBeta/IGCWebSyncService.asmx"  Was last updated in 2015.  Banished.
#define ATLAS_CANADA_WEB_SERVICE_XMLNS @"IGCWebSync"

#define FILE_WEB_SERVICE_PATH @"/FileUtility/FileService.asmx"
#define FILE_WEB_SERVICE_XMLNS @"FileUtility"
#define FILE_USER_AGENT @"IGCFile iPhone"

#define ITEM_LISTS_WCF_ADDRESS @"216.185.53.11"
#define ITEM_LISTS_WCF_PATH @"/ItemListsWCF/ItemListService.svc"
#define ITEM_LISTS_WCF_SOAP_ACTION_PREFIX @"http://tempuri.org/IItemListService/"
#define ITEM_LISTS_WCF_XMLNS @"http://tempuri.org/"
#define ITEM_LISTS_WCF_USER_AGENT @"ItemLists iPhone"

#define ARPIN_PVO_WCF_ADDRESS @"igc.arpin.com"
//#define PVO_WCF_ADDRESS @"aisync1.mobilemover.com"
#define PVO_WCF_ADDRESS @"homesafe-win.movehq.com"


#define PVO_WCF_PATH @"/AISyncService/SyncService.svc"
#define PVO_WCF_PATH @"/SyncService.svc"

#define PVO_WCF_SOAP_ACTION_PREFIX @"https://AICloudService.ServiceModel/ISyncService/"
#define PVO_WCF_XMLNS @"https://AICloudService.ServiceModel"
#define PVO_WCF_USER_AGENT @"AISync iPhone"


#define ACTIVATION_WCF_SOAP_ACTION_PREFIX @"http://igcsoftware.com/igcactivation.web/"
#define ACTIVATION_WCF_XMLNS @"http://igcsoftware.com/"
#define ACTIVATION_USER_AGENT @"iPhone"

#define HEARTBEAT_WCF_PATH @"/HeartBeat/Service1.svc"
#define HEARTBEAT_WCF_SOAP_ACTION_PREFIX @"http://ActivationCheckService.ServiceModel/IActivationCheckService/"
#define HEARTBEAT_WCF_XMLNS @"http://ActivationCheckService.ServiceModel"
#define HEARTBEAT_WCF_USER_AGENT @"HeartBeat iOS"

#define ATLAS_SYNC 1
#define QM_SYNC 2
#define FILE_UPLOAD 3
#define WEB_REPORTS 4
#define BEKINS_SYNC 5
#define CUSTOM_ITEM_LISTS 6
#define PVO_SYNC 7
#define HEARTBEAT 8
#define ACTIVATION 9
#define ATLAS_SYNC_CANADA 10

@interface WebSyncParam : NSObject {
	NSString *paramName;
	NSString *paramValue;
}

@property (nonatomic, retain) NSString *paramName;
@property (nonatomic, retain) NSString *paramValue;

@end

@class WebSyncRequest;
@protocol WebSyncRequestDelegate <NSObject>
@optional
-(void)progressUpdate:(WebSyncRequest*)request isResponse:(BOOL)isResponse withBytesSent:(NSInteger)sent withTotalBytes:(NSInteger)total;
-(void)completed:(WebSyncRequest*)request withSuccess:(BOOL)success andData:(NSString*)response;
@end

@interface WebSyncRequest : NSObject<NSURLConnectionDataDelegate
    /*, NSURLConnectionDownloadDelegate*/> { //can't have both delegates apparently, it's only one or the other
	NSString *username;
	NSString *serverAddress;
	NSString *functionName;
	NSString *pitsDir;
	//NSString *data;
	int type;
	int port;
	BOOL overrideWithFullPITSAddress;
    
    //objects to use for async NSURLConnection calls
    NSURLConnection *asyncConnection;
    BOOL asyncIsFinished;
    NSURLResponse *asyncResponse;
    NSMutableData *asyncData;
    NSError *asyncError;
    BOOL asyncDecode;
    NSString *asyncFilePath;
}

@property (nonatomic) int type;
@property (nonatomic) int port;
@property (nonatomic) BOOL overrideWithFullPITSAddress;

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *serverAddress;
@property (nonatomic, retain) NSString *functionName;
@property (nonatomic, retain) NSString *pitsDir;
//@property (nonatomic, retain) NSString *data;

@property (nonatomic) BOOL runAsync;
@property (nonatomic, retain) NSObject<WebSyncRequestDelegate>* delegate;


-(BOOL)getData:(NSString**)dest;
-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode;
-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl;
-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl flushToFile:(NSString*)filePath;
-(BOOL)getData:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl flushToFile:(NSString*)filePath withOrder:(NSArray*)order;
-(BOOL)sendFile:(NSString**)dest withArguments:(NSDictionary*)args needsDecoded:(BOOL) decode withSSL:(BOOL)ssl;
-(NSString*)servicePath;
-(NSString*)serviceXMLNS;
-(NSString*)userAgent;
-(NSString*)soapActionPrefix;

@end
