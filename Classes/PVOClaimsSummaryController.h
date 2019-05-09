//
//  PVOClaimsSummaryController.h
//  Survey
//
//  Created by Tony Brame on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOClaim.h"
#import "PVOEditClaimController.h"

@interface PVOClaimsSummaryController : UITableViewController
{
    NSMutableArray *claims;
    PVOEditClaimController *editController;
}

@property (nonatomic, strong) NSMutableArray *claims;
@property (nonatomic, strong) PVOEditClaimController *editController;

-(IBAction)cmdAdd_Click:(id)sender;
-(void)loadClaim:(PVOClaim*)pvoClaim;

@end
