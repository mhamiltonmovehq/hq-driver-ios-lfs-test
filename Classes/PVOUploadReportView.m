//
//  PVOUploadReportView.m
//  Survey
//
//  Created by Tony Brame on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOUploadReportView.h"
#import "PVOSync.h"
#import "SurveyAppDelegate.h"
#import "PVOPrintController.h"

@implementation PVOUploadReportView

@synthesize viewLoading;
@synthesize activity, delegate;
@synthesize labelStatus, sync, suppressLoadingScreen;
@synthesize updateCallback;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        
        CGRect viewFrame = appwindow.frame;
        
        viewLoading = [[UIView alloc] initWithFrame:appwindow.frame];
        viewLoading.backgroundColor = [UIColor blackColor];
        viewLoading.alpha = .75;
        
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGSize activitysize = activity.frame.size;
        activity.frame = CGRectMake(20, (viewFrame.size.height / 2) - (activitysize.height / 2), 
                                    activitysize.width, activitysize.height);
        [activity startAnimating];
        [viewLoading addSubview:activity];
            
        CGSize textSize = [@"Uploading Report" sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}];
        labelStatus = [[UILabel alloc] initWithFrame:
                       CGRectMake(30 + activitysize.width, (viewFrame.size.height / 2) - (textSize.height / 2), 
                                  300, textSize.height)];
        labelStatus.font = [UIFont systemFontOfSize:22];
        labelStatus.text = @"Uploading Report";
        labelStatus.textColor = [UIColor whiteColor];
        labelStatus.backgroundColor = [UIColor clearColor];
        [viewLoading addSubview:labelStatus];
    }
    
    return self;
}

-(void)loadWaitingScreen:(NSString*)waitMessage
{
    
    UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
    [appwindow addSubview:viewLoading];
    [appwindow bringSubviewToFront:viewLoading];

    viewLoaded = YES;
    
    if(waitMessage != nil)
        labelStatus.text = waitMessage;
}

-(void)uploadDocument:(int)pvoReportTypeID
{
    [self uploadDocument:pvoReportTypeID withAdditionalInfo:-1];
}

-(void)uploadDocument:(int)pvoReportTypeID withAdditionalInfo:(int)pvoNavItemID
{
    
    //load the document - via sync...
    self.sync = [[PVOSync alloc] init];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:del.customerID];
    
    if(cust.pricingMode == LOCAL && (shipInfo.orderNumber == nil || [shipInfo.orderNumber length] == 0))
    {
        if(viewLoaded)
            [viewLoading removeFromSuperview];
        
        [self updateProgress:@"An order number is required to receive for a shipment."];
        [self syncError];
        del.uploadingArpinDoc = NO;
        return;
    }
    sync.orderNumber = shipInfo.orderNumber;
    
    if(!viewLoaded && !suppressLoadingScreen)
    {
        UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
        [appwindow addSubview:viewLoading];
        [appwindow bringSubviewToFront:viewLoading];
    }
    
    if([del.pricingDB vanline] == ATLAS)
    {
        //Canada has its own document upload method
        if ([cust isCanadianCustomer])
        {
            sync.syncAction = PVO_SYNC_ACTION_SYNC_CANADA;
        }
        else
        {
            if(pvoReportTypeID == LOAD_HVI_AND_CUST_RESPONSIBILITIES)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_HVI_AND_CUST_RESP;
            else if(pvoReportTypeID == DEL_HIGH_VALUE)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_DEL_HVI;
            else if(pvoReportTypeID == PACK_PER_INVENTORY)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_PPI;
            else if(pvoReportTypeID == WEIGHT_TICKET)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_WEIGHT_TICKET;
            else if(pvoReportTypeID == PACKING_SERVICES || pvoReportTypeID == UNPACKING_SERVICES)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_PACK_SERVICES;
            else if (pvoReportTypeID == GENERATE_BOL)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_BOL;
            else if (pvoReportTypeID == INVENTORY || pvoReportTypeID == DELIVERY_INVENTORY || pvoReportTypeID == LOAD_HIGH_VALUE || pvoReportTypeID == LOAD_HVI_INSTRUCTIONS)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORY;
            else if (pvoReportTypeID > 0)
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_DOCUMENT_WITH_REPORTTYPEID;
            else //leaving this as default for now, but i think PVO_SYNC_ACTION_UPLOAD_DOCUMENT_WITH_REPORTTYPEID should be default
            	sync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORY;
        }
    }
    else
        sync.syncAction = PVO_SYNC_ACTION_UPLOAD_INVENTORY;
    
    sync.pvoReportID = pvoReportTypeID;
    sync.additionalParamInfo = [NSNumber numberWithInt:pvoNavItemID];
    sync.updateWindow = self;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncError);
    
    [del.operationQueue addOperation:sync];
}

