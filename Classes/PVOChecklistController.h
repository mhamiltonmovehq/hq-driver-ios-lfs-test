//
//  PVOChecklistController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Order.h"
//#import "ProcessExplanationController.h"
#import "PVOWireFrameTypeController.h"
#import "PreviewPDFController.h"
#import "PVOCheckListItem.h"
#import "SurveyCustomer.h"

@interface PVOChecklistController : UITableViewController
{
    //Order *order;
    NSArray *checklist;
    //ProcessExplanationController *process;
    PVOWireFrameTypeController *wireframe;
    //PreviewPDFController *previewPDF;
    PVOVehicle *vehicle;
    SurveyCustomer *customer;
    
    BOOL isOrigin;
}

//@property (nonatomic, retain) Order *order;
@property (nonatomic, retain) NSArray *checklist;
//@property (nonatomic, retain) ProcessExplanationController *process;
//@property (retain, nonatomic) IBOutlet UITableView *tableChecklist;
//@property (retain, nonatomic) IBOutlet UITableView *tableSummary;
@property (retain, nonatomic) PVOVehicle *vehicle;

@property (nonatomic) BOOL isOrigin;

//- (IBAction)cmdNextClick:(id)sender;
//- (IBAction)cmdPreviousClick:(id)sender;
//- (IBAction)cmdDoneClick:(id)sender;

-(BOOL)verifyFieldsAreComplete;

@end
