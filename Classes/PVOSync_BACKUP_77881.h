//
//  PVOSync.h
//  Survey
//
//  Created by Tony Brame on 9/6/11
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSyncRequest.h"
#import "RestSyncRequest.h"
#import "XMLWriter.h"
#import "SurveyDownloadXMLParser.h"

#define PVO_SYNC_ACTION_DOWNLOAD 0
#define PVO_SYNC_ACTION_UPLOAD_INVENTORY 1
#define PVO_SYNC_ACTION_UPLOAD_HVI_AND_CUST_RESP 2
#define PVO_SYNC_ACTION_UPLOAD_DEL_HVI 3
#define PVO_SYNC_ACTION_UPLOAD_INVENTORIES 4
#define PVO_SYNC_ACTION_RECEIVE 5
#define PVO_SYNC_ACTION_DOWNLOAD_BOL 6
#define PVO_SYNC_ACTION_UPLOAD_PPI 7
#define PVO_SYNC_ACTION_UPLOAD_WEIGHT_TICKET 8
#define PVO_SYNC_ACTION_UPLOAD_PACK_SERVICES 9
#define PVO_SYNC_ACTION_UPDATE_ACTUAL_DATES 10  // TODO: Atlas logic. Dead in this repo. Remove.
#define PVO_SYNC_ACTION_UPLOAD_BOL 11
#define PVO_SYNC_ACTION_UPLOAD_DOCUMENT_WITH_REPORTTYPEID 12
#define PVO_SYNC_ACTION_SYNC_CANADA 13
#define PVO_SYNC_ACTION_GET_DATA 16
#define PVO_SYNC_ACTION_GET_DATA_WITH_ORDER_REQUEST 17
#define PVO_SYNC_ACTION_UPDATE_ORDER_STATUS 18

#define SCHEME @"https://"
#define QA_HOST @"basesync-qa.movehq.com/"
#define UAT_HOST @"basesync-uat.movehq.com/"
#define PROD_HOST @"basesync.movecrm.com/"

#define AICLOUD_PATH @"moveCRMSync/api/aicloud"

#define UNLOADS_PATH @"/unloads"
#define LOADS_PATH @"/loads"
#define ORDERS_PATH @"/orders"
#define REPORTS_PATH @"/reports"
#define WEIGHT_TICKET_PATH @"/weightTickets"
#define INVENTORY_ACTIVITY_PATH @"/inventoryActivity"
#define ITEM_IMAGES_PATH @"/images/items"
#define ROOM_IMAGES_PATH @"/images/rooms"
#define LOCATION_IMAGES_PATH @"/images/locations"

@class PVOSync;
@protocol PVOSyncDelegate <NSObject>
@optional
-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete;
-(void)syncProgressUpdate:(PVOSync*)sync withMessage:(NSString*)message andPercentComplete:(double)percentComplete animated:(BOOL)animated;
-(void)syncProgressBarUpdate:(double)percentComplete;
-(void)syncCompleted:(PVOSync*)sync withSuccess:(BOOL)success;
@end

@interface PVOSync : NSOperation<WebSyncRequestDelegate> {
    NSObject *updateWindow;
    SEL updateCallback;
    SEL completedCallback;
    SEL errorCallback;
    WebSyncRequest *req;
    
    int syncAction;
    
    //so doc upload can send in the ID
    int pvoReportID;
    
    NSString *orderNumber;
    int downloadRequestType;
    
    NSArray *inventoryItemEntries;
    int receivedType;
    int receivedUnloadType;
    int loadType;
    int mproWeight;
    int sproWeight;
    int consWeight;
    
    
    //generic param info...
    id additionalParamInfo;
    
    //flag to indicate a customer record should be merged or a new created.
    BOOL mergeCustomer;
    
    //adding automatic inventory upload for atlas with the option to upload photos instead of always uploading photos
    BOOL uploadPhotosWithInventory;
    
    BOOL ssl;
}
@property (nonatomic) SEL updateCallback;
@property (nonatomic) SEL completedCallback;
@property (nonatomic) SEL errorCallback;
@property (nonatomic) int syncAction;
@property (nonatomic) int pvoReportID;
@property (nonatomic) BOOL mergeCustomer;
@property (nonatomic) BOOL uploadPhotosWithInventory;
//specifies interstate or local
@property (nonatomic) int downloadRequestType;

@property (nonatomic) int receivedType;
@property (nonatomic) int receivedUnloadType;
@property (nonatomic) int loadType;
@property (nonatomic) int mproWeight;
@property (nonatomic) int sproWeight;
@property (nonatomic) int consWeight;

@property (nonatomic, strong) RestSyncRequest *restRequest;

@property (nonatomic, strong) NSObject *updateWindow;
@property (nonatomic, strong) NSString *orderNumber;
@property (nonatomic, strong) NSArray *inventoryItemEntries;
//@property (nonatomic, retain) NSString *customerLastName;
@property (nonatomic, strong) NSString *overrideAgencyCode;
@property (nonatomic, strong) id additionalParamInfo;

@property (nonatomic, strong) NSObject<PVOSyncDelegate> *delegate;

@property (nonatomic) BOOL isDelivery;
@property (nonatomic) NSString* orderStatus;

// added for generic report/data download
@property (nonatomic, strong) NSString *functionName;
@property (nonatomic, strong) NSString *resultString;
@property (nonatomic, strong) NSArray *parameterKeys;
@property (nonatomic, strong) NSArray *parameterValues;
//

-(void)updateProgress:(NSString*)updateString withPercent:(double)percent;
-(void)resetProgressBar;
-(void)updateProgressBar:(double)percent;
-(void)updateProgressBar:(double)percent animated:(BOOL)animated;
-(void)completed;
-(void)error;
-(BOOL)downloadSurvey;
-(BOOL)receiveInventory;
-(BOOL)receiveInventory:(BOOL)skipUpdateProgress;
-(BOOL)downloadBOL;
-(BOOL)uploadCurrentDoc;
//this one has to generate reports...
-(BOOL)uploadHVIAndCustResponsibilities;
-(BOOL)generateDocument:(int)pvoDocID;

-(BOOL)uploadInventories;
-(BOOL)uploadPhotos:(int)custID;
+(NSData*)getResizedPhotoData:(UIImage*)img;

-(BOOL)downloadMMItemImages:(int)imageID forSurveyedItemID:(int)siID;
-(BOOL)downloadMMRoomImages:(int)imageID forRoomID:(int)roomID;
-(BOOL)downloadMMLocationImages;

-(BOOL)updateActualDates;
-(BOOL)updateOrderStatus;

-(XMLWriter*)getRequestXML;
-(NSDictionary*)getOrderRequestJson:(NSError**) error;

-(NSData *)getBodyDataForDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end
