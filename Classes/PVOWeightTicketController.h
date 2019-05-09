//
//  PVOAllWeightsController.h
//  Survey
//
//  Created by Tony Brame on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyImageViewer.h"
#import "PVOWeightTicket.h"
#import "PVOUploadReportView.h"
#import "PVOBaseTableViewController.h"

@class PVOWeightTicketController;
@protocol PVOWeightTicketControllerDelegate <NSObject>
@optional
-(void)weightDataEntered:(PVOWeightTicketController*)weightController;
@end

#define PVO_WEIGHT_TICKET_IMAGE 0
#define PVO_WEIGHT_TICKET_DATE 1
#define PVO_WEIGHT_TICKET_DESCRIPTION 2
#define PVO_WEIGHT_TICKET_WEIGHT 3
#define PVO_WEIGHT_TICKET_WEIGHT_TYPE 4
#define PVO_WEIGHT_TICKET_UPLOAD 5

#define PVO_ALERT_UPLOAD_WEIGHT_TICKET 100

@interface PVOWeightTicketController : PVOBaseTableViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    
    PVOWeightTicket *weightTicket;
    
    id<PVOWeightTicketControllerDelegate> delegate;
    UITextField *tboxCurrent;
    
    SurveyImageViewer *images;
    
    NSMutableArray *rows;
    
    PVOUploadReportView *uploader;
}

@property (nonatomic, strong) id<PVOWeightTicketControllerDelegate> delegate;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) PVOWeightTicket *weightTicket;
@property (nonatomic, strong) NSMutableDictionary *weightTypes;

-(void)updateValueWithField:(UITextField*)fld;

-(IBAction)cancel_Click:(id)sender;
-(IBAction)save_Click:(id)sender;

-(IBAction)textFieldDoneEditing:(id)sender;

-(void)weightTypeSelected:(NSNumber*)weightType;
-(void)ticketDateSelected:(NSDate*)newDate withIgnore:(NSDate*)ignore;

@end
