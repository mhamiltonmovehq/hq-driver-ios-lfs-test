//
//  ItemDetailController.m
//  Survey
//
//  Created by Tony Brame on 7/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ItemDetailController.h"
#import "TextWithHeaderCell.h"
#import "Item.h"
#import "SurveyAppDelegate.h"
#import "SurveyImageViewer.h"
#import "SurveyImage.h"
#import "SurveyCustomer.h"
#import "CustomerUtilities.h"

@implementation ItemDetailController

@synthesize item, si, comment, dims, fieldController, callback, caller, imageViewer, itemImage, imagesCount, sections;

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

- (void)viewDidLoad {
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.preferredContentSize = CGSizeMake(320, 416);
    
    /*self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(save:)];*/
    
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(!editing)
    {
        Item *base = [del.surveyDB getItem:si.itemID WithCustomer:del.customerID];
        si.item = base;
        
        if(item.isCrate > 0)
            self.dims = [del.surveyDB getCrateDimensions:si.siID];
        else
            self.dims = nil;
        
        self.comment = [del.surveyDB getItemComment:si.siID];
        
        if(item.isBulky)
        {
            // removed code that did literally nothing.  Not sure what should be done here.
        }
        
        [self initializeSections];
        
    }
    
    if(!editing || editingImages)
    {
        //load image if it has one.
        NSMutableArray *arr = [del.surveyDB getImagesList:del.customerID withPhotoType:IMG_SURVEYED_ITEMS 
                               withSubID:si.siID loadAllItems:NO];
        self.itemImage = nil;
        imagesCount = 0;
        if(arr != nil && [arr count] > 0)
        {
            NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
            SurveyImage *image = [arr objectAtIndex:0];
            NSString *filePath = image.path;
            NSString *fullPath = [docsDir stringByAppendingPathComponent:filePath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:fullPath])
            {
                UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
                UIImage *newImg = [SurveyAppDelegate resizeImage:img withNewSize:CGSizeMake(30, 30)];
                self.itemImage = newImg;
            }
            
            imagesCount = [arr count];
        }                
    }
    
    editing = NO;
    editingImages = NO;
    
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

-(void)initializeSections
{
    
    if(sections == nil)
        sections = [[NSMutableArray alloc] init];
    
    [sections removeAllObjects];
        
    [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_SHIP]];
    [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_WEIGHT]];
    [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_COMMENT]];
    if(item.isCP || item.isCrate)
        [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_PACK]];
    if(item.isCrate)
        [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_DIMENSIONS]];
    
    if(![SurveyAppDelegate iPad])
        [sections addObject:[NSNumber numberWithInt:ITEM_DETAIL_SECTION_PHOTO]];
    
}

