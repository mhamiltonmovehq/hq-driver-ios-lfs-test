//
//  RoomSummaryCell.h
//  Survey
//
//  Created by Tony Brame on 5/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RoomSummaryCell : UITableViewCell {
	IBOutlet	UILabel *labelRoomName;
	IBOutlet	UILabel *labelSummary;
	IBOutlet	UIButton *cmdImages;
}

@property (nonatomic, strong) UILabel *labelRoomName;
@property (nonatomic, strong) UILabel *labelSummary;
@property (nonatomic, strong) UIButton *cmdImages;
@property (strong, nonatomic) IBOutlet UIImageView *imgPhoto;

-(void)setImage:(UIImage *)image;

@end
