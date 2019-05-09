//
//  PVOClaimItemDetailController.m
//  Survey
//
//  Created by Tony Brame on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PVOClaimItemDetailController.h"
#import "SurveyAppDelegate.h"
#import "NoteCell.h"
#import "LabelTextCell.h"

@implementation PVOClaimItemDetailController

@synthesize item, tboxCurrent, tviewCurrent;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Claim Item Detail";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)updateValueWithTextView:(UITextView*)tbox
{
    item.description = tbox.text;
}

-(void)updateValueWithField:(UITextField*)tbox
{
    
    if(tbox.tag == PVO_CLAIM_ITEM_WEIGHT)
        item.estimatedWeight = [tbox.text intValue];
    else if(tbox.tag == PVO_CLAIM_ITEM_AGE)
        item.ageOrDatePurchased = tbox.text;
    else if(tbox.tag == PVO_CLAIM_ITEM_ORIGINAL_COST)
        item.originalCost = [tbox.text doubleValue];
    else if(tbox.tag == PVO_CLAIM_ITEM_REPLACEMENT_COST)
        item.replacementCost = [tbox.text doubleValue];
    else if(tbox.tag == PVO_CLAIM_ITEM_REPAIR_COST)
        item.estimatedRepairCost = [tbox.text doubleValue];
}
-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if(tviewCurrent != nil)
        [self updateValueWithTextView:tviewCurrent];
    
    [del.surveyDB savePVOClaimItem:item];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return section == 0 ? 3 : 7
    ;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
        return 30;
    else if(indexPath.row == PVO_CLAIM_ITEM_DAMAGE_DESCRIPTION)
        return 130;
    else
        return 44;
        
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *NoteCellIdentifier = @"NoteCell";
    static NSString *TextCellIdentifier = @"LabelTextCell";
    
    UITableViewCell *cell = nil;
    LabelTextCell *ltCell = nil;
    NoteCell *noteCell = nil;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    int row = indexPath.row;
    
    if(indexPath.section == 0 || 
       (indexPath.section == 1 && row == PVO_CLAIM_ITEM_IMAGES))
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        if(indexPath.section == 1 && row == PVO_CLAIM_ITEM_IMAGES)
        {
            UIImage *myimage = [SurveyImageViewer getDefaultImage:IMG_PVO_CLAIM_ITEMS forItem:item.pvoClaimItemID];
            if(myimage == nil)
                myimage = [UIImage imageNamed:@"img_photo.png"];
            cell.textLabel.text = @"Manage Photos";
            cell.imageView.image = myimage;
        }
        else if(row == PVO_CLAIM_ITEM_NUMBER)
        {
            PVOItemDetail *pid= [del.surveyDB getPVOItem:item.pvoItemID];
            cell.textLabel.text = [NSString stringWithFormat:@"Item: %@", [pid displayInventoryNumber]];
        }
        else if(row == PVO_CLAIM_ITEM_ROOM)
        {
            PVOItemDetail *pid= [del.surveyDB getPVOItem:item.pvoItemID];
            Room *r = [del.surveyDB getRoom:pid.roomID WithCustomerID:del.customerID];
            cell.textLabel.text = [NSString stringWithFormat:@"Room: %@", r.roomName];
        }
        else if(row == PVO_CLAIM_ITEM_NAME)
        {
            PVOItemDetail *pid= [del.surveyDB getPVOItem:item.pvoItemID];
            Item *i = [del.surveyDB getItem:pid.itemID WithCustomer:del.customerID];
            cell.textLabel.text = [NSString stringWithFormat:@"Name: %@", i.name];
        }
    }
    else if(row == PVO_CLAIM_ITEM_DAMAGE_DESCRIPTION)
    {
        noteCell = (NoteCell*)[tableView dequeueReusableCellWithIdentifier:NoteCellIdentifier];
        if (noteCell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NoteCell" owner:self options:nil];
            noteCell = [nib objectAtIndex:0];
            noteCell.tboxNote.delegate = self;
        }
        
        noteCell.tboxNote.tag = row;
        
    }
    else
    {
		ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
		if (ltCell == nil) {
			NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
			ltCell = [nib objectAtIndex:0];
			[ltCell.tboxValue addTarget:self 
								 action:@selector(textFieldDoneEditing:) 
					   forControlEvents:UIControlEventEditingDidEndOnExit];
			ltCell.tboxValue.delegate = self;
            ltCell.tboxValue.returnKeyType = UIReturnKeyDone;
            ltCell.tboxValue.font = [UIFont systemFontOfSize:17.];
            [ltCell setPVOView];
		}
        ltCell.tboxValue.keyboardType = UIKeyboardTypeDecimalPad;
        
        ltCell.tboxValue.tag = row;
        
        if(row == PVO_CLAIM_ITEM_WEIGHT)
        {
            ltCell.labelHeader.text = @"Est. Weight";
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", item.estimatedWeight];
        }
        else if(row == PVO_CLAIM_ITEM_AGE)
        {
            ltCell.tboxValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            ltCell.labelHeader.text = @"Age/Date Purchased";
            ltCell.tboxValue.text = item.ageOrDatePurchased;
        }
        else if(row == PVO_CLAIM_ITEM_ORIGINAL_COST)
        {
            ltCell.labelHeader.text = @"Original Cost";
            ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:item.originalCost];
        }
        else if(row == PVO_CLAIM_ITEM_REPLACEMENT_COST)
        {
            ltCell.labelHeader.text = @"Replacement Cost";
            ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:item.replacementCost];
        }
        else if(row == PVO_CLAIM_ITEM_REPAIR_COST)
        {
            ltCell.labelHeader.text = @"Repair Cost";
            ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:item.estimatedRepairCost];
        }
        
    }
    
    
    return cell != nil ? cell : ltCell != nil ? ltCell : noteCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section == 1 && indexPath.row == PVO_CLAIM_ITEM_IMAGES)
    {
        if(imageViewer == nil)
            imageViewer = [[SurveyImageViewer alloc] init];
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
        imageViewer.photosType = IMG_PVO_CLAIM_ITEMS;
        imageViewer.customerID = del.customerID;
        imageViewer.subID = item.pvoClaimItemID;
        
        imageViewer.caller = self.view;
        
        imageViewer.viewController = self;
        
        [imageViewer loadPhotos];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(tboxCurrent != nil)
        [tboxCurrent resignFirstResponder];
    if(tviewCurrent != nil)
        [tviewCurrent resignFirstResponder];
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
}

#pragma mark UITextViewDelegate methods

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.tviewCurrent = textView;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    [self updateValueWithTextView:textView];
}


@end