-(void)updateActualDate:(BOOL)origin
{
    //load the details - via sync...
    self.sync = [[PVOSync alloc] init];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *syncTitle = @"Save To Server";
#ifdef ATLASNET
    syncTitle = @"Save To Atlas";
#endif
    
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:del.customerID];
    if(shipInfo.orderNumber == nil || [shipInfo.orderNumber length] == 0)
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"An order # is required to automatically upload load/delivery dates when the customer signs at origin/destination.  Enter the order # and use %@ to upload the actual date.", syncTitle] withTitle:@"Required Fields"];
        return;
    }
    sync.orderNumber = shipInfo.orderNumber;
    
    
    DriverData *driverInfo = [del.surveyDB getDriverData];
    
    if(driverInfo.driverNumber == nil || [driverInfo.driverNumber length] == 0)
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"A driver # is required to automatically upload load/delivery dates when the customer signs at origin/destination.  Enter the driver # and use %@ to upload the actual date.", syncTitle] withTitle:@"Required Fields"];
        return;
    }
    
    sync.additionalParamInfo = [NSNumber numberWithBool:origin];
    
    labelStatus.text = @"Uploading Actual Date";
    
    UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
    [appwindow addSubview:viewLoading];
    [appwindow bringSubviewToFront:viewLoading];
    
    sync.syncAction = PVO_SYNC_ACTION_UPDATE_ACTUAL_DATES;
    
    sync.updateWindow = self;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncCompleted);
    
    [del.operationQueue addOperation:sync];
}

-(void)receiveLoad
{
    
    //load the details - via sync...
    self.sync = [[PVOSync alloc] init];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    ShipmentInfo *shipInfo = [del.surveyDB getShipInfo:del.customerID];
    if(shipInfo.orderNumber == nil || [shipInfo.orderNumber length] == 0)
    {
        [SurveyAppDelegate showAlert:@"An order number is required to receive for a shipment." withTitle:@"Required Fields"];
        return;
    }
    sync.orderNumber = shipInfo.orderNumber;
    
    labelStatus.text = @"Receiving";
    
    UIWindow *appwindow = [[UIApplication sharedApplication] keyWindow];
    [appwindow addSubview:viewLoading];
    [appwindow bringSubviewToFront:viewLoading];
    
    sync.syncAction = PVO_SYNC_ACTION_RECEIVE;
    
    sync.updateWindow = self;
    sync.updateCallback = @selector(updateProgress:);
    sync.completedCallback = @selector(syncCompleted);
    sync.errorCallback = @selector(syncError);
    
    [del.operationQueue addOperation:sync];
}

-(void)updateProgress:(NSString*)textToAdd
{
    if (!suppressLoadingScreen)
        [SurveyAppDelegate showAlert:textToAdd withTitle:sync.syncAction == PVO_SYNC_ACTION_RECEIVE ? @"Receive" : @"Upload Report"];
    else if (delegate != nil && [delegate respondsToSelector:updateCallback])
    {
        [delegate performSelector:updateCallback withObject:textToAdd];
    }
}

-(void)syncCompleted
{
    if(!suppressLoadingScreen)
        [viewLoading removeFromSuperview];
    
    viewLoaded = NO;
    
    if(sync.syncAction == PVO_SYNC_ACTION_RECEIVE && delegate != nil && [delegate respondsToSelector:@selector(receiveCompleted:withItems:)])
        [delegate receiveCompleted:self withItems:sync.inventoryItemEntries];
    else if(sync.syncAction != PVO_SYNC_ACTION_RECEIVE && delegate != nil && [delegate respondsToSelector:@selector(uploadCompleted:)])
        [delegate uploadCompleted:self];
}

-(void)syncError
{
    if(!suppressLoadingScreen)
        [viewLoading removeFromSuperview];
    
    viewLoaded = NO;
    
    if(delegate != nil && [delegate respondsToSelector:@selector(uploadError:)])
        [delegate uploadError:self];
}
@end
