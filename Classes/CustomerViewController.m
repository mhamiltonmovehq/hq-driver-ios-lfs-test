    //
//  CustomerViewController.m
//  Survey
//
//  Created by Tony Brame on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "CustomerViewController.h"
#import "BasicInfoController.h"
#import "SurveyAppDelegate.h"
#import "RoomSummary.h"
#import "CustomerUtilities.h"
#import "PackSummaryItem.h"
#import "PackSummaryCrateItem.h"
#import "CustomerDetailPackSumCell.h"

@implementation CustomerViewController

@synthesize scroller, parent;

@synthesize customer;
@synthesize info, pricing, pricingModes, basicInfoController, popoverHolder, localPricing;
@synthesize datesController, currentPopover;
@synthesize locationController;
@synthesize surveySummaryController;
@synthesize agentsController;
@synthesize infoController;
@synthesize pricingController;
@synthesize summaryController, csSummaryController;
@synthesize miscController, tboxCurrent;
@synthesize packSummaryController, phonesController;
@synthesize localPricingController, interstateAccessorialsController, packSummary, noteViewController;
@synthesize accessorialList;
@synthesize packingList;
@synthesize estimateTypes;
@synthesize jobStatuses;
@synthesize valDeds, labelDiscBL;
@synthesize valAmts, leadSources, currentZip, imageViewer;

//detail buttons
@synthesize cmdBasicInfo;
@synthesize cmdOriginInfo;
@synthesize cmdDestinationInfo;
@synthesize cmdDates;
@synthesize cmdMoveInfo;
@synthesize cmdAgents;
@synthesize cmdPricing;
@synthesize cmdAccessorials, cmdCubesheetSummary;
@synthesize cmdPackSummary, cmdTotals;
@synthesize cmdMisc;
@synthesize cmdComments, cmdCustomerName, cmdClose, segmentView;

//basic info
@synthesize tboxFirstName;
@synthesize tboxLastName;
@synthesize tboxEmail, cmdEmail;

//origin info
@synthesize tboxOrigAdd1;
@synthesize tboxOrigAdd2;
@synthesize tboxOrigCity;
@synthesize tboxOrigState;
@synthesize tboxOrigZip;
@synthesize tboxOrigPhones;

//destination info
@synthesize tboxDestAdd1;
@synthesize tboxDestAdd2;
@synthesize tboxDestCity;
@synthesize tboxDestState;
@synthesize tboxDestZip;
@synthesize tboxDestPhones;

//dates
@synthesize tboxDatePackFrom;
@synthesize tboxDatePackTo;
@synthesize tboxDateLoadFrom;
@synthesize tboxDateLoadTo;
@synthesize tboxDateDeliverFrom;
@synthesize tboxDateDeliverTo;
@synthesize tboxDateSurvey;
@synthesize tboxDateSurveyTime;
@synthesize tboxDateFollowUp;
@synthesize tboxDateDecision;

//move info
@synthesize tboxTariff;
@synthesize tboxMiles;
@synthesize tboxLeadSource;
@synthesize tboxEstimateType;
@synthesize tboxJobStatus;
@synthesize tboxOrderNumber;

//agents info
@synthesize labelBookingName;
@synthesize labelBookingAddress;
@synthesize labelBookingCSZ;
@synthesize labelBookingPhone;
@synthesize labelOriginName;
@synthesize labelOriginAddress;
@synthesize labelOriginCSZ;
@synthesize labelOriginPhone;
@synthesize labelDestinationName;
@synthesize labelDestinationAddress;
@synthesize labelDestinationCSZ;
@synthesize labelDestinationPhone;

//survey summary
@synthesize labelSurveySummary;

//pricing info
@synthesize tboxValDed;
@synthesize tboxValAmt;
@synthesize chkPricePacking;
@synthesize tboxDateEffective;
@synthesize tboxDiscBL, labelValAmt;

@synthesize tboxComments, labelMiscHeader;

//summaries
@synthesize tableAccSummary;
@synthesize tablePackSummary;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	[cmdEmail setImage:[SurveyAppDelegate resizeImage:[UIImage imageNamed:@"mail_button.PNG"] withNewSize:cmdEmail.frame.size]
			  forState:UIControlStateNormal];
	
	scroller.contentSize = CGSizeMake(768, 960);
	
	[tableAccSummary setBackgroundView:nil];
	[tablePackSummary setBackgroundView:nil];
	
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
	//ensure i'm not registered twice..
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(keyboardWillShow:)
	 name:UIKeyboardWillShowNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(keyboardWillHide:)
	 name:UIKeyboardWillHideNotification
	 object:nil];
	
	[self initializeScreen];
	
	[super viewWillAppear:animated];
}

-(void) keyboardWillShow:(NSNotification *)note
{
	[self adjustViewForKeyboard:note showing:YES];
}

-(void) keyboardWillHide:(NSNotification *)note
{
	[self adjustViewForKeyboard:note showing:NO];
}

