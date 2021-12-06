//
//  CustomerOptionsController.m
//  Survey
//
//  Created by Tony Brame on 5/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CustomerOptionsController.h"
#import	"BasicInfoController.h"
#import "LocationController.h"
#import "SurveyAppDelegate.h"
#import "WebSyncRequest.h"
#import "CustomerUtilities.h"
#import "Prefs.h"
#import "DocumentLibraryController.h"
#import "AppFunctionality.h"

@implementation CustomerOptionsController


@synthesize cmd_BasicInfo;
@synthesize cmd_Agents;
@synthesize cmd_Dates;
@synthesize cmd_Origin;
@synthesize cmd_Destination;
@synthesize cmd_Survey;
@synthesize cmd_Notes;
@synthesize cmd_MoveInfo;
@synthesize cmd_Miscellaneous;
@synthesize cmd_Pricing;
@synthesize cmd_PriceSummary;
@synthesize cmd_PackCrateSummary;


@synthesize selectedItem, surveySummaryController, inventoryController;
@synthesize datesController, agentsController, infoController;
@synthesize receiveController;
@synthesize pvoController, pvoClaimsController;

- (void)viewDidLoad
{
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
	
	[super viewDidLoad];
}

-(IBAction)doneEditingNote:(NSString*)newNote
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	[del.surveyDB updateCustomerNote:selectedItem.custID withNote:newNote];
}


-(IBAction)cmd_AgentsPressed:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if(agentsController == nil)
	{
		agentsController = [[SurveyAgentsController alloc] initWithStyle:UITableViewStyleGrouped];
		agentsController.title = @"Agents";
	}
	[del.navController pushViewController:agentsController animated:YES];
}

-(IBAction)cmd_BasicInfoPressed:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	BasicInfoController *basicController = [[BasicInfoController alloc] initWithStyle:UITableViewStyleGrouped];
    basicController.title = del.viewType == OPTIONS_PVO_VIEW ? @"Shipper Info" : @"Basic Info";
	basicController.custID = selectedItem.custID;
	
	[del.navController pushViewController:basicController animated:YES];
}

-(IBAction)cmd_DatesPressed:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if(datesController == nil)
	{
		datesController = [[SurveyDatesController alloc] initWithStyle:UITableViewStyleGrouped];
		datesController.title = @"Dates";
	}
	[del.navController pushViewController:datesController animated:YES];
}

-(IBAction)cmd_OriginPressed:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    LocationController *locationController = [[LocationController alloc] initWithStyle:UITableViewStyleGrouped];
    locationController.title = @"Origin";
	locationController.locationID = ORIGIN_LOCATION_ID;
	locationController.dirty = FALSE;
	
	//tell that view what customer was selected.
	locationController.custID = selectedItem.custID;
	
	[del.navController pushViewController:locationController animated:YES];
}

-(IBAction)cmd_DestinationPressed:(id)sender
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    LocationController *locationController = [[LocationController alloc] initWithStyle:UITableViewStyleGrouped];
	locationController.title = @"Destination";
	locationController.locationID = DESTINATION_LOCATION_ID;
	locationController.dirty = FALSE;
	
	//tell that view what customer was selected.
	locationController.custID = selectedItem.custID;
	
	[del.navController pushViewController:locationController animated:YES];
}

-(IBAction)cmd_SurveyPressed:(id)sender
{
    if(pvoController == nil)
        pvoController = [[PVONavigationController alloc] initWithNibName:@"PVONavigationView" bundle:nil];
    pvoController.currentPage = 1;
    [self.navigationController pushViewController:pvoController animated:YES];
}

-(IBAction)cmd_NotesPressed:(id)sender
{
    /*if(pvoClaimsController == nil)
        pvoClaimsController = [[PVOClaimsSummaryController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:pvoClaimsController animated:YES];*/
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *note = [del.surveyDB getCustomerNote:del.customerID];
    
    [del pushNoteViewController:note
                   withKeyboard:UIKeyboardTypeASCIICapable
                   withNavTitle:@"Note"
                withDescription:[NSString stringWithFormat:@"Note for: %@", selectedItem.name]
                     withCaller:self
                    andCallback:@selector(doneEditingNote:)
              dismissController:YES
                       noteType:NOTE_TYPE_CUSTOMER
                  maxNoteLength:[AppFunctionality maxNotesLengh:[CustomerUtilities customerPricingMode]]];
}

-(IBAction)cmd_MoveInfoPressed:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    if(imagesController == nil)
        imagesController = [[ExistingImagesController alloc] initWithNibName:@"ExistingImagesView" bundle:nil];
    
    imagesController.imagePaths = [del.surveyDB getImagesList:del.customerID withPhotoType:0 withSubID:0 loadAllItems:YES];
    
    PortraitNavController *nav = [[PortraitNavController alloc] initWithRootViewController:imagesController];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
    imagesController.cmdDelete.enabled = FALSE;
}

