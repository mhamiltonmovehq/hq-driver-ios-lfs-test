//
//  EditAgentController.h
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SurveyAgent.h"
#import "SingleFieldController.h"
#import "SelectNewAgencyController.h"
#import "PVOBaseTableViewController.h"

#define STATE_FILTER_SECTION 0
#define AGENT_INFO_SECTION 1

#define AGENT_CODE_ROW 0
#define AGENT_NAME_ROW 1
#define AGENT_ADDRESS_ROW 2
#define AGENT_CITY_ROW 3
#define AGENT_STATE_ROW 4
#define AGENT_ZIP_ROW 5
#define AGENT_PHONE_ROW 6
#define AGENT_EMAIL_ROW 7
#define AGENT_CONTACT_ROW 8

@interface EditAgentController : PVOBaseTableViewController {
	SurveyAgent *agent;
	NSString *currentState;
	NSIndexPath *editingPath;
	SingleFieldController *editController;
	SelectNewAgencyController *selectAgentController;
	BOOL editing;
    BOOL lockFields;
}

@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL lockFields;

@property (nonatomic, retain) SurveyAgent *agent;
@property (nonatomic, retain) NSString *currentState;
@property (nonatomic, retain) NSIndexPath *editingPath;
@property (nonatomic, retain) SingleFieldController *editController;
@property (nonatomic, retain) SelectNewAgencyController *selectAgentController;

-(void) doneEditing:(NSString*)newValue;

-(void) newAgentSelected:(SurveyAgent*)newAgent;

-(IBAction)cmd_DefaultPressed:(id)sender;

@end
