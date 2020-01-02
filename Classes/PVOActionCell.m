//
//  PVOActionCell.m
//  Mobile Mover
//
//  Created by Matthew Hamilton on 12/30/19.
//

#import "PVOActionCell.h"

@implementation PVOActionCell
@synthesize labelDate, labelAction, buttonAction;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    buttonAction.layer.cornerRadius = 10; // this value vary as per your desire
    buttonAction.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setActionTime:(NSDate * _Nonnull)actionTime
{
    _actionTime = actionTime;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, yyyy"];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"hh:mm a"];
    
    [labelDate setText:[NSString stringWithFormat:@"%@ at %@", [dateFormatter stringFromDate:_actionTime], [timeFormatter stringFromDate:_actionTime]]];
    
    // If there is not an action date/time, then we only display the button to start
    //   if there IS an action date/time, do the opposite
    bool isDateSet = (_actionTime == nil || [_actionTime isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]]) ? NO : YES;
       
    labelAction.hidden = !isDateSet;
    labelDate.hidden = !isDateSet;
    buttonAction.hidden = isDateSet;
}

- (IBAction)performAction:(id)sender
{
    [self setActionTime:[NSDate date]];
    
    if(_delegate != nil && [_delegate respondsToSelector:_callback])
    {
        [_delegate performSelector:_callback withObject:_actionTime];
    }
}

@end