-(IBAction)cmd_MiscellaneousPressed:(id)sender
{
    if (PVO_RECEIVE_SCREEN & [AppFunctionality getPvoReceiveType])
        [self loadReceivables];
    else
        [self loadDocumentsLibrary];
}

-(IBAction)cmd_PricingPressed:(id)sender
{
    [self loadDocumentsLibrary];
}

-(IBAction)cmd_PriceSummaryPressed:(id)sender
{
    
}

-(IBAction)cmd_PackCrateSummaryPressed:(id)sender
{
    
}

-(IBAction)cmd_DuplicatePressed:(id)sender
{
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you would like to make an exact copy of the current customer?"
													   delegate:self 
											  cancelButtonTitle:@"No" 
										 destructiveButtonTitle:@"Yes"
											  otherButtonTitles:nil];
	
	[sheet showInView:self.view];
			
}

-(void)viewWillAppear:(BOOL)animated {
	
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    viewType = del.viewType;
    
	[super viewWillAppear:animated];
    
    [self setupView];
    
}

-(void)setupView
{
    BOOL showReceiveScreen = (PVO_RECEIVE_SCREEN & [AppFunctionality getPvoReceiveType]);
    BOOL showDocLibrary = ![AppFunctionality disableDocumentsLibrary];
    BOOL showAgents = ![AppFunctionality customerIsAutoInventory];
    
    if (showReceiveScreen && showDocLibrary)
    {
        cmd_Miscellaneous.hidden = NO;
        cmd_Pricing.hidden = NO;
    }
    else if (showReceiveScreen || showDocLibrary)
    {
        cmd_Miscellaneous.hidden = NO;
        cmd_Pricing.hidden = YES;
    }
    else
    {
        cmd_Miscellaneous.hidden = YES;
        cmd_Pricing.hidden = YES;
    }
    cmd_PriceSummary.hidden = YES;
    cmd_PackCrateSummary.hidden = YES;
    
    //NOTE: per feedback from Brian the agents icon should not show for auto inventory records...
    if (!showAgents)
        cmd_Agents.hidden = YES;
    
    if(pvoTruckView != nil)
        pvoTruckView.hidden = YES;
    
    
    [cmd_Notes setImage:[UIImage imageNamed:@"fb_notes"]
               forState:UIControlStateNormal];
    
    [cmd_Survey setImage:[UIImage imageNamed:@"img_inventory"]
                forState:UIControlStateNormal];
    
    [cmd_BasicInfo setImage:[UIImage imageNamed:@"img_shipper_info"]
                   forState:UIControlStateNormal];
    
    if (!cmd_Miscellaneous.hidden)
    {
        if (showReceiveScreen)
        {
            [cmd_Miscellaneous setImage:[UIImage imageNamed:@"img_receive"]
                               forState:UIControlStateNormal];
        }
        else if(showDocLibrary)
        {
            [cmd_Miscellaneous setImage:[UIImage imageNamed:@"doc_library"]
                               forState:UIControlStateNormal];
        }
    }
    
    if (!cmd_Pricing.hidden)
    {
        [cmd_Pricing setImage:[UIImage imageNamed:@"doc_library"]
                     forState:UIControlStateNormal];
    }
    
    [cmd_MoveInfo setImage:[UIImage imageNamed:@"img_images"]
                  forState:UIControlStateNormal];
    
//    if(pvoTruckView == nil)
//    {
//        UIImage *truckImage = [UIImage imageNamed:@"pvo_truck"];
//        truckImage = [SurveyAppDelegate resizeImage:truckImage withNewSize:CGSizeMake(truckImage.size.width * (PVO_IMAGE_TRUCK_HEIGHT / truckImage.size.height), PVO_IMAGE_TRUCK_HEIGHT)];
//        
//        UIImage *houseImage = [UIImage imageNamed:@"pvo_house_origin"];
//        houseImage = [SurveyAppDelegate resizeImage:houseImage withNewSize:CGSizeMake(houseImage.size.width * (PVO_IMAGE_HOUSE_HEIGHT / houseImage.size.height), PVO_IMAGE_HOUSE_HEIGHT)];
//        
//        CGRect rect = CGRectMake(PVO_VIEW_MARGIN, self.view.frame.size.height - (PVO_IMAGE_HOUSE_HEIGHT + PVO_VIEW_MARGIN),
//                                 self.view.frame.size.width - (PVO_VIEW_MARGIN*2), PVO_IMAGE_HOUSE_HEIGHT);
//        pvoTruckView = [[UIView alloc] initWithFrame:rect];
//        
//        UIImageView *houseView = [[UIImageView alloc] initWithImage:houseImage];
//        houseView.frame = CGRectMake(0, 0, houseImage.size.width, houseImage.size.height);
//        [pvoTruckView addSubview:houseView];
//        [houseView release];
//        
//        houseImage = [UIImage imageNamed:@"pvo_house_dest"];
//        houseImage = [SurveyAppDelegate resizeImage:houseImage withNewSize:CGSizeMake(houseImage.size.width * (PVO_IMAGE_HOUSE_HEIGHT / houseImage.size.height), PVO_IMAGE_HOUSE_HEIGHT)];
//        houseView = [[UIImageView alloc] initWithImage:houseImage];
//        houseView.frame = CGRectMake(rect.size.width - houseImage.size.width, 0, houseImage.size.width, houseImage.size.height);
//        [pvoTruckView addSubview:houseView];
//        [houseView release];
//        
//        //add in truck view
//        pvoTruckImage = [[UIImageView alloc] initWithImage:truckImage];
//        pvoTruckImage.frame = CGRectMake(0, PVO_IMAGE_HOUSE_HEIGHT-PVO_IMAGE_TRUCK_HEIGHT, truckImage.size.width, truckImage.size.height);
//        [pvoTruckView addSubview:pvoTruckImage];
//        
//        [self.view addSubview:pvoTruckView];
//    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
    [self updateTruckProgress];
}

