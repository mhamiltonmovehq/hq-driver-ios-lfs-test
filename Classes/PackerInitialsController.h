//
//  PackerInitialsController.h
//  Survey
//
//  Created by Tony Brame on 4/15/13.
//
//

#import <UIKit/UIKit.h>

@interface PackerInitialsController : UITableViewController
{
    NSMutableArray *initials;
    BOOL isModal;
}

@property (nonatomic) BOOL isModal;

-(IBAction)addPackerInitials:(id)sender;

@end
