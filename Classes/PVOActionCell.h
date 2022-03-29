//
//  PVOActionCell.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface PVOActionCell : UITableViewCell {
    
    IBOutlet UILabel *labelAction;
    IBOutlet UILabel *labelDate;
    IBOutlet UIButton *buttonAction;
}

@property (nonatomic, retain) UILabel *labelAction;
@property (nonatomic, retain) UILabel *labelDate;
@property (nonatomic, retain) UIButton *buttonAction;
@property (nonatomic, retain) NSDate *actionTime;
@property (nonatomic) id delegate;
@property (nonatomic) SEL callback;

- (void) setActionTime:(NSDate * _Nonnull)actionTime;
- (IBAction)performAction:(id)sender;

@end

NS_ASSUME_NONNULL_END