-(void)adjustViewForKeyboard:(NSNotification *)note showing:(BOOL)showing
{
	NSDictionary* userInfo = [note userInfo];
	
	// Get animation info from userInfo
	NSTimeInterval animationDuration;
	UIViewAnimationCurve animationCurve;
	
	CGRect keyboardEndFrame;
	
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
	
	
	[[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
	
	
	// Animate up or down
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:animationDuration];
	[UIView setAnimationCurve:animationCurve];
	
	CGRect newFrame = scroller.frame;
	CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
	
	newFrame.size.height -= keyboardFrame.size.height * (showing? 1 : -1);
	scroller.frame = newFrame;
	
	[UIView commitAnimations];
	
}

-(void) initializeScreen
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
	self.customer = cust;
	[cust release];
	
	ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
	self.info = inf;
	[inf release];
	
	InterstatePricing *priceInfo = [del.surveyDB getIntPricing:del.customerID];
	self.pricing = priceInfo;
	[priceInfo release];
	
	if(cust.pricingMode == 1)
	{
		LocalPricing *locpriceInfo = [del.surveyDB getLocalPricing];
		self.localPricing = locpriceInfo;
		[locpriceInfo release];
	}
	
	//basic info
	cmdCustomerName.title = [NSString stringWithFormat:@"%@ %@", customer.firstName, customer.lastName];
	tboxFirstName.text = customer.firstName;
	tboxLastName.text = customer.lastName;
	tboxEmail.text = customer.email;
	
	//origin info
	SurveyLocation *loc = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
	tboxOrigAdd1.text = loc.address1;
	tboxOrigAdd2.text = loc.address2;
	tboxOrigCity.text = loc.city;
	tboxOrigState.text = loc.state;
	tboxOrigZip.text = loc.zip;
	
	NSArray *phones = [del.surveyDB getCustomerPhones:del.customerID withLocationID:ORIGIN_LOCATION_ID];
	tboxOrigPhones.text = [self buildPhoneString:phones];
	[phones release];
	
	[loc release];
	
	//destination info
	loc = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
	tboxDestAdd1.text = loc.address1;
	tboxDestAdd2.text = loc.address2;
	tboxDestCity.text = loc.city;
	tboxDestState.text = loc.state;
	tboxDestZip.text = loc.zip;
	
	phones = [del.surveyDB getCustomerPhones:del.customerID withLocationID:DESTINATION_LOCATION_ID];
	tboxDestPhones.text = [self buildPhoneString:phones];
	[phones release];
	
	[loc release];
	
	//dates
	SurveyDates *dates = [del.surveyDB getDates:del.customerID];
	tboxDatePackFrom.text = [SurveyAppDelegate formatDate:dates.packFrom];
	tboxDatePackTo.text = [SurveyAppDelegate formatDate:dates.packTo];
	tboxDateLoadFrom.text = [SurveyAppDelegate formatDate:dates.loadFrom];
	tboxDateLoadTo.text = [SurveyAppDelegate formatDate:dates.loadTo];
	tboxDateDeliverFrom.text = [SurveyAppDelegate formatDate:dates.deliverFrom];
	tboxDateDeliverTo.text = [SurveyAppDelegate formatDate:dates.deliverTo];
	tboxDateSurvey.text = [SurveyAppDelegate formatDate:dates.survey];
	tboxDateFollowUp.text = [SurveyAppDelegate formatDate:dates.followUp];
	tboxDateDecision.text = [SurveyAppDelegate formatDate:dates.decision];
	tboxDateSurveyTime.text = [SurveyAppDelegate formatTime:dates.survey];
	
	[self hideOrShowDateGroup:DATE_GROUP_PACK setHidden:dates.noPack];
	[self hideOrShowDateGroup:DATE_GROUP_LOAD setHidden:dates.noLoad];
	[self hideOrShowDateGroup:DATE_GROUP_DELIVER setHidden:dates.noDeliver];
	
	[dates release];
	
	//move info
	self.pricingModes = [[CustomerUtilities getPricingModes] autorelease];
	if([del.pricingDB isUnigroup] && 
	   (info.type == WEIGHT_ALLOWANCE || info.type == NO_WEIGHT_ALLOWANCE) && customer.pricingMode == 0)
		tboxTariff.text = [pricingModes objectForKey:[NSNumber numberWithInt:2]];//GPP
	else if([del.pricingDB vanline] == BEKINS && customer.pricingMode == 0 && 
			!info.bekins412)
		tboxTariff.text = [pricingModes objectForKey:[NSNumber numberWithInt:2]];//400N
	else
		tboxTariff.text = [pricingModes objectForKey:[NSNumber numberWithInt:customer.pricingMode]];
	
	self.estimateTypes = [[CustomerUtilities getEstimateTypes] autorelease];
	tboxEstimateType.text = [estimateTypes objectForKey:[NSNumber numberWithInt:info.type]];
	
	self.jobStatuses = [[CustomerUtilities getJobStatuses] autorelease];
	tboxJobStatus.text = [jobStatuses objectForKey:[NSNumber numberWithInt:info.status]];
	
	tboxMiles.text = [NSString stringWithFormat:@"%d", info.miles];
	self.leadSources = [[del.surveyDB getLeadSources] autorelease];
	if([leadSources count] > 0)
	{
		tboxLeadSource.textColor = tboxOrigPhones.textColor;
		tboxLeadSource.delegate = self;
	}
	else
	{
		tboxLeadSource.textColor = tboxOrigAdd1.textColor;
		tboxLeadSource.delegate = nil;
	}
	
	tboxLeadSource.text = info.leadSource;
	tboxOrderNumber.text = info.orderNumber;
	
	//agents
	SurveyAgent *agent = [del.surveyDB getAgent:del.customerID withAgentID:AGENT_BOOKING];
	labelBookingName.text = [NSString stringWithFormat:@"Booking: %@ %@", agent.name, 
								 [agent.code isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"(%@)", agent.code]];
	labelBookingAddress.text = agent.address;
	
	if([agent.city isEqualToString:@""] && [agent.state isEqualToString:@""] && [agent.zip isEqualToString:@""])
		labelBookingCSZ.text = @"";
	else
		labelBookingCSZ.text = [NSString stringWithFormat:@"%@, %@ %@", agent.city, agent.state, agent.zip];
	
	labelBookingPhone.text = agent.phone;
	[agent release];
	
	agent = [del.surveyDB getAgent:del.customerID withAgentID:AGENT_ORIGIN];
	labelOriginName.text = [NSString stringWithFormat:@"Origin: %@ %@", agent.name, 
								 [agent.code isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"(%@)", agent.code]];
	labelOriginAddress.text = agent.address;
	
	if([agent.city isEqualToString:@""] && [agent.state isEqualToString:@""] && [agent.zip isEqualToString:@""])
		labelOriginCSZ.text = @"";
	else
		labelOriginCSZ.text = [NSString stringWithFormat:@"%@, %@ %@", agent.city, agent.state, agent.zip];
	
	labelOriginPhone.text = agent.phone;
	[agent release];
	
	agent = [del.surveyDB getAgent:del.customerID withAgentID:AGENT_DESTINATION];
	labelDestinationName.text = [NSString stringWithFormat:@"Destination: %@ %@", agent.name, 
								 [agent.code isEqualToString:@""] ? @"" : [NSString stringWithFormat:@"(%@)", agent.code]];
	labelDestinationAddress.text = agent.address;
	
	if([agent.city isEqualToString:@""] && [agent.state isEqualToString:@""] && [agent.zip isEqualToString:@""])
		labelDestinationCSZ.text = @"";
	else
		labelDestinationCSZ.text = [NSString stringWithFormat:@"%@, %@ %@", agent.city, agent.state, agent.zip];
	
	labelDestinationPhone.text = agent.phone;
	[agent release];
	
	
	labelMiscHeader.text = [NSString stringWithFormat:@"Misc Items (%d)", 
							[[[del.surveyDB getMiscItems:del.customerID] autorelease] count]];	
	tboxComments.text = [[del.surveyDB getCustomerNote:del.customerID] autorelease];
	
	//survey summary
	RoomSummary *total = [CustomerUtilities getTotalSurveyedSummary];
	labelSurveySummary.text = [NSString stringWithFormat:@"%d items shipping, %d items not shipping, %@ cubic feet, %@ pounds",
							   total.shipping, total.notShipping, 
							   [SurveyAppDelegate formatDouble:total.cube withPrecision:1],
							   [SurveyAppDelegate formatDouble:total.weight withPrecision:0]];
	[total release];
	
	//pricing info
	if(customer.pricingMode == 1)
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		
		[dict setObject:@"$0.60/lb Released" forKey:[NSNumber numberWithInt:SIXTY_CENTS]];
		[dict setObject:@"FVP - $0 Ded." forKey:[NSNumber numberWithInt:ZERO]];
		[dict setObject:@"FVP - $250 Ded." forKey:[NSNumber numberWithInt:TWO_FIFTY]];
		[dict setObject:@"FVP - $500 Ded." forKey:[NSNumber numberWithInt:FIVE_HUNDRED]];
		
		NSArray *deds = [del.surveyDB getLocalVal];
		LocalValDed *temp;
		for(int i = 0; i < [deds count]; i++)
		{
			temp = [deds objectAtIndex:i];
			[dict setObject:[NSString stringWithFormat:@"FVP - $%d Ded.",temp.deductible] 
					 forKey:[NSNumber numberWithInt:CUSTOM + i]];
		}
		[deds release];
		self.valDeds = dict;
		[dict release];
		tboxValDed.text = [valDeds objectForKey:[NSNumber numberWithInt:localPricing.valDed]];
		
		self.valAmts = [[del.pricingDB getValuationAmounts:pricing.effDate with50Plus:FALSE] autorelease];
		tboxValAmt.text = [SurveyAppDelegate formatCurrency:localPricing.valAmt];
		
		tboxValAmt.textColor = tboxOrigAdd1.textColor;
		tboxValAmt.delegate = nil;
		
		tboxValAmt.hidden = localPricing.valDed == SIXTY_CENTS;
		labelValAmt.hidden = localPricing.valDed == SIXTY_CENTS;
	}
	else
	{
		self.valDeds = [[del.pricingDB getValuationDeductibles:pricing.effDate with50Plus:pricing.arpin50Plus] autorelease];
		tboxValDed.text = [valDeds objectForKey:[NSNumber numberWithInt:pricing.valuationDed]];
		
		self.valAmts = [[del.pricingDB getValuationAmounts:pricing.effDate with50Plus:pricing.arpin50Plus] autorelease];
		tboxValAmt.text = [valAmts objectForKey:[NSNumber numberWithDouble:pricing.valuationAmount]];
		
		tboxValAmt.textColor = tboxOrigPhones.textColor;
		tboxValAmt.delegate = self;
		
		tboxValAmt.hidden = pricing.valuationDed == SIXTY_CENTS;
		labelValAmt.hidden = pricing.valuationDed == SIXTY_CENTS;
	}
	
	Discounts *discs = [del.surveyDB getDiscounts:del.customerID];
	tboxDateEffective.text = [SurveyAppDelegate formatDate:pricing.effDate];
	chkPricePacking.on = pricing.pricePacking;
	tboxDiscBL.text = [SurveyAppDelegate formatDouble:discs.bottomLine];
	tboxDiscBL.hidden = [del.pricingDB isUnigroup] && customer.pricingMode == 0 && (info.type == WEIGHT_ALLOWANCE || info.type == NO_WEIGHT_ALLOWANCE);
	labelDiscBL.hidden = [del.pricingDB isUnigroup] && customer.pricingMode == 0 && (info.type == WEIGHT_ALLOWANCE || info.type == NO_WEIGHT_ALLOWANCE);
	[discs release];
	
	tboxComments.font = [UIFont systemFontOfSize:14];
	
	//summaries
	if(customer.pricingMode == 1)
		[self loadLocalAccessorials];
	else
		[self loadAccessorials];
	[tableAccSummary reloadData];
	[self loadPacking];
	[tablePackSummary reloadData];
}

