//
//  CommonNotesController.m
//  Survey
//
//  Created by Tony Brame on 8/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CommonNotesController.h"
#import "SurveyAppDelegate.h"
#import "NoteViewController.h"

@implementation CommonNotesController

@synthesize noteType, options, caller, callback;

- (void)viewDidLoad {
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    self.preferredContentSize = CGSizeMake(320, 416);
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.options = [del.surveyDB loadCommonNotes:noteType];
    
    [self.tableView reloadData];
    
    switch (noteType) {
        case NOTE_TYPE_CUSTOMER:
            self.title = @"Common Customer Notes";
            break;
        case NOTE_TYPE_ITEM:
            self.title = @"Common Item Notes";
            break;
        case NOTE_TYPE_THIRD_PARTY:
            self.title = @"Common 3rd Pty Notes";
            break;
        default:
            break;
    }
    
    [super viewWillAppear:animated];
}

-(void)enteredNewNote:(NSString*)newNote
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CommonNote *note = [[CommonNote alloc] init];
    note.type = noteType;
    note.note = newNote;
    
    [del.surveyDB saveNewCommonNote:note];
    
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
*/

/*
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
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

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [options count] + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if([indexPath row] < [options count])
    {
        CommonNote *note = [options objectAtIndex:[indexPath row]];
        cell.textLabel.text = note.note;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        cell.textLabel.text = @"Add New";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if([indexPath row] == [options count])
    {//add new
        
        //use my own note controller since the global one is in use on the stack already
        //have to load it in memory here since it is a recursive reference to put it in the header.
        //may cause a memory leak?
        
        NoteViewController *noteController = nil;
        if(noteController == nil)
        {
            noteController = [[NoteViewController alloc] initWithStyle:UITableViewStyleGrouped];
            noteController.keyboard = UIKeyboardTypeASCIICapable;
            noteController.navTitle = @"New Common Note";
            noteController.description = @"Enter New Common Note";
            noteController.caller = self;
            noteController.callback = @selector(enteredNewNote:);
            noteController.noteType = NOTE_TYPE_NONE;
        }
        
        noteController.destString = @"";
        [self.navigationController pushViewController:noteController animated:YES];
        
    }
    else
    {
        CommonNote *note = [options objectAtIndex:[indexPath row]];
        if([caller respondsToSelector:callback])
        {
            [caller performSelector:callback withObject:note.note];
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if([indexPath row] != [options count])
        return YES;
    else
        return NO;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        CommonNote *note = [options objectAtIndex:[indexPath row]];
        [del.surveyDB deleteCommonNote:note.recID];
        
        self.options = [del.surveyDB loadCommonNotes:noteType];
        
        // Animate the deletion from the table.
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                  withRowAnimation:UITableViewRowAnimationFade];
    }
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



@end

