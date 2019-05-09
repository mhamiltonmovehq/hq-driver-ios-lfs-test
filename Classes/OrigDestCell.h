//
//  OrigDestCell.h
//  Survey
//
//  Created by Tony Brame on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ORIG_DEST_ORIGIN 0
#define ORIG_DEST_DESTINATION 1

@interface OrigDestCell : UITableViewCell {
    IBOutlet UISegmentedControl *segmentOrigDest;
}

@property (nonatomic, strong) UISegmentedControl *segmentOrigDest;

@end