-(void)hideOrShowDateGroup:(int)dateGroup setHidden:(BOOL)hidden
{
	for (UIView *v in self.scroller.subviews) {
		for (UIView *v2 in v.subviews) {
			if(v2.tag == dateGroup)
				v2.hidden = hidden;
		}
	}
}

-(void)loadPacking
{
	self.packingList = [[CustomerUtilities loadPackSummaryItems:NO] autorelease];
	[packingList addObjectsFromArray:[[CustomerUtilities loadCrateSummaryItems] autorelease]];
}


-(void)loadLocalAccessorials
{
	//rate...
	self.accessorialList = [NSMutableArray array];
	LocalPriceCalc *rater = [[LocalPriceCalc alloc] init];
	[rater RateLocalEstimate];
	
	BulkyItem *bi;
	for(int i=0; i < [rater.price.bulkies count]; i++)
	{
		bi = [rater.price.bulkies objectAtIndex:i];
		[accessorialList addObject:[BulkyItem getBulkyName:bi.BulkyID]];
	}
	
	if(rater.price.accOrigStairs)
		[accessorialList addObject:@"Origin Stairs"];
	
	if(rater.price.accOrigElevators)
		[accessorialList addObject:@"Origin Elevators"];
	
	if(rater.price.accOrigLongs)
		[accessorialList addObject:@"Origin Long Carry"];
	
	if(rater.price.accOrigAppliances)
		[accessorialList addObject:@"Origin Appliance"];
	
	if(rater.price.accOrigDiversions)
		[accessorialList addObject:@"Origin Diversions"];
	
	if(rater.price.accOrigShuttle)
		[accessorialList addObject:@"Origin Shuttle"];
	
	if(rater.price.accOrigExLabor)
		[accessorialList addObject:@"Origin Ex Labor"];
	
	if(rater.price.exStops)
		[accessorialList addObject:@"Extra Locations"];
	
	if(rater.price.accDestStairs)
		[accessorialList addObject:@"Destination Stairs"];
	
	if(rater.price.accDestElevators)
		[accessorialList addObject:@"Destination Elevators"];
	
	if(rater.price.accDestLongs)
		[accessorialList addObject:@"Destination Long Carry"];
	
	if(rater.price.accDestAppliances)
		[accessorialList addObject:@"Destination Appliance"];
	
	if(rater.price.accDestDiversions)
		[accessorialList addObject:@"Destination Diversions"];
	
	if(rater.price.accDestShuttle)
		[accessorialList addObject:@"Destination Shuttle"];
	
	if(rater.price.accDestExLabor)
		[accessorialList addObject:@"Destination Ex Labor"];
	
	if(rater.price.sitOrig)
		[accessorialList addObject:@"Origin SIT"];
	
	if(rater.price.sitOrigCartage)
		[accessorialList addObject:@"Origin SIT Cartage"];
	
	if(rater.price.sitOrigHandling)
		[accessorialList addObject:@"Origin SIT Handling"];
	
	if(rater.price.sitDest)
		[accessorialList addObject:@"Destination SIT"];
	
	if(rater.price.sitDestCartage)
		[accessorialList addObject:@"Destination SIT Cartage"];
	
	if(rater.price.sitDestHandling)
		[accessorialList addObject:@"Destination SIT Handling"];
	
	if(rater.price.accOrigStorage)
		[accessorialList addObject:@"Origin Storage"];
	
	if(rater.price.accOrigStoCartage)
		[accessorialList addObject:@"Origin Storage Cartage"];
	
	if(rater.price.accOrigStoHandling)
		[accessorialList addObject:@"Origin Storage Handling"];
		
	[rater release];
}

