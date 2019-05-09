//
//  PVONewCartonContentsController.m
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVONewCartonContentsController.h"
#import "SurveyAppDelegate.h"
#import "TextCell.h"

@implementation PVONewCartonContentsController

@synthesize content, tboxCurrent, delegate;

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
                                                                                            target:self 
                                                                                            action:@selector(saveItem:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                            target:self 
                                                                                            action:@selector(cancel:)];
    
}

-(IBAction)saveItem:(id)sender
{
    if(tboxCurrent != nil)
        [self updateValueWithField:tboxCurrent];
    
    if(content.description == nil || [content.description isEqualToString:@""])
    {
        [SurveyAppDelegate showAlert:@"Carton Content must have a description." withTitle:@"Error Saving"];
        return;
    }
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(![del.surveyDB savePVOCartonContent:content withCustomerID:del.customerID])
    {
        [SurveyAppDelegate showAlert:@"Content Codes must be unique and in the 9000 series or higher, please re-enter content code." withTitle:@"Error Saving"];
        return;
    }
    
    if(delegate != nil && [delegate respondsToSelector:@selector(addContentsController:addedContent:)])
        [delegate addContentsController:self addedContent:content];
    
    [self cancel:nil];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.content = [[PVOCartonContent alloc] init];
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    content.contentID = [del.surveyDB getPVONextCartonContentID];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
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

-(void)updateValueWithField:(UITextField*)field
{
    if(field.tag == PVO_NEW_CONTENTS_NAME)
        content.description = field.text;
    else if(field.tag == PVO_NEW_CONTENTS_CODE)
        content.contentID = [field.text intValue];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(NSString*) tableView: (UITableView*)tableView titleForFooterInSection: (NSInteger) section
{
    return @"Please enter a description and a content code for the contents.  Content Codes must be in the 9000 series.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TextCell";
    
    TextCell *cell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.tboxValue.delegate = self;
        cell.tboxValue.tag = indexPath.row;
        [cell.tboxValue addTarget:self 
                           action:@selector(textFieldDoneEditing:) 
                 forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    
    if(indexPath.row == PVO_NEW_CONTENTS_NAME)
    {
        cell.tboxValue.placeholder = @"Contents Description";
        cell.tboxValue.clearsOnBeginEditing = NO;
        cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
        cell.tboxValue.text = content.description;
    }
    else if(indexPath.row == PVO_NEW_CONTENTS_CODE)
    {
        cell.tboxValue.placeholder = @"Contents Code";
        cell.tboxValue.clearsOnBeginEditing = YES;
        cell.tboxValue.keyboardType = UIKeyboardTypeNumberPad;
        cell.tboxValue.text = [NSString stringWithFormat:@"%d", content.contentID];
    }
    
    return cell;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

@end
