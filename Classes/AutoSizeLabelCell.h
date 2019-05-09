//
//  MenuItemCell.h
//  RestaurantTemplate
//
//  Created by Tony Brame on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoSizeLabelCell : UITableViewCell
{
    IBOutlet UILabel *labelDescription;
    
    NSString *text;
}

+(float)sizeOfCellForText:(NSString*)text;

@property (nonatomic, retain) IBOutlet UILabel *labelDescription;
@property (nonatomic, retain) IBOutlet NSString *text;

@end
