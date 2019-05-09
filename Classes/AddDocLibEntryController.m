//
//  AddDocLibEntryController.m
//  Survey
//
//  Created by Tony Brame on 5/23/13.
//
//

#import "AddDocLibEntryController.h"
#import "TextCell.h"
#import "SurveyAppDelegate.h"

@interface AddDocLibEntryController ()

@end

@implementation AddDocLibEntryController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [SurveyAppDelegate adjustTableViewForiOS7:self.tableView];
    
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                            target:self
                                                                                            action:@selector(cmdSaveClick:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self
                                                                                            action:@selector(cmdCancelClick:)];
    
    self.title = @"New Document";
}

-(IBAction)cmdCancelClick:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)cmdSaveClick:(id)sender
{
    //validate the url, save the document
    if(self.tboxCurrent != nil)
    {
        [self updateValueWithField:self.tboxCurrent];
        [self.tboxCurrent resignFirstResponder];
    }
    
    if(self.current.docName == nil || self.current.docName.length == 0)
    {
        [SurveyAppDelegate showAlert:@"You must have a doc name entered to continue." withTitle:@"Name Required"];
        return;
    }
    if(self.current.url == nil || self.current.url.length == 0)
    {
        [SurveyAppDelegate showAlert:@"You must have a doc URL entered to continue." withTitle:@"URL Required"];
        return;
    }
    
    NSURL *candidateURL = [NSURL URLWithString:self.current.url];
    if (!candidateURL || !candidateURL.scheme || !candidateURL.host) {
        [SurveyAppDelegate showAlert:@"You must have a valid doc URL entered to continue." withTitle:@"URL Required"];
        return;
    }
    
    if(![self.current.url hasSuffix:@".pdf"])
    {
        [SurveyAppDelegate showAlert:@"Only pdf documents are supported. Please provide the URL for a PDF." withTitle:@"URL Required"];
        return;
    }
    
    self.current.delegate = self;
    [self.current downloadDoc];
    
}

-(IBAction)textFieldDoneEditing:(id)sender
{
	[sender resignFirstResponder];
}

-(void)updateValueWithField:(UITextField*)tbox
{
    if(tbox.tag == ADD_DOC_DOC_NAME)
        self.current.docName = tbox.text;
    else if(tbox.tag == ADD_DOC_URL)
        self.current.url = tbox.text;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.current = [[DocLibraryEntry alloc] init];
    self.current.docEntryType = DOC_LIB_TYPE_GLOBAL;
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TextCell *cell = nil;
    NSString *TextCellIdentifier = @"TextCell";
    
    cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
    if(cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    
        [cell.tboxValue setDelegate:self];
        cell.tboxValue.returnKeyType = UIReturnKeyDone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.tboxValue addTarget:self
                           action:@selector(textFieldDoneEditing:)
                 forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    
    int row = indexPath.row;
    cell.tboxValue.tag = row;
    
    //if it wasn't created yet, go ahead and load the data to it now.
    switch (row) {
        case ADD_DOC_DOC_NAME:
            cell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            cell.tboxValue.text = self.current.docName;
            cell.tboxValue.placeholder = @"Document Name";
            cell.tboxValue.keyboardType = UIKeyboardTypeASCIICapable;
            break;
        case ADD_DOC_URL:
            cell.tboxValue.autocapitalizationType = UITextAutocapitalizationTypeWords;
            cell.tboxValue.text = self.current.url;
            cell.tboxValue.placeholder = @"Document URL";
            cell.tboxValue.keyboardType = UIKeyboardTypeURL;
            break;
        default:
            break;
			
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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


#pragma mark - Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.tboxCurrent = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self updateValueWithField:textField];
    
}

#pragma mark - DocumentLibraryEntryDelegate methods

-(void)documentDownloaded:(DocLibraryEntry *)entry
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