-(void)loadAccessorials
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	self.accessorialList = [NSMutableArray array];
	int totalWeight = (int)[CustomerUtilities getTotalCustomerWeight];
	
	InterstateAccessorials *origacc = [del.surveyDB getAccessorials:del.customerID withLocationID:ORIGIN_LOCATION_ID];
	InterstateAccessorials *destacc = [del.surveyDB getAccessorials:del.customerID withLocationID:DESTINATION_LOCATION_ID];
	
	if(origacc.exLabor)
	{
		[accessorialList addObject:@"Org Extra Labor"];
	}
	if(destacc.exLabor)
	{
		[accessorialList addObject:@"Dest Extra Labor"];
	}
	if(origacc.exLaborOT)
	{
		[accessorialList addObject:@"Org Extra Labor OT"];
	}
	if(destacc.exLaborOT)
	{
		[accessorialList addObject:@"Dest Extra Labor OT"];
	}
	
	if(origacc.waitTime)
	{
		[accessorialList addObject:@"Org Wait Time"];
	}
	if(destacc.waitTime)
	{
		[accessorialList addObject:@"Dest Wait Time"];
	}
	if(origacc.waitTimeOT)
	{
		[accessorialList addObject:@"Org Wait Time OT"];
	}
	if(destacc.waitTimeOT)
	{
		[accessorialList addObject:@"Dest Wait Time OT"];
	}
	
	if(origacc.otLoad)
	{
		[accessorialList addObject:@"Org OT Load"];
	}
	if(destacc.otLoad)
	{
		[accessorialList addObject:@"Dest OT Unload"];
	}
	
	if(origacc.otPack)
	{
		[accessorialList addObject:@"Org OT Pack"];
	}
	if(destacc.otPack)
	{
		[accessorialList addObject:@"Dest OT Unpack"];
	}
	
	if(origacc.shuttle)
	{
		[accessorialList addObject:[NSString stringWithFormat:@"Org Shuttle, %d lbs", 
													  origacc.shuttleWeight == 0 ? totalWeight : origacc.shuttleWeight]];
	}
	if(destacc.shuttle)
	{
		[accessorialList addObject:[NSString stringWithFormat:@"Dest Shuttle, %d lbs", 
													  origacc.shuttleWeight == 0 ? totalWeight : origacc.shuttleWeight]];
	}
	
	if(origacc.sitDays)
	{
		[accessorialList addObject:@"Org SIT"];
	}
	if(destacc.sitDays)
	{
		[accessorialList addObject:@"Dest SIT"];
	}
	
	int stops = [del.surveyDB getExtraLocationsCount:del.customerID];
	if(stops)
	{
		[accessorialList addObject:[NSString stringWithFormat:@"%d Extra Stops", stops]];
	}
	
	//mini storage
	for (int i = 0; i < 2; i++) {
		NSArray *ministo = [del.surveyDB getMiniStorage:del.customerID 
										 withLocationID:i == 0 ? ORIGIN_LOCATION_ID : DESTINATION_LOCATION_ID];
		for (MiniStorage *ms in ministo) {
			[accessorialList addObject:[NSString stringWithFormat:@"%@ Mini Storage, %d lbs", 
										i == 0 ? @"Org" : @"Dest", 
										ms.weight == 0 ? totalWeight : ms.weight]];
		}
		[ministo release];
	}
	
	//bulkies
	SurveyedItemsList *bulkies = [del.surveyDB getBulkies:del.customerID];
	NSEnumerator *enumerator = [bulkies.list objectEnumerator];
	SurveyedItem *si;
	while (si = [enumerator nextObject]) {
		if(si.shipping > 0)
		{
			[accessorialList addObject:[NSString stringWithFormat:@"%@ (%d)", 
										[[[del.surveyDB getItem:si.itemID] autorelease] name], si.shipping]];
		}
	}
	
	[origacc release];
	[destacc release];	
}

-(NSString*) buildPhoneString:(NSArray*)phones
{
	NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
	for (SurveyPhone *phone in phones) 
	{
		if([str isEqualToString:@""])
			[str appendString:phone.number];
		else
			[str appendFormat:@", %@", phone.number];
	}
	
	return [str autorelease];
}

-(void) saveScreen
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	//basic info
	customer.firstName = tboxFirstName.text;
	customer.lastName = tboxLastName.text;
	customer.email = tboxEmail.text;
	[del.surveyDB updateCustomer:customer];
	
	//origin
	SurveyLocation *loc = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
	loc.address1 = tboxOrigAdd1.text;
	loc.address2 = tboxOrigAdd2.text;
	loc.city = tboxOrigCity.text;
	loc.state = tboxOrigState.text;
	loc.zip = tboxOrigZip.text;
	
	[del.surveyDB updateLocation:loc];
	[loc release];
	
	//destination
	loc = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
	loc.address1 = tboxDestAdd1.text;
	loc.address2 = tboxDestAdd2.text;
	loc.city = tboxDestCity.text;
	loc.state = tboxDestState.text;
	loc.zip = tboxDestZip.text;
	
	[del.surveyDB updateLocation:loc];
	[loc release];
	
	//dates
	SurveyDates *dates = [del.surveyDB getDates:del.customerID];
	dates.packFrom = [SurveyAppDelegate prepareDate:tboxDatePackFrom.text];
	dates.packTo = [SurveyAppDelegate prepareDate:tboxDatePackTo.text];
	dates.loadFrom = [SurveyAppDelegate prepareDate:tboxDateLoadFrom.text];
	dates.loadTo = [SurveyAppDelegate prepareDate:tboxDateLoadTo.text];
	dates.deliverFrom = [SurveyAppDelegate prepareDate:tboxDateDeliverFrom.text];
	dates.deliverTo = [SurveyAppDelegate prepareDate:tboxDateDeliverTo.text];
	dates.survey = [SurveyAppDelegate prepareDate:tboxDateSurvey.text];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"hh:mm a"];
	NSDate *time = [formatter dateFromString:tboxDateSurveyTime.text];
	//take the time interval, which is gmt, and add the current time zome seconds from gmt, then adjust by an hour (not sure why, but it worked --- DAYLIGHT SAVINGS TIME, this broke!!)
    /*
     ok, for some reason, and I imainge it has to do with NSDateFormatter, 
     [[NSTimeZone systemTimeZone] secondsFromGMTForDate:time]
     doesn't return the same thing as 
     [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]], and
     [[NSTimeZone systemTimeZone] secondsFromGMT]
     
     NSDateFormatter apparently doesn't account for DST, but the others do, and that was an issue for us.  
     we wanted non-dst numbers.
     */
	dates.survey = [dates.survey dateByAddingTimeInterval:[time timeIntervalSince1970] + [[NSTimeZone systemTimeZone] secondsFromGMTForDate:time]];
	[formatter release];
	
	dates.followUp = [SurveyAppDelegate prepareDate:tboxDateFollowUp.text];
	dates.decision = [SurveyAppDelegate prepareDate:tboxDateDecision.text];	
	[del.surveyDB updateDates:dates];
	[dates release];
	
	//shipemtn info
	info.miles = [tboxMiles.text intValue];
	info.leadSource = tboxLeadSource.text;
	info.orderNumber = tboxOrderNumber.text;
	[del.surveyDB updateShipInfo:info];
	
	//pricing
	if(customer.pricingMode == 0)
	{
		pricing.effDate = [SurveyAppDelegate prepareDate:tboxDateEffective.text];
		//idk why this is here?
		//pricing.pricePacking = chkPricePacking.on;
		[del.surveyDB updateIntPricing:pricing];
	}
	else
	{
		localPricing.valAmt = [[tboxValAmt.text stringByReplacingOccurrencesOfString:@"$" withString:@""] doubleValue];
		[del.surveyDB updateLocalPricing:localPricing];
	}
	
	[del.surveyDB updateCustomerNote:del.customerID withNote:tboxComments.text];
	
	Discounts *discs = [del.surveyDB getDiscounts:del.customerID];
	discs.bottomLine = [tboxDiscBL.text doubleValue];
	[del.surveyDB updateDiscounts:discs];
	
}

