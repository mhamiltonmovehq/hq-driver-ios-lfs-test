//
//  SurveyAgentsController.h
//  Survey
//
//  Created by Tony Brame on 7/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditAgentController.h"

@interface SurveyAgentsController : UITableViewController {
	EditAgentController *editAgentController;
}

@property (nonatomic, retain) EditAgentController *editAgentController;

@end