-(IBAction)save:(id)sender
{
    
    //all saves are taken care of in the dissapear function'
    //i removed the save button as well
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if(!editing && !editingImages)
    {
        if([caller respondsToSelector:callback])
        {
            [caller performSelector:callback withObject: si];
            
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            if(comment != nil)
                [del.surveyDB setItemComment:si.siID withCommentText:comment];
            
            if(dims != nil)
            {
                [del.surveyDB setCrateDimensions:si.siID withDimensions:dims];
            }
            
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)doneEditing:(NSString*)newValue
{
//    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *temp;
    int section = [self sectionTypeAtIndex:editingPath.section];
    switch (section) {
        case ITEM_DETAIL_SECTION_SHIP:
            if([editingPath row] == ITEM_DETAIL_ROW_SHIPPING)
            {
                si.shipping = [newValue intValue];
                if(si.item.isCP || si.item.isCrate)
                    si.packing = si.shipping;
            }
            else if ([editingPath row] == ITEM_DETAIL_ROW_NOTSHIPPING)
                si.notShipping = [newValue intValue];
            break;
        case ITEM_DETAIL_SECTION_WEIGHT:
            if([editingPath row] == ITEM_DETAIL_ROW_WEIGHT)
                si.weight = [newValue intValue];
            else if ([editingPath row] == ITEM_DETAIL_ROW_CUBE)
                si.cube = [newValue doubleValue];
            break;
        case ITEM_DETAIL_SECTION_PACK:
            if([editingPath row] == ITEM_DETAIL_ROW_PACK)
                si.packing = [newValue intValue];
            else if ([editingPath row] == ITEM_DETAIL_ROW_UNPACK)
                si.unpacking = [newValue intValue];
            break;
        case ITEM_DETAIL_SECTION_COMMENT:
            self.comment = newValue;
            break;
        case ITEM_DETAIL_SECTION_DIMENSIONS:
            if([editingPath row] == ITEM_DETAIL_ROW_LENGTH)
                dims.length = [newValue intValue];
            else if([editingPath row] == ITEM_DETAIL_ROW_WIDTH)
                dims.width = [newValue intValue];
            else if([editingPath row] == ITEM_DETAIL_ROW_HEIGHT)
                dims.height = [newValue intValue];
            
            [si updateCrateCube:dims withMinimum:4 andInches:4];
            
            
            break;
        default:
            break;
    }
    
    [self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sections count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int sect = [self sectionTypeAtIndex:section];
    switch (sect) {
        case ITEM_DETAIL_SECTION_SHIP:
        case ITEM_DETAIL_SECTION_WEIGHT:
        case ITEM_DETAIL_SECTION_PACK:
            return 2;
        case ITEM_DETAIL_SECTION_DIMENSIONS:
            return 3;
        default:
            return 1;
    }
}

-(int)sectionTypeAtIndex:(int)idx
{
    return [[sections objectAtIndex:idx] intValue];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *THCellIdentifier = @"TextWithHeaderCell";
    static NSString *BasicIdentifier = @"BasicCell";
    UITableViewCell *simplecell = nil;
    TextWithHeaderCell *cell = nil;
    
    int section = [self sectionTypeAtIndex:indexPath.section];
    
    if(section == ITEM_DETAIL_SECTION_PHOTO)
    {
        simplecell = [tableView dequeueReusableCellWithIdentifier:BasicIdentifier];
        if (simplecell == nil) {
            simplecell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BasicIdentifier];
            simplecell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else
    {
        cell = (TextWithHeaderCell *)[tableView dequeueReusableCellWithIdentifier:THCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextWithHeaderCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    switch (section) {
        case ITEM_DETAIL_SECTION_SHIP:
            if([indexPath row] == ITEM_DETAIL_ROW_SHIPPING)
            {
                cell.labelHeader.text = @"Shipping";
                cell.labelText.text = [NSString stringWithFormat:@"%d", si.shipping];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_NOTSHIPPING)
            {
                cell.labelHeader.text = @"Not Shipping";
                cell.labelText.text = [NSString stringWithFormat:@"%d", si.notShipping];
            }
            break;
        case ITEM_DETAIL_SECTION_WEIGHT:
            if([indexPath row] == ITEM_DETAIL_ROW_WEIGHT)
            {
                cell.labelHeader.text = @"Weight";
                cell.labelText.text = [NSString stringWithFormat:@"%d", si.weight];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_CUBE)
            {
                cell.labelHeader.text = @"Cube";
                cell.labelText.text = [Item formatCube: si.cube];
            }
            break;
        case ITEM_DETAIL_SECTION_PACK:
            if([indexPath row] == ITEM_DETAIL_ROW_PACK)
            {
                cell.labelHeader.text = @"Packing";
                cell.labelText.text = [NSString stringWithFormat:@"%d", si.packing];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_UNPACK)
            {
                cell.labelHeader.text = @"Unpacking";
                cell.labelText.text = [NSString stringWithFormat:@"%d", si.unpacking];
            }
            break;
        case ITEM_DETAIL_SECTION_COMMENT:
            cell.labelHeader.text = @"Comment";
            cell.labelText.text = comment;
            break;
        case ITEM_DETAIL_SECTION_PHOTO:
            if(self.itemImage == nil)
            {
                simplecell.textLabel.text = @"Manage Photos";
                simplecell.imageView.image = [UIImage imageNamed:@"img_photo.png"];
            }
            else
            {
                simplecell.textLabel.text = [NSString stringWithFormat:@"Manage Photos [%d]", imagesCount];
                simplecell.imageView.image = self.itemImage;
            }
            break;
        case ITEM_DETAIL_SECTION_DIMENSIONS:            
            if([indexPath row] == ITEM_DETAIL_ROW_LENGTH) 
            {
                cell.labelHeader.text = @"Length";
                cell.labelText.text = [NSString stringWithFormat:@"%d", dims.length];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_WIDTH) 
            {
                cell.labelHeader.text = @"Width";
                cell.labelText.text = [NSString stringWithFormat:@"%d", dims.width];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_HEIGHT) 
            {
                cell.labelHeader.text = @"Height";
                cell.labelText.text = [NSString stringWithFormat:@"%d", dims.height];
            }
            break;
    }
    
    // Set up the cell...
    
    return simplecell != nil ? simplecell : cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL loadFieldController = YES, loadNoteController = NO;
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UIKeyboardType keyboard = UIKeyboardTypeNumberPad;
    BOOL clear = NO;
    NSString *placeholder;
    NSString *value = nil;
    int section = [self sectionTypeAtIndex:indexPath.section];
    switch (section) {
        case ITEM_DETAIL_SECTION_SHIP:
            if([indexPath row] == ITEM_DETAIL_ROW_SHIPPING)
            {
                placeholder = @"Shipping";
                value = [NSString stringWithFormat:@"%d", si.shipping];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_NOTSHIPPING)
            {
                placeholder = @"Not Shipping";
                value = [NSString stringWithFormat:@"%d", si.notShipping];
            }
            break;
        case ITEM_DETAIL_SECTION_WEIGHT:
            if([indexPath row] == ITEM_DETAIL_ROW_WEIGHT)
            {
                placeholder = @"Weight";
                value = [NSString stringWithFormat:@"%d", si.weight];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_CUBE)
            {
                keyboard = UIKeyboardTypeNumbersAndPunctuation;
                placeholder = @"Cube";
                value = [[NSNumber numberWithDouble:si.cube] stringValue];
            }
            break;
        case ITEM_DETAIL_SECTION_PACK:
            if([indexPath row] == ITEM_DETAIL_ROW_PACK)
            {
                placeholder = @"Packing";
                value = [NSString stringWithFormat:@"%d", si.packing];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_UNPACK)
            {
                placeholder = @"Unpacking";
                value = [NSString stringWithFormat:@"%d", si.unpacking];
            }
            break;
        case ITEM_DETAIL_SECTION_PHOTO:
            
            if(imageViewer == nil)
                self.imageViewer = [[SurveyImageViewer alloc] init];
            
            imageViewer.photosType = IMG_SURVEYED_ITEMS;
            imageViewer.customerID = del.customerID;
            imageViewer.subID = si.siID;
            
            imageViewer.caller = self.view;
            imageViewer.viewController = self;
            
            
            [imageViewer loadPhotos];
            
            editingImages = YES;
            
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                        
            loadFieldController = NO;
            break;
        case ITEM_DETAIL_SECTION_COMMENT:
            keyboard = UIKeyboardTypeASCIICapable;
            placeholder = @"Comment";
            value = comment;
            loadFieldController = NO;
            loadNoteController = YES;
            break;
        case ITEM_DETAIL_SECTION_DIMENSIONS:
            if([indexPath row] == ITEM_DETAIL_ROW_LENGTH)
            {
                placeholder = @"Length";
                value = [NSString stringWithFormat:@"%d", dims.length];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_WIDTH)
            {
                placeholder = @"Width";
                value = [NSString stringWithFormat:@"%d", dims.width];
            }
            else if([indexPath row] == ITEM_DETAIL_ROW_HEIGHT)
            {
                placeholder = @"Height";
                value = [NSString stringWithFormat:@"%d", dims.height];
            }
            break;
    }
    
    editing = YES;
    editingPath = indexPath;
    
    if(loadFieldController)
    {
        
        [del pushSingleFieldController:value
                           clearOnEdit:clear 
                          withKeyboard:keyboard 
                       withPlaceHolder:placeholder
                            withCaller:self 
                           andCallback:@selector(doneEditing:)
                     dismissController:YES
                      andNavController:self.navigationController];
    }
    else if(loadNoteController)
    {
        
        [del pushNoteViewController:value 
                       withKeyboard:keyboard 
                       withNavTitle:@"Note" 
                    withDescription:[NSString stringWithFormat:@"Note For: %@",item.name]  
                         withCaller:self 
                        andCallback:@selector(doneEditing:)
                  dismissController:YES
                           noteType:NOTE_TYPE_ITEM
                   andNavController:self.navigationController];
        
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

