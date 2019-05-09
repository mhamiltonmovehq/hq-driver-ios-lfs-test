//
//  PVOSkipItemNumberController.m
//  Survey
//
//  Created by Brian Prescott on 5/13/13.
//
//

#import "PVOSkipItemNumberController.h"
#import "SurveyAppDelegate.h"

@implementation PVOSkipItemNumberController

@synthesize defaultLotNumber, custID, lotNumberField, itemNumberField, selectedLotNumber, selectedItemNumber;

#pragma mark - Button presses

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender
{
    self.selectedLotNumber = lotNumberField.text;
    self.selectedItemNumber = itemNumberField.text;

    if ([selectedLotNumber length] == 0 || [selectedItemNumber length] == 0)
    {
        [SurveyAppDelegate showAlert:@"Please enter a valid lot number and item number before tapping the Done button." withTitle:@"Invalid lot and/or item number"];
        return;
    }
    
    if ([itemNumberField isFirstResponder])
        [itemNumberField resignFirstResponder];
    if ([lotNumberField isFirstResponder])
        [lotNumberField resignFirstResponder];

    NSString *msg = [NSString stringWithFormat:@"Are you sure you want to skip item number %@ in lot number %@? (This will adjust any item numbers higher than the entered item number.)", selectedItemNumber, selectedLotNumber];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:msg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [av show];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        int selectedItemNumberValue = [selectedItemNumber intValue];
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        SmallProgressView *progress = [[SmallProgressView alloc] initWithDefaultFrame:[NSString stringWithFormat:@"Skipping %@%@...", selectedLotNumber, selectedItemNumber] andProgressBar:YES];
        dispatch_async(dispatch_queue_create([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL), ^{
            NSArray *items = [del.surveyDB getPVOAllItems:custID lotNumber:selectedLotNumber];
            //sort them in the proper order, since the user may not have created them in order
            items = [items sortedArrayUsingSelector:@selector(compareWithItemNumberAndLot:)];
            //work backwards since the pvoItemExists method needs to be sated before a save can occur...
            for (int i = items.count-1; i >= 0; i--) {
                PVOItemDetail *item = [items objectAtIndex:i];
                int itemNumberValue = [item.itemNumber intValue];
                if (itemNumberValue >= selectedItemNumberValue)
                {
                    item.itemNumber = [PVOItemDetail paddedItemNumber:[NSString stringWithFormat:@"%d", (itemNumberValue + 1)]];
                    [del.surveyDB updatePVOItem:item];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progress updateProgressBar:((items.count-i) / (1. * items.count))];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [progress removeFromSuperview];
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        });
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(done:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self
                                                                                            action:@selector(cancel:)];
    self.title = @"Skip Item Number";
}

- (void)viewDidAppear:(BOOL)animated
{
    lotNumberField.text = defaultLotNumber;
    [itemNumberField becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