-(void) dateChanged:(NSDate*)newDate withIgnore:(NSDate*)ignoreMe
{
	if(tboxCurrent == tboxDateSurveyTime)
	{//time
		tboxCurrent.text = [SurveyAppDelegate formatTime:newDate];
	}
	else
	{//date
		tboxCurrent.text = [SurveyAppDelegate formatDate:newDate];
		if(tboxCurrent == tboxDatePackTo && 
		   [newDate timeIntervalSince1970] < [[SurveyAppDelegate prepareDate:tboxDatePackFrom.text] timeIntervalSince1970])
			tboxDatePackFrom.text = [SurveyAppDelegate formatDate:newDate];
		if(tboxCurrent == tboxDateLoadTo && 
		   [newDate timeIntervalSince1970] < [[SurveyAppDelegate prepareDate:tboxDateLoadFrom.text] timeIntervalSince1970])
			tboxDateLoadFrom.text = [SurveyAppDelegate formatDate:newDate];
		if(tboxCurrent == tboxDateDeliverTo && 
		   [newDate timeIntervalSince1970] < [[SurveyAppDelegate prepareDate:tboxDateDeliverFrom.text] timeIntervalSince1970])
			tboxDateDeliverFrom.text = [SurveyAppDelegate formatDate:newDate];
		
		if(tboxCurrent == tboxDatePackFrom && 
		   [newDate timeIntervalSince1970] > [[SurveyAppDelegate prepareDate:tboxDatePackTo.text] timeIntervalSince1970])
			tboxDatePackTo.text = [SurveyAppDelegate formatDate:newDate];
		if(tboxCurrent == tboxDateLoadFrom && 
		   [newDate timeIntervalSince1970] > [[SurveyAppDelegate prepareDate:tboxDateLoadTo.text] timeIntervalSince1970])
			tboxDateLoadTo.text = [SurveyAppDelegate formatDate:newDate];
		if(tboxCurrent == tboxDateDeliverFrom && 
		   [newDate timeIntervalSince1970] > [[SurveyAppDelegate prepareDate:tboxDateDeliverTo.text] timeIntervalSince1970])
			tboxDateDeliverTo.text = [SurveyAppDelegate formatDate:newDate];
	}
}

-(IBAction) close:(id)sender
{
	[self saveScreen];
	
	if(parent != nil)
		[parent dismissModalViewControllerAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

-(UIPopoverController*)showPopoverControl:(UIViewController *)viewController inRect:(CGRect)rect
{
	return [self showPopoverControl:viewController inRect:rect fromBarButton:nil];
}

-(UIPopoverController*)showPopoverControl:(UIViewController *)viewController inRect:(CGRect)rect fromBarButton:(UIBarButtonItem*)button
{
	[self saveScreen];
	
	UINavigationController *holder = [[UINavigationController alloc] initWithRootViewController:viewController];
	self.popoverHolder = holder;
	[holder release];
	
	UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:popoverHolder];
	//popover.popoverContentSize = CGSizeMake(320, 460);
	self.currentPopover = popover;
	popover.delegate = self;
	if(button == nil)
	{
		[popover presentPopoverFromRect:rect 
								 inView:self.scroller 
			   permittedArrowDirections:UIPopoverArrowDirectionAny 
							   animated:YES];
	}
	else
	{
		[popover presentPopoverFromBarButtonItem:button 
						permittedArrowDirections:UIPopoverArrowDirectionAny 
										animated:YES];
	}

	return [popover autorelease];
}

-(IBAction)cmd_DuplicatePressed:(id)sender
{
	
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you would like to make an exact copy of the current customer?"
													   delegate:self 
											  cancelButtonTitle:@"No" 
										 destructiveButtonTitle:@"Yes"
											  otherButtonTitles:nil];
	sheet.tag = ACTION_SHEET_DUPLICATE;
	[sheet showInView:self.view];
	[sheet release];		
}