-(void)updateTruckProgress
{
    return;
    
//    [UIView beginAnimations:@"TruckMove" context:nil];
//    [UIView setAnimationDuration:2];
//    
//    CGRect newFrame = pvoTruckImage.frame;
//    
//    int currentPVOProgress = 0;
//    //loop through each nav item (ordered by item id), 
//    //determine if it is completed, and if so, 
//    //update currentPVOProgress to that item's index + 1 (so it moves at 0)
//    PVONavigationListItem *item;
//    for (int i = 0; i < [pvoNavItems count]; i++) {
//        item = [pvoNavItems objectAtIndex:i];
//        if(item.completed)
//            currentPVOProgress = i + 1;
//    }
//    
//    if(currentPVOProgress > totalPVOProgress)
//        currentPVOProgress = 0;
//    
//    newFrame.origin.x = (currentPVOProgress / (double)totalPVOProgress) * 
//        (pvoTruckView.frame.size.width - pvoTruckImage.frame.size.width);  /*total width - image width (to keep it on the screen*/
//    pvoTruckImage.frame = newFrame;
//    
//    [UIView commitAnimations];
}

-(void)loadReceivables
{
    if(inventoryController == nil)
        inventoryController = [[PVOLocationSummaryController alloc] initWithNibName:@"PVOLocationSummaryView" bundle:nil];
    
    inventoryController.title = @"Location";
    //                inventoryController.inventory = inventory;
    inventoryController.quickAddPopupLoaded = NO;
    inventoryController.receiveOnly = YES;
    
    [self.navigationController pushViewController:inventoryController animated:YES];
/*
    if (receiveController == nil)
        receiveController = [[PVOReceiveController alloc] initWithNibName:@"PVOReceiveView" bundle:nil];
    receiveController.title = @"Receive";
    receiveController.loadTheThings = !(PVO_RECEIVE_ON_DOWNLOAD & [AppFunctionality getPvoReceiveType]);
//  receiveController.receivingType = PVO_RECEIVE_SCREEN;
    receiveController.receivingType = [AppFunctionality getPvoReceiveType];
    [self.navigationController pushViewController:receiveController animated:YES];
*/
}

-(void)loadDocumentsLibrary
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DocumentLibraryController *content = [[DocumentLibraryController alloc] initWithStyle:UITableViewStyleGrouped];
    content.customerMode = YES;
    content.customerID = del.customerID;
    [self.navigationController pushViewController:content animated:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated 
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated 
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == CUSTOMER_OPTIONS_ALERT_RECEIVE)
    {
        if(buttonIndex != [actionSheet cancelButtonIndex])
        {
            if(buttonIndex == 0)
            {
                if(receiveController == nil)
                    receiveController = [[PVOReceiveController alloc] initWithNibName:@"PVOReceiveView" bundle:nil];
                receiveController.title = @"Receive";
                receiveController.loadTheThings = YES;
                [self.navigationController pushViewController:receiveController animated:YES];
            }
            else if(buttonIndex == 1)
                [SurveyAppDelegate showAlert:@"Packers Inventory is not yet functional.  Currently, only the Warehouse receive method is completed." 
                                   withTitle:@"No Packer Inventory"];
        }
    }
	else if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		//copy the current customer...
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
		[del.surveyDB copyCustomer:selectedItem.custID];
	}
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != alertView.cancelButtonIndex)
	{
	}
	else 
	{
	}
	
}

@end

