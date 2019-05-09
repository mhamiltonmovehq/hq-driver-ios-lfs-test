//
//  PVOBulkyDetailsController.m
//  Survey
//
//  Created by Justin on 6/24/16.
//
//

#import "PVOBulkyDetailsController.h"
#import "SurveyAppDelegate.h"
#import "LabelTextCell.h"
#import "PVOBulkyEntry.h"
#import "PVOBulkyData.h"


@implementation PVOBulkyDetailsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Details";
    self.editingEntry = nil;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonSystemItemDone target:self action:@selector(save:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //mimics dyanimc reports, there are no drop down entries or date pickers right now, if there were this would prevent the view from reloading data when we return
    if(self.editingEntry == nil)
    {
        self.entries = [del.pricingDB getPVOBulkyDetailEntries:_pvoBulkyItem.pvoBulkyItemTypeID];
        self.data = [del.surveyDB getPVOBulkyData:_pvoBulkyItem.pvoBulkyItemID];
    }
    
    self.editingEntry = nil;
    
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(IBAction)updateValueWithField:(UITextField*)sender
{
    PVOBulkyEntry *thisEntry = nil;
    
    for (PVOBulkyEntry *entry in self.entries) {
        if(entry.dataEntryID == sender.tag)
            thisEntry = entry;
    }
    
    if(thisEntry == nil)
        return;
    
    PVOBulkyData *data = [self getBulkyDataForEntry:thisEntry];
    
    if(thisEntry.entryDataType == RDT_TEXT || thisEntry.entryDataType == RDT_TEXT_LONG){
        data.textValue = sender.text;
    }
    else if(thisEntry.entryDataType == RDT_INTEGER){
        data.intValue = [sender.text intValue];
    }
    else if(thisEntry.entryDataType == RDT_DOUBLE){
        data.doubleValue = [sender.text doubleValue];
    }
}

#pragma mark Interface Button Methods

-(IBAction)save:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(self.currentTextBox != nil)
        [self updateValueWithField:self.currentTextBox];
    
    
    _pvoBulkyItem.pvoBulkyItemID = [del.surveyDB savePVOBulkyInventoryItem:del.customerID withPVOBulkyItem:_pvoBulkyItem];
    
    [del.surveyDB savePVOBulkyData:self.data withPVOBulkyItemID:_pvoBulkyItem.pvoBulkyItemID];
    
    if(_wireframe == nil)
        _wireframe = [[PVOWireFrameTypeController alloc] initWithStyle:UITableViewStyleGrouped];
    
    _wireframe.isAutoInventory = NO;
    _wireframe.wireframeItemID = _pvoBulkyItem.pvoBulkyItemID;
    _wireframe.isOrigin = _isOrigin;
    _wireframe.delegate = self;
    _wireframe.selectedWireframeTypeID = _pvoBulkyItem.wireframeTypeID;
    
    
    [SurveyAppDelegate setDefaultBackButton:self];
    [self.navigationController pushViewController:_wireframe animated:YES];
}

#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.currentTextBox = textField;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
    [self updateValueWithField:textField];
}

-(IBAction)textFieldDoneEditing:(id)sender
{
    [sender resignFirstResponder];
}

-(void)dealloc
{
    self.currentTextBox;
    self.checkListController;
    self.pvoBulkyItem;
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.entries count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *LabelTextCellIdentifier = @"LabelTextCell";
    
    LabelTextCell* ltCell = nil;
    
    ltCell = (LabelTextCell*)[tableView dequeueReusableCellWithIdentifier:LabelTextCellIdentifier];//point cell to label textview class and identifier
    //populate items in the label text cell
    if (ltCell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LabelTextCell" owner:self options:nil];
        ltCell = [nib objectAtIndex:0];
        [ltCell setPVOView];
        ltCell.tboxValue.delegate = self;
        [ltCell.tboxValue addTarget:self action:@selector(textFieldDoneEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
    }
    
    PVOBulkyEntry *thisEntry = [self.entries objectAtIndex:indexPath.row];
    PVOBulkyData *thisData = [self getBulkyDataForEntry:thisEntry];
    
    if(thisEntry.entryDataType == RDT_TEXT ||
       thisEntry.entryDataType == RDT_INTEGER ||
       thisEntry.entryDataType == RDT_DOUBLE){
        
        ltCell.tboxValue.tag = thisEntry.dataEntryID;
        ltCell.labelHeader.text = thisEntry.entryName;
        
        if(thisEntry.entryDataType == RDT_TEXT)
            ltCell.tboxValue.text = thisData.textValue;
        else if(thisEntry.entryDataType == RDT_INTEGER)
            ltCell.tboxValue.text = [NSString stringWithFormat:@"%d", thisData.intValue];
        else if(thisEntry.entryDataType == RDT_DOUBLE)
            ltCell.tboxValue.text = [SurveyAppDelegate formatDouble:thisData.doubleValue];
        
    }
    
    return ltCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.editingEntry = [self.entries objectAtIndex:indexPath.row];
//    PVODynamicReportData *thisData = nil; //[self getReportDataForEntry:self.editingEntry];
    
    //do nothing for now, everythign is short text entry
    
}


//get the customer data from the customer database for the entry from the PVO Control tables
-(PVOBulkyData*)getBulkyDataForEntry:(PVOBulkyEntry*)controlEntry
{
    for (PVOBulkyData *data in self.data) {
        if (data.dataEntryID == controlEntry.dataEntryID)
            return data;
    }
    
    //create a new one
    PVOBulkyData *retval = [[PVOBulkyData alloc] init];
    retval.dataEntryID = controlEntry.dataEntryID;
    
    [self.data addObject:retval];
    
    return retval;
}

#pragma mark - PVOWiretypeControllerDelegate methods

-(NSDictionary*)getWireFrameTypes:(id)controller
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
//    return [[NSDictionary alloc] initWithObjects:@[@"Car", @"Truck", @"SUV", @"Photo"]
//                                         forKeys:@[[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],[NSNumber numberWithInt:3],[NSNumber numberWithInt:4]]];
    
    
    //get wireframe options
    return [del.pricingDB getWireframeTypesForPVOBulkyItemType:_pvoBulkyItem.pvoBulkyItemTypeID];
}

-(void)saveWireFrameTypeIDForDelegate:(int)selectedWireframeType
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _pvoBulkyItem.wireframeTypeID = selectedWireframeType;
    
    if (_pvoBulkyItem.pvoBulkyItemID > 0) {
        [del.surveyDB updatePVOBulkyInventoryItem:_pvoBulkyItem];        
    }
}


@end
