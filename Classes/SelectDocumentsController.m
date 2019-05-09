//
//  SelectDocumentsController.m
//  Survey
//
//  Created by Chris Jenkins on 9/3/15.
//
//

#import "SelectDocumentsController.h"

@implementation SelectDocumentsController

@synthesize docs;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        //dismiss = TRUE;
    }
    return self;
}

- (void)viewDidLoad
{
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];
    
    //	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
    //																						  target:self
    //																						  action:@selector(cancel:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    [super viewDidLoad];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    //    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = @"Select Documents";
    
    //if (itemsToMove == nil)
      //  itemsToMove = [[NSMutableArray alloc] init];
    //[itemsToMove removeAllObjects];
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidUnload {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)save:(id)sender
{

}

-(IBAction)cancel:(id)sender
{

}

#pragma mark - Table view data source


@end
