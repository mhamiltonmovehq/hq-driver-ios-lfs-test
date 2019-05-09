//
//  TablePickerController.m
//  Survey
//
//  Created by Tony Brame on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TablePickerController.h"
#import "SurveyAppDelegate.h"
#import "CustomerOptionsController.h"

@implementation TablePickerController

@synthesize objects;
@synthesize currentValue;
@synthesize caller;
@synthesize callback;
@synthesize showingModal, selectOnCheck;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    self.preferredContentSize = CGSizeMake(320, 416);
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
    
    [super viewDidLoad];
}



- (void)viewWillAppear:(BOOL)animated {
    
    _exitWithSave = NO;

    if(!selectOnCheck)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                                target:self
                                                                                                action:@selector(save:)];
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    if([objects isKindOfClass:[NSDictionary class]] ||
       [objects isKindOfClass:[NSMutableDictionary class]]) 
        keys = [[objects allKeys] sortedArrayUsingSelector:@selector(compare:)];
    else
        keys = nil;
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}


-(IBAction)save:(id)sender
{
    _exitWithSave = YES;
    
    if(currentValue == nil)
    {
        [SurveyAppDelegate showAlert:@"You must have a value selected to continue." withTitle:@"Selection Required"];
        return;
    }
    
    if([caller respondsToSelector:callback])
        [caller performSelector:callback withObject:currentValue];
    
    [self cancel:nil];
}

-(IBAction)cancel:(id)sender
{
    if(_skipInventoryProcess && !_exitWithSave){
        //jump back to customer options
        CustomerOptionsController *c = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[CustomerOptionsController class]])
                c = view;
        }
        
        if(c != nil){
            [self.navigationController popToViewController:c animated:YES];
        } else {
            [self.navigationController pushViewController:c animated:YES];
        }
    }
    else if(showingModal)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    
    
    [super viewWillDisappear:animated];
}

//-(void)viewDidDisappear:(BOOL)animated
//{
//    if(currentValue != nil)
//    {
//        if([caller respondsToSelector:callback])
//            [caller performSelector:callback withObject:currentValue];
//    }
//}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if([objects isKindOfClass:[NSArray class]] || 
       [objects isKindOfClass:[NSMutableArray class]])
        return [(NSArray*)objects count];
    else
        return [keys count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if([objects isKindOfClass:[NSArray class]] || 
       [objects isKindOfClass:[NSMutableArray class]])
    {
        NSString *current = [objects objectAtIndex:[indexPath row]];
        cell.textLabel.text = current;
        
        if(!selectOnCheck && [current isEqualToString:currentValue])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;    
    }
    else
    {
        NSNumber *currentKey = [keys objectAtIndex:[indexPath row]];
        cell.textLabel.text = [objects objectForKey:currentKey];
        
        if(!selectOnCheck && currentValue != nil && [currentKey intValue] == [currentValue intValue])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;    
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if([objects isKindOfClass:[NSArray class]] || 
       [objects isKindOfClass:[NSMutableArray class]])
    {
        self.currentValue = [objects objectAtIndex:[indexPath row]];
    }
    else
    {
        self.currentValue = [keys objectAtIndex:[indexPath row]];
    }
    
    if(selectOnCheck)
    {
        [self save:nil];
    }
    else
    {
        for (UITableViewCell *tvc in [tableView visibleCells]) {
            tvc.accessoryType = UITableViewCellAccessoryNone;
        }
        
        UITableViewCell *uitvc = [tableView cellForRowAtIndexPath:indexPath];
        uitvc.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}




@end

