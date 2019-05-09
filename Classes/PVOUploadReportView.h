//
//  PVOUploadReportView.h
//  Survey
//
//  Created by Tony Brame on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PVOSync;

@class PVOUploadReportView;
@protocol PVOUploadReportViewDelegate <NSObject>
@optional
-(void)receiveCompleted:(PVOUploadReportView*)uploadReportView withItems:(NSArray*)pvoItems;
-(void)uploadCompleted:(PVOUploadReportView*)uploadReportView;
-(void)uploadError:(PVOUploadReportView*)uploadReportView;
@end

@interface PVOUploadReportView : NSObject
{
    UIView *viewLoading;
    UIActivityIndicatorView *activity;
    UILabel *labelStatus;
    PVOSync *sync;
    
    id<PVOUploadReportViewDelegate> delegate;
    
    BOOL viewLoaded;
    BOOL suppressLoadingScreen;
    
    SEL updateCallback;
}
@property (nonatomic) BOOL suppressLoadingScreen;
@property (nonatomic, retain) UIView *viewLoading;
@property (nonatomic, retain) UIActivityIndicatorView *activity;
@property (nonatomic, retain) UILabel *labelStatus;
@property (nonatomic, retain) PVOSync *sync;
@property (nonatomic, retain) id<PVOUploadReportViewDelegate> delegate;
@property (nonatomic) SEL updateCallback;

-(void)loadWaitingScreen:(NSString*)waitMessage;
-(void)uploadDocument:(int)pvoReportTypeID;
-(void)uploadDocument:(int)pvoReportTypeID withAdditionalInfo:(int)additionalParamInfo;
-(void)updateProgress:(NSString*)textToAdd;
-(void)syncCompleted;
-(void)syncError;

-(void)updateActualDate:(BOOL)origin;
-(void)receiveLoad;

//-(void)removeFromView;

@end
