//
//  SelectObjectController.m
//  Survey
//
//  Created by Tony Brame on 10/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SelectObjectController.h"
#import "SurveyAppDelegate.h"

@implementation SelectObjectController

@synthesize choices, displayMethod, multipleSelection, delegate, selectedItems, controllerPushed, allowsNoSelection;

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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self 
                                                                                           action:@selector(cancel:)];
    if(multipleSelection)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                                target:self 
                                                                                                action:@selector(save:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    if(delegate != nil && [delegate respondsToSelector:@selector(selectObjectControllerPreSelectedItems:)])
        self.selectedItems = [delegate selectObjectControllerPreSelectedItems:self];
    else if(self.selectedItems == nil)
        self.selectedItems = [NSMutableArray array];
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

-(IBAction)save:(id)sender
{
    if([selectedItems count] == 0 && !allowsNoSelection)
    {
        [SurveyAppDelegate showAlert:@"You must select at least one item." withTitle:@"No Selection"];
        return;
    }
    
    //call back to delegate...
    if([delegate respondsToSelector:@selector(objectsSelected:withObjects:)])
    {
        [delegate objectsSelected:self withObjects:selectedItems];
    }
    
    if([delegate respondsToSelector:@selector(selectObjectControllerShouldDismiss:)])
    {
        if([delegate selectObjectControllerShouldDismiss:self])
            [self cancel:nil];
    }
    else
    {
        [self cancel:nil];
    }
}

-(IBAction)cancel:(id)sender
{
    if(controllerPushed)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.selectedItems = nil;
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [choices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    id object = [choices objectAtIndex:indexPath.row];
    if([object respondsToSelector:displayMethod])
        cell.textLabel.text = [object performSelector:displayMethod];
    else
        cell.textLabel.text = @"invalid responder";
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if(multipleSelection)
    {
        for (id selected in selectedItems) {
            if(object == selected)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
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
    
    id object = [choices objectAtIndex:indexPath.row];
    
    if(multipleSelection)
    {
        UITableViewCell *uitvc = [tableView cellForRowAtIndexPath:indexPath];
        if([selectedItems containsObject:object])
        {
            uitvc.accessoryType = UITableViewCellAccessoryNone;
            [selectedItems removeObject:object];
        }
        else
        {
            uitvc.accessoryType = UITableViewCellAccessoryCheckmark;
            [selectedItems addObject:object];
        }
    }
    else
    {
        [selectedItems removeAllObjects];
        [selectedItems addObject:object];
        //save
        [self save:nil];
    }
}

@end
