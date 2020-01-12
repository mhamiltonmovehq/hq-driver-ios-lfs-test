//
//  CrewCell.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 1/12/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CrewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelType;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

NS_ASSUME_NONNULL_END
