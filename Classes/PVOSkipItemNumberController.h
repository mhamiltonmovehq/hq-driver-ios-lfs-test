//
//  PVOSkipItemNumberController.h
//  Survey
//
//  Created by Brian Prescott on 5/13/13.
//
//

#import <UIKit/UIKit.h>

@interface PVOSkipItemNumberController : UIViewController
{
}

@property (nonatomic, strong) NSString *defaultLotNumber;
@property (nonatomic) int custID;

@property (nonatomic, strong) IBOutlet UITextField *lotNumberField;
@property (nonatomic, strong) IBOutlet UITextField *itemNumberField;

@property (nonatomic, strong) NSString *selectedLotNumber;
@property (nonatomic, strong) NSString *selectedItemNumber;

@end
