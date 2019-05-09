//
//  PVOItemDetailExtended.h
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOItemDetail.h"

@interface PVOItemDetailExtended : PVOItemDetail
{
    NSMutableArray *cartonContentsDetail;
    NSMutableArray *descriptiveSymbols;
    NSMutableArray *damageDetails;
    NSMutableArray *itemCommentDetails;
}

@property (nonatomic, retain) NSMutableArray *cartonContentsDetail;
@property (nonatomic, retain) NSMutableArray *descriptiveSymbols;
@property (nonatomic, retain) NSMutableArray *damageDetails;
@property (nonatomic, retain) NSMutableArray *itemCommentDetails;

@end