-(IBAction) cmdBasicInfo_click:(id)sender
{
	self.basicInfoController = [[[BasicInfoController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	basicInfoController.title = @"Basic Info";
	basicInfoController.custID = customer.custID;
	basicInfoController.popover = [self showPopoverControl:basicInfoController inRect:cmdBasicInfo.frame];
}

-(IBAction) cmdOriginInfo_click:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	self.locationController = [[[LocationController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	locationController.title = @"Origin";
	locationController.locationID = ORIGIN_LOCATION_ID;
	locationController.dirty = FALSE;
	del.locationID = locationController.locationID;
	locationController.custID = del.customerID;
	[self showPopoverControl:locationController inRect:cmdOriginInfo.frame];
}

-(IBAction) cmdOriginPhotos_click:(id)sender
{
	if(imageViewer == nil)
		self.imageViewer = [[SurveyImageViewer alloc] init];
	
	imageViewer.photosType = IMG_LOCATIONS;
	imageViewer.customerID = customer.custID;
	imageViewer.subID = ORIGIN_LOCATION_ID;
	
	imageViewer.caller = self.view;
	imageViewer.viewController = self;
	imageViewer.ipadPresentView = self.scroller;
	
	imageViewer.ipadFrame = ((UIButton*)sender).frame;
	
	[imageViewer loadPhotos];
}

-(IBAction) cmdDestinationPhotos_click:(id)sender
{
	if(imageViewer == nil)
		self.imageViewer = [[SurveyImageViewer alloc] init];
	
	imageViewer.photosType = IMG_LOCATIONS;
	imageViewer.customerID = customer.custID;
	imageViewer.subID = DESTINATION_LOCATION_ID;
	
	imageViewer.caller = self.view;
	imageViewer.viewController = self;
	imageViewer.ipadPresentView = self.scroller;
	
	imageViewer.ipadFrame = ((UIButton*)sender).frame;
	
	[imageViewer loadPhotos];
}

-(IBAction) cmdDestinationInfo_click:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	self.locationController = [[[LocationController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	locationController.title = @"Destination";
	locationController.locationID = DESTINATION_LOCATION_ID;
	locationController.dirty = FALSE;
	del.locationID = locationController.locationID;
	locationController.custID = del.customerID;
	[self showPopoverControl:locationController inRect:cmdDestinationInfo.frame];
}

-(IBAction) cmdDates_click:(id)sender
{
	self.datesController = [[[SurveyDatesController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	datesController.title = @"Dates";
	[self showPopoverControl:datesController inRect:cmdDates.frame];
}

-(IBAction) cmdMoveInfo_click:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	self.infoController = [[[InfoController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	infoController.title = @"Shipment Info";
	infoController.info = [[del.surveyDB getShipInfo:del.customerID] autorelease];
	infoController.sync = [[del.surveyDB getCustomerSync:del.customerID] autorelease];
	infoController.popover = [self showPopoverControl:infoController inRect:cmdMoveInfo.frame];
}

-(IBAction) cmdAgents_click:(id)sender
{
	self.agentsController = [[[SurveyAgentsController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	agentsController.title = @"Agents";
	[self showPopoverControl:agentsController inRect:cmdAgents.frame];
}

-(IBAction) cmdPricing_click:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	
	if(customer.pricingMode == 0)
	{
		self.pricingController = [[[IntPricingController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		pricingController.title = @"Pricing";
		pricingController.pricing = pricing;
		[self saveScreen];
		pricingController.discounts = [[del.surveyDB getDiscounts:del.customerID] autorelease];
		
		if([del.pricingDB vanline] == ATLAS)
			pricingController.freeFVP = [[del.surveyDB getFreeFVP] autorelease];
		
		if([CustomerUtilities tpgApplied])
		{
			TPGInfo *inf = [del.surveyDB getTPGInfo:del.customerID];
			pricingController.tpgInfo = inf;
			[inf release];
		}
		else 
		{
			pricingController.tpgInfo = nil;
		}
		[self showPopoverControl:pricingController inRect:cmdPricing.frame];
	}
	else
	{
		self.localPricingController = [[[LocalPricingController alloc] initWithNibName:@"LocalPricingView" bundle:nil] autorelease];
		localPricingController.title = @"Pricing";
		[self showPopoverControl:localPricingController inRect:cmdPricing.frame];
	}
}

-(IBAction) cmdMisc_click:(id)sender
{
	self.miscController = [[[MiscItemsController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	miscController.title = @"Misc Items";
	[self showPopoverControl:miscController inRect:cmdMisc.frame];
}

-(IBAction) cmdComments_click:(id)sender
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	NSString *note;
	//load the note controller with the customer note.
	note = [del.surveyDB getCustomerNote:del.customerID];
	self.noteViewController = [[[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	noteViewController.caller = self;
	noteViewController.callback = @selector(noteChanged:);
	noteViewController.destString = note;
	noteViewController.description = @"Comments";
	noteViewController.navTitle = @"Comments";
	noteViewController.keyboard = UIKeyboardTypeASCIICapable;
	noteViewController.dismiss = YES;
	noteViewController.noteType = NOTE_TYPE_CUSTOMER;
	[note release];
	noteViewController.popover = [self showPopoverControl:noteViewController inRect:cmdComments.frame];
}

-(void) noteChanged:(NSString*)newNote
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del.surveyDB updateCustomerNote:del.customerID withNote:newNote];
}

-(IBAction) cmdAccessorials_click:(id)sender
{
	self.interstateAccessorialsController = [[[InterstateAccessorialsController alloc] initWithNibName:@"InterstateAccessorialsView" bundle:nil] autorelease];
	interstateAccessorialsController.locationID = -1;
	[self showPopoverControl:interstateAccessorialsController inRect:cmdAccessorials.frame];
}

-(IBAction) cmdPackSummary_click:(id)sender
{
	self.packSummary = [[[PackSummaryController alloc] initWithNibName:@"PackSummaryView" bundle:nil] autorelease];
	packSummary.title = @"Pack Summary";
	[self showPopoverControl:packSummary inRect:cmdPackSummary.frame];
}

-(IBAction) cmdTotal_click:(id)sender
{
	cmdTotals.enabled = FALSE;
	self.summaryController = [[[PriceSummaryController alloc] initWithNibName:@"PriceSummaryView" bundle:nil] autorelease];
	summaryController.title = @"Price Summary";
	[self showPopoverControl:summaryController inRect:CGRectMake(0, 0, 0, 0) fromBarButton:cmdTotals];
	
	cmdClose.enabled = FALSE;
	segmentView.enabled = FALSE;
}

-(IBAction) cmdCubesheet_click:(id)sender
{
	UISegmentedControl *ctl = nil;
	if([sender class] == [UISegmentedControl class])
	{
		ctl=sender;
		if([ctl selectedSegmentIndex] == 0)
			return;
	}
	
	[self saveScreen];
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	SurveyCustomer *cust = [del.surveyDB getCustomer:del.customerID];
	if(cust.weight > 0)
	{
		ctl.selectedSegmentIndex = 0;
		[SurveyAppDelegate showAlert:@"Survey has been disabled since this move has a weight override applied." withTitle:@"Survey Disabled"];
		[cust release];
		return;
	}
	[cust release];
	
	if(parent != nil)
		[parent changeView:CONTENT_CUBESHEET];
	
	if(ctl != nil)
		ctl.selectedSegmentIndex = 0;
}

-(IBAction) cmdCubesheetSummary_click:(id)sender
{
	if(csSummaryController == nil)
	{
		csSummaryController = [[SurveySummaryController alloc] initWithNibName:@"SurveySummaryView" bundle:nil];
		csSummaryController.title = @"Room Summary";
		csSummaryController.caller = self;
		CGRect newRect = csSummaryController.view.frame;
		newRect.size.height -= csSummaryController.toolbar.frame.size.height;
		[csSummaryController.toolbar removeFromSuperview];
		csSummaryController.view.frame = newRect;
		csSummaryController.tblView.frame = newRect;
		csSummaryController.contentSizeForViewInPopover = CGSizeMake(320, 44*6);
		[csSummaryController.pickerWeightFactor removeFromSuperview];
		csSummaryController.navigationItem.rightBarButtonItem = nil;
	}
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	csSummaryController.cubesheet = [[del.surveyDB openCubeSheet:del.customerID] autorelease];
	
	csSummaryController.popover = [self showPopoverControl:csSummaryController inRect:cmdCubesheetSummary.frame];
}

-(IBAction) cmdEmail_click:(id)sender
{
	if([tboxEmail.text isEqualToString:@""])
	{
		[SurveyAppDelegate showAlert:@"You must have an address entered to send an email." withTitle:@"Address Required"];
		return;
	}
	
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Send email to %@?", tboxEmail.text]
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Yes", @"Cancel", nil];
	[sheet showInView:self.scroller];
	[sheet release];
}

-(void) pickerValueChanged:(NSNumber*)newNumber
{
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	if(tboxCurrent == tboxTariff)
	{
		if(customer.pricingMode != [newNumber intValue] || [del.pricingDB isUnigroup] || [del.pricingDB vanline] == BEKINS)
		{
			
			[self saveScreen];
			SurveyCustomer *cust =[del.surveyDB getCustomer:del.customerID];
			cust.pricingMode = [newNumber intValue] == 2 ? 0 : [newNumber intValue];
			[del.surveyDB updateCustomer:cust];
			[cust release];
			
			ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
			
			if([del.pricingDB isUnigroup] && [newNumber intValue] == 2 && 
			   (info.type != WEIGHT_ALLOWANCE && info.type != NO_WEIGHT_ALLOWANCE))
			{
				inf.type = WEIGHT_ALLOWANCE;
			}
			else if([del.pricingDB isUnigroup] && [newNumber intValue] == 0 && info.type != NON_BINDING)
			{
				ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
				inf.type = NON_BINDING;
			}
		
			if([del.pricingDB vanline] == BEKINS && [newNumber intValue] != 1)
			{
				inf.bekins412 = [newNumber intValue] == 0;
				//if(inf.bekins412)
				//	inf.type = GUARANTEED;
			}
			
			[del.surveyDB updateShipInfo:inf];
			[inf release];
			
			tboxTariff.text = [pricingModes objectForKey:newNumber];
			[self initializeScreen];
		}
	}
	else if(tboxCurrent == tboxEstimateType)
	{
		if([del.pricingDB isUnigroup] && customer.pricingMode == 0 && info.type == NON_BINDING && 
		   ([newNumber intValue] == WEIGHT_ALLOWANCE || [newNumber intValue] == NO_WEIGHT_ALLOWANCE))
			[SurveyAppDelegate showAlert:@"Only Non-Binding allowed in non-GPP pricing mode." withTitle:@"Non-Binding Type Required"];
		else if([del.pricingDB isUnigroup] && customer.pricingMode == 0 && [newNumber intValue] == NON_BINDING && 
				(info.type == WEIGHT_ALLOWANCE || info.type == NO_WEIGHT_ALLOWANCE))
			[SurveyAppDelegate showAlert:@"Only Weight Allowance and No Weight Allowance allowed in GPP pricing mode." withTitle:@"GPP Type Required"];
		else
		{
			info.type = [newNumber intValue];
			tboxEstimateType.text = [estimateTypes objectForKey:newNumber];
		}
	}
	else if(tboxCurrent == tboxJobStatus)
	{
		info.status = [newNumber intValue];
		tboxJobStatus.text = [jobStatuses objectForKey:newNumber];
	}
	else if(tboxCurrent == tboxValDed)
	{
		if(customer.pricingMode == 0)
		{
			pricing.valuationDed = [newNumber intValue];
			tboxValDed.text = [valDeds objectForKey:newNumber];
			tboxValAmt.hidden = pricing.valuationDed == SIXTY_CENTS;
			labelValAmt.hidden = pricing.valuationDed == SIXTY_CENTS;
			if([CustomerUtilities getValuationMinimum] >= pricing.valuationAmount)
			{
				pricing.valuationAmount = [CustomerUtilities getValuationMinimumFromDB];
				tboxValAmt.text = [valAmts objectForKey:[NSNumber numberWithDouble:pricing.valuationAmount]];
			}
		}
		else 
		{
			localPricing.valDed = [newNumber intValue];
			tboxValDed.text = [valDeds objectForKey:newNumber];
			tboxValAmt.hidden = localPricing.valDed == SIXTY_CENTS;
			labelValAmt.hidden = localPricing.valDed == SIXTY_CENTS;
			double valmin = [CustomerUtilities getLocalValuationMinimum:localPricing.valDed];
			if(valmin != 0.0 && valmin >= pricing.valuationAmount)
			{
				localPricing.valAmt = valmin;
				tboxValAmt.text = [SurveyAppDelegate formatCurrency:localPricing.valAmt];
			}
		}

	}
	else if(tboxCurrent == tboxValAmt)
	{
		if(customer.pricingMode == 0)
		{
			if([CustomerUtilities getValuationMinimum] >= [newNumber doubleValue])
			{
				pricing.valuationAmount = [CustomerUtilities getValuationMinimumFromDB];
				tboxValAmt.text = [valAmts objectForKey:[NSNumber numberWithDouble:pricing.valuationAmount]]; 
				[SurveyAppDelegate showAlert:
				 [NSString stringWithFormat:@"The valuation amount selected was below the minimum of $%@ The minimum has been set.", 
				  [SurveyAppDelegate formatDouble:[CustomerUtilities getValuationMinimum]]] 
								   withTitle:@"Minimum Valuation"];
			}
			else
			{
				pricing.valuationAmount = [newNumber doubleValue];
				tboxValAmt.text = [valAmts objectForKey:newNumber];
			}
		}
		else
		{
			localPricing.valAmt = [newNumber doubleValue];
			tboxValAmt.text = [SurveyAppDelegate formatCurrency:localPricing.valAmt];
		}
	}
}


-(void)viewWillDisappear:(BOOL)animated
{
	CGRect newFrame = scroller.frame;
	newFrame.size.height = 960;
	scroller.frame = newFrame;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {

	[customer release];
	[info release];
	[pricing release];
	[localPricing release];
	[pricingModes release];
	[basicInfoController release];
	[popoverHolder release];
	[datesController release];
	[currentPopover release];
	[estimateTypes release];
	[jobStatuses release];
	[valDeds release];
	[valAmts release];
	[leadSources release];
	[currentZip release];
	[imageViewer release];
	
	[surveySummaryController release];
	[locationController release];
	[agentsController release];
	[infoController release];
	[pricingController release];
	[summaryController release];
	[miscController release];
	[packSummaryController release];
	[localPricingController release];
	[interstateAccessorialsController release];
	[packSummary release];
	[csSummaryController release];
	[noteViewController release];
	[tboxCurrent release];
	[phonesController release];
	[accessorialList release];
	[packingList release];
	
	[scroller release];
	
	//detail buttons
	[cmdBasicInfo release];
	[cmdOriginInfo release];
	[cmdDestinationInfo release];
	[cmdDates release];
	[cmdMoveInfo release];
	[cmdAgents release];
	[cmdPricing release];
	[cmdMisc release];
	[cmdComments release];
	[cmdAccessorials release];
	[cmdPackSummary release];
	[cmdCubesheetSummary release];
	[cmdTotals release];
	[cmdCustomerName release];
	[cmdClose release];
	[segmentView release];
	
	//basic info
	[tboxFirstName release];
	[tboxLastName release];
	[tboxEmail release];
	[cmdEmail release];
	
	//origin info
	[tboxOrigAdd1 release];
	[tboxOrigAdd2 release];
	[tboxOrigCity release];
	[tboxOrigState release];
	[tboxOrigZip release];
	[tboxOrigPhones release];
	
	//destination info
	[tboxDestAdd1 release];
	[tboxDestAdd2 release];
	[tboxDestCity release];
	[tboxDestState release];
	[tboxDestZip release];
	[tboxDestPhones release];
	
	//dates
	[tboxDatePackFrom release];
	[tboxDatePackTo release];
	[tboxDateLoadFrom release];
	[tboxDateLoadTo release];
	[tboxDateDeliverFrom release];
	[tboxDateDeliverTo release];
	[tboxDateSurvey release];
	[tboxDateSurveyTime release];
	[tboxDateFollowUp release];
	[tboxDateDecision release];
	
	//move info
	[tboxTariff release];
	[tboxMiles release];
	[tboxLeadSource release];
	[tboxEstimateType release];
	[tboxJobStatus release];
	[tboxOrderNumber release];
	
	//agents info
	[labelBookingName release];
	[labelBookingAddress release];
	[labelBookingCSZ release];
	[labelBookingPhone release];
	[labelOriginName release];
	[labelOriginAddress release];
	[labelOriginCSZ release];
	[labelOriginPhone release];
	[labelDestinationName release];
	[labelDestinationAddress release];
	[labelDestinationCSZ release];
	[labelDestinationPhone release];
	
	//survey summary
	[labelSurveySummary release];
	
	//pricing info
	[tboxValDed release];
	[tboxValAmt release];
	[chkPricePacking release];
	[tboxDateEffective release];
	[labelDiscBL release];
	[tboxDiscBL release];
	[labelValAmt release];
	
	[tboxComments release];
	[labelMiscHeader release];
	
	//summaries
	[tableAccSummary release];
	[tablePackSummary release];
	
	[parent release];
	
    [super dealloc];
}

#pragma mark UIPopoverControllerDelegate methods

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
	return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[popoverHolder viewWillDisappear:NO];
	cmdTotals.enabled = TRUE;
	cmdClose.enabled = TRUE;
	segmentView.enabled = TRUE;
	//load any changes from the breakout...
	[self initializeScreen];
}

#pragma mark UITextViewDelegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if(tboxComments == textView)	
	{
		[scroller scrollRectToVisible:tboxComments.frame animated:YES];
	}
}

#pragma mark UITextFieldDelegate methods

//any fields with this set as their delegate are non-editable, they will be edited via popups (dates, phones)
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	if(textField == tboxOrigZip || textField == tboxDestZip)
	{
		self.currentZip = textField.text;
		return YES;
	}
	
	SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
	self.tboxCurrent = textField;
	
	if(textField == tboxOrigPhones || textField == tboxDestPhones)
	{
		self.phonesController = [[[LocationPhonesController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		phonesController.title = textField == tboxOrigPhones ? @"Origin Phones" : @"Destination Phones";
		phonesController.custID = del.customerID;
		phonesController.locationID = textField == tboxOrigPhones ? ORIGIN_LOCATION_ID : DESTINATION_LOCATION_ID;
		[self showPopoverControl:phonesController inRect:textField.frame];
	}
	else if(textField == tboxTariff)
	{
		//show tariff options
		[del popiPadPickerViewController:@"Pricing Mode" 
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:pricingModes 
					withCurrentSelection:[NSNumber numberWithInt:customer.pricingMode]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
	}
	else if(textField == tboxEstimateType)
	{
		[del popiPadPickerViewController:@"Estimate Type" 
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:estimateTypes 
					withCurrentSelection:[NSNumber numberWithInt:info.type]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
		
	}
	else if(textField == tboxJobStatus)
	{
		[del popiPadPickerViewController:@"Job Status" 
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:jobStatuses 
					withCurrentSelection:[NSNumber numberWithInt:info.status]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
		
	}
	else if(textField == tboxValDed)
	{
		[del popiPadPickerViewController:@"Valuation Deductible"
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:valDeds 
					withCurrentSelection:[NSNumber numberWithInt:customer.pricingMode == 0 ? pricing.valuationDed : localPricing.valDed]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
		
	}
	else if(textField == tboxValAmt)
	{
		[del popiPadPickerViewController:[NSString stringWithFormat:@"Min: $%@",
										  [del.doubleDecFormatter stringFromDouble:[CustomerUtilities getValuationMinimum]]]
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:valAmts 
					withCurrentSelection:[NSNumber numberWithInt:pricing.valuationAmount]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
		
	}
	else if(textField == tboxLeadSource)
	{
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		for(int i = 0; i < [leadSources count]; i++)
		{
			[dict setObject:[leadSources objectAtIndex:i] forKey:[leadSources objectAtIndex:i]];
		}
		[del popiPadPickerViewController:@"Lead Source"
								  inView:scroller 
								fromRect:tboxCurrent.frame 
							 withObjects:dict 
					withCurrentSelection:[NSNumber numberWithInt:-1]
							  withCaller:self 
							 andCallback:@selector(pickerValueChanged:)];
		[dict release];
	}
	else if(textField == tboxDateSurveyTime)
	{//time
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"h:m a"];
		NSDate *time = [formatter dateFromString:tboxDateSurveyTime.text];
		/*//take the time interval, which is gmt, and add the current time zome seconds from gmt, then adjust by an hour (not sure why, but it worked?)
		dates.survey = [dates.survey addTimeInterval:([time timeIntervalSince1970]+[[NSTimeZone systemTimeZone] secondsFromGMT])-3600];*/
		[formatter release];
		[del popiPadSingleDateViewController:time
									  inView:self.scroller 
									fromRect:textField.frame 
								withNavTitle:@"Select Time" 
								  withCaller:self 
								 andCallback:@selector(dateChanged:withIgnore:)
									  isDate:NO];
	}
	else 
	{//dates
		[del popiPadSingleDateViewController:[SurveyAppDelegate prepareDate:textField.text]
									  inView:self.scroller 
									fromRect:textField.frame 
								withNavTitle:@"Select Date" 
								  withCaller:self 
								 andCallback:@selector(dateChanged:withIgnore:)];
	}

	
	return NO;
}

//used for the zips to regenerate mileage
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if((textField == tboxOrigZip || textField == tboxDestZip) && 
	   ![currentZip isEqualToString:textField.text] && 
	   [textField.text length] >= 3)
	{//zip changed, and greater than 3 digits
		SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
		SurveyLocation *loc;
		if(textField == tboxOrigZip)
		{
			loc = [del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID];
			loc.zip = textField.text;
			[del.surveyDB updateLocation:loc];
			[loc release];
			//check dest to make sure of three chars
			if([[[[del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID] autorelease] zip] length] < 3)
				return;
		}
		else if(textField == tboxDestZip)
		{
			loc = [del.surveyDB getCustomerLocation:del.customerID withType:DESTINATION_LOCATION_ID];
			loc.zip = textField.text;
			[del.surveyDB updateLocation:loc];
			[loc release];
			//check dest to make sure of three chars
			if([[[[del.surveyDB getCustomerLocation:del.customerID withType:ORIGIN_LOCATION_ID] autorelease] zip] length] < 3)
				return;
		}
		
		if([CustomerUtilities intraHasDefaultMileage])
			tboxMiles.text = [NSString stringWithFormat:@"%d", [CustomerUtilities intraDefaultMileage]];
		else
			tboxMiles.text = [NSString stringWithFormat:@"%d", [CustomerUtilities getMileage]];
		
	}
}


#pragma mark action sheet stuff

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
		if(actionSheet.tag == ACTION_SHEET_DUPLICATE)
		{
			//copy the current customer...
			SurveyAppDelegate *del = [[UIApplication sharedApplication] delegate];
			[del.surveyDB copyCustomer:del.customerID];
		}
		else
		{
			if(buttonIndex == 0)
			{//yes, send the email...
				//save
				[self saveScreen];
				
				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", tboxEmail.text]];
				
				if([[UIApplication sharedApplication] canOpenURL:url])
					[[UIApplication sharedApplication] openURL:url];
				else
					[SurveyAppDelegate showAlert:@"Your device does not support this type of functionality." withTitle:@"Error"];
			}
		}
	}
}


#pragma mark Table Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 1;
}

-(NSInteger)tableView: (UITableView *)thisTableView numberOfRowsInSection: (NSInteger)section
{
	if(thisTableView == tableAccSummary)
		return [accessorialList count];
	else
		return [packingList count];
}

-(UITableViewCell*)tableView: (UITableView *)thisTableView 
	   cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
	static NSString *BasicCellID = @"BasicCellID";
	static NSString *PackSummaryCellID = @"CustomerDetailPackSumCell";
	UITableViewCell *cell = nil;
	CustomerDetailPackSumCell *packCell = nil;
	
	NSUInteger row = [indexPath row];
	
	if(thisTableView == tableAccSummary)
	{
		cell = [thisTableView dequeueReusableCellWithIdentifier:BasicCellID];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicCellID] autorelease];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.font = tboxFirstName.font;
		}
		
		cell.textLabel.text = [accessorialList objectAtIndex:row];
	}
	else
	{
		packCell = (CustomerDetailPackSumCell *)[thisTableView dequeueReusableCellWithIdentifier:PackSummaryCellID];
		
		if (packCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomerDetailPackSumCell" owner:self options:nil];
			packCell = [nib objectAtIndex:0];
		}
		
		PackSummaryItem *packItem;
		PackSummaryCrateItem *crateItem;
		if([[packingList objectAtIndex:row] class] == [PackSummaryItem class])
		{
			packCell.labelPBO.hidden = NO;
			packItem = [packingList objectAtIndex:row];
			packCell.labelName.text = packItem.name;
			packCell.labelCP.text = [NSString stringWithFormat:@"CP: %d", packItem.cpCount];
			packCell.labelPBO.text = [NSString stringWithFormat:@"PBO: %d", packItem.pboCount];
		}
		else 
		{
			packCell.labelPBO.hidden = YES;
			CGRect rect = packCell.labelCP.frame;
			rect.size.width += packCell.labelPBO.frame.size.width;
			packCell.labelCP.frame = rect;
			
			crateItem = [packingList objectAtIndex:row];
			if(crateItem.si.shipping > 1)
				packCell.labelName.text = [NSString stringWithFormat:@"%@ (%d)", crateItem.si.item.name, crateItem.si.shipping];
			else
				packCell.labelName.text = crateItem.si.item.name;
			packCell.labelCP.text = [NSString stringWithFormat:@"(%d x %d x %d), %@ cf", 
									 crateItem.dims.length, crateItem.dims.width, crateItem.dims.height,
									 [Item formatCube:crateItem.si.cube]];
		}
	}
	
	return cell != nil ? cell : (UITableViewCell*)packCell;
	
}

#pragma mark -
#pragma mark Table View Delegate Methods

-(CGFloat) tableView: (UITableView*)tv
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return 35;
}


-(void)tableView: (UITableView*)thisTableView
didSelectRowAtIndexPath: (NSIndexPath*)indexPath
{
	[thisTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
	if(tv == tableAccSummary && [accessorialList count] == 0)
		return @"No Accessorials have been added to this estimate.";
	else if(tv == tablePackSummary && [packingList count] == 0)
		return @"No Packing Items have been added to this estimate.";
	
	return nil;
}


@end
