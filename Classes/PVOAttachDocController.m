//
//  PVOAttachDocControllerViewController.m
//  Survey
//
//  Created by Lee Zumstein on 8/19/14.
//
//

#import "PVOAttachDocController.h"
#import "SurveyAppDelegate.h"

@implementation PVOAttachDocController

@synthesize caller, viewController, picker;
@synthesize oneImageView, oneImageViewImage, allImagesView, docLabel, scrollView;
@synthesize navItemID, category, attachDocOptions, selectedDoc, addedImages;
@synthesize firstLoad, generateDocProgress;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)promptForDocument
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    attachDocOptions = [del.pricingDB getPVOAttachDocItems:navItemID withDriverType:[del.surveyDB getDriverData].driverType];
    
    NSMutableDictionary *opts = [[NSMutableDictionary alloc] init];
    for (int i=0; i<[attachDocOptions count]; i++) {
        PVOAttachDocItem *item = [attachDocOptions objectAtIndex:i];
        [opts setObject:item.description forKey:[NSNumber numberWithInt:i]];
    }
    
    [del popTablePickerController:@"Document Type"
                      withObjects:opts
             withCurrentSelection:nil
                       withCaller:self
                      andCallback:@selector(attachDocSelected:)
                  dismissOnSelect:YES
                andViewController:self.viewController];
    
}

-(void)attachDocSelected:(NSNumber*)index
{
    selectedDoc = [attachDocOptions objectAtIndex:[index intValue]];
    firstLoad = YES;
    
    PortraitNavController *nav = [[PortraitNavController alloc] initWithRootViewController:self];
    [self.viewController presentViewController:nav animated:YES completion:nil];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Attach Document";
    
    oneImageView.hidden = YES;
    
    [self setNavigationItems];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.addedImages = [[NSMutableArray alloc] init];
}

-(void)setNavigationItems
{
    if (oneImageView.hidden)
    {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelOrDoneSelected:)];
        self.navigationItem.leftBarButtonItem = cancel;
        
        UIBarButtonItem *addImage = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addImage:)];
        self.navigationItem.rightBarButtonItem = addImage;
    }
    else
    {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelOrDoneSelected:)];
        self.navigationItem.leftBarButtonItem = done;
        
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(void)cancelOrDoneSelected:(id)sender
{
    if (oneImageView.hidden)
    {
        [self deleteTempImages];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {// First create a CATransition object to describe the transition
        CATransition *transition = [CATransition animation];
        // Animate over .5 seconds
        transition.duration = 0.5;
        // using the ease in/out timing function
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromLeft;
        
        // Next add it to the view's layer. This will perform the transition based on how we change its contents.
        [self.view.layer addAnimation:transition forKey:nil];
        
        oneImageView.hidden = YES;
        allImagesView.hidden = NO;
        
        oneImageViewImage.image = nil;
        
        self.navigationItem.title = @"Attach Document";
        
        [self setNavigationItems];
    }
}

-(void)addImage:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Add Page"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"Take New Photo" otherButtonTitles:@"Add Existing Photo", nil];
    [sheet showInView:self.view];
}

-(void)viewWillAppear:(BOOL)animated
{
    oneImageView.hidden = YES;
    allImagesView.hidden = NO;
    
    //remove everything
    [[scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (firstLoad)
        docLabel.text = [NSString stringWithFormat:@"%@ %@", category, selectedDoc.description];
    
    if (addedImages != nil && [addedImages count] > 0)
    {
        //here is where i will add all of the images.
        //loop through my images, and create thumbnails
        CGSize imageSize;
        imageSize.width = 100;
        imageSize.height = 100;
        
        int buffer = 5;
        
        int added = 0;
        int currenty = 0;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        int i = 0;
        for (SurveyImage *surveyImage in addedImages)
        {
            if([fileManager fileExistsAtPath:surveyImage.path])
            {
                if(added > 0 && added % 3 == 0)//new row
                    currenty += buffer + imageSize.height;
                
                CGRect location = CGRectMake(buffer + ((added % 3) * (buffer + imageSize.width)),
                                             currenty,
                                             imageSize.width,
                                             imageSize.height);
                surveyImage.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
                surveyImage.imageButton.frame = location;
                [surveyImage.imageButton setBackgroundColor:[UIColor blackColor]];
                
                surveyImage.imageButton.tag = i;
                
                //set this once it is live!
                [surveyImage.imageButton addTarget:self action:@selector(imageSelected:) forControlEvents:UIControlEventTouchUpInside];
                
                //add a progress indicator
                UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectInset(location, 40, 40)];
                progress.tag = 1000;
                progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
                [progress startAnimating];
                [surveyImage.imageButton addSubview:progress];
                
                [scrollView addSubview:surveyImage.imageButton];
                
                NSArray *array = [[NSArray alloc] initWithObjects:surveyImage, [NSNumber numberWithInt:(added+1)], nil];
                NSOperationQueue *queue = [NSOperationQueue new];
                NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                    initWithTarget:self
                                                    selector:@selector(loadImage:)
                                                    object:array];
                [queue addOperation:operation];
                
                added++;
            }
            i++;
        }
        
        //scrollView.contentSize = CGSizeMake(315, currenty + buffer + imageSize.height);
    }
    
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    if (firstLoad)
    {
        firstLoad = NO;
        [self addImage:nil];
    }
    
    [super viewDidAppear:animated];
}

-(void)loadImage:(NSArray*)data
{
    SurveyImage *imageDetails = [data objectAtIndex:0];
    NSNumber *pageNum = [data objectAtIndex:1];
    
    CGSize imageSize;
    imageSize.width = 100;
    imageSize.height = 100;
    
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imageDetails.path];
    
    UIImage *newimg = [SurveyAppDelegate resizeImage:img withNewSize:imageSize];
    
    NSArray *array = [[NSArray alloc] initWithObjects:imageDetails, newimg, pageNum, nil];
    [self performSelectorOnMainThread:@selector(imageLoaded:)
                           withObject:array
                        waitUntilDone:YES];
    
    
}

-(void)imageLoaded:(NSArray*)data
{
    SurveyImage *imageDetails = [data objectAtIndex:0];
    UIImage *image = [data objectAtIndex:1];
    NSNumber *pageNum = [data objectAtIndex:2];
    
    //remove spinner
    [[imageDetails.imageButton viewWithTag:1000] removeFromSuperview];
    
    [imageDetails.imageButton setBackgroundImage:image forState:UIControlStateNormal];
    
    CGRect location = imageDetails.imageButton.frame;
    location = CGRectMake(location.origin.x,
                          (location.origin.y + location.size.height) - 25, //move it up three px from the bottom of the image
                          location.size.width,
                          22);
    UILabel *lblPage = [[UILabel alloc] initWithFrame:location];
    lblPage.tag = imageDetails.imageButton.tag + 2000;
    lblPage.backgroundColor = [UIColor clearColor];
    lblPage.textColor = [UIColor redColor];
    lblPage.textAlignment = NSTextAlignmentCenter;
    lblPage.text = [NSString stringWithFormat:@"Page %d", [pageNum intValue]];
    lblPage.font = [UIFont systemFontOfSize:14];
    [scrollView addSubview:lblPage];
}

-(void)imageSelected:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    editingIDX = btn.tag;
    SurveyImage *image = [addedImages objectAtIndex:editingIDX];
    
    UIImage *current = [[UIImage alloc] initWithContentsOfFile:image.path];
    oneImageViewImage.image = current;
    
    //begin the transition
    CATransition *transition = [CATransition animation];
    // Animate over .5 seconds
    transition.duration = 0.5;
    // using the ease in/out timing function
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromRight;
    
    // Next add it to the view's layer. This will perform the transition based on how we change its contents.
    [self.view.layer addAnimation:transition forKey:nil];
    
    allImagesView.hidden = YES;
    oneImageView.hidden = NO;
    
    self.navigationItem.title = [NSString stringWithFormat:@"Page %d", editingIDX+1];
    
    [self setNavigationItems];
}

-(IBAction)cmdDelete:(id)sender
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                 message:@"Would you like to remove this image from the Document?"
                                                delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"Yes", nil];
    av.tag = editingIDX;
    [av show];
}

-(IBAction)cmdSave:(id)sender
{
    if (addedImages == nil || [addedImages count] == 0)
    {
        [SurveyAppDelegate showAlert:@"At least one Page must be added to save Document." withTitle:@"No Pages Added"];
    }
    else
    {
        static double pixelsPerInch = 72.; // 72 ppi
        static double pdfPageWidth = 612.; // 8.5 in x 72 ppi
        static double pdfPageHeight = 792.; //11 in x 72 ppi
        static double padding = 21.6; // 0.3 in x 72 ppi
        static double resolution = 300.;
        
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        generateDocProgress = [[SmallProgressView alloc] initWithDefaultFrame:@"Generating Document"];
        
        [del.operationQueue addOperationWithBlock:^{
//            [NSThread sleepForTimeInterval:3.]; //sleep for 3 seconds
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSMutableData *pdfData = [[NSMutableData alloc] init];
            UIGraphicsBeginPDFContextToData(pdfData, CGRectZero, nil);
            
            for (SurveyImage *surveyImage in addedImages)
            {
                if (![fileManager fileExistsAtPath:surveyImage.path])
                    continue;
                
                UIImage *image = [[UIImage alloc] initWithContentsOfFile:surveyImage.path];
                
                double imageWidth = (image.size.width * image.scale * pixelsPerInch / resolution);
                double imageHeight = (image.size.height * image.scale * pixelsPerInch / resolution);
                double scale = ((pdfPageWidth - (padding * 2.)) / imageWidth);
                if (imageHeight * scale > (pdfPageHeight - (padding * 2.)))
                    scale = ((pdfPageHeight - (padding * 2.)) / imageHeight);
                imageWidth = (imageWidth * scale);
                imageHeight = (imageHeight * scale);
                
                UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pdfPageWidth, pdfPageHeight), nil);
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                //buggy, didn't handle image orientation when taken from camera
//                //flip it
//                CGContextTranslateCTM(context, 0, (imageHeight * scale));
//                CGContextScaleCTM(context, 1., -1.);
//                
//                //draw it
//                CGRect imageRect = CGRectMake(((pdfPageWidth - imageWidth) / 2.),
//                                              -((pdfPageHeight - imageHeight) / 2.), //because of flip, needs to be negative value
//                                              imageWidth, imageHeight);
//                CGContextDrawImage(context, imageRect, [image CGImage]);
                
                //draw it using method on UIImage object, handles picture orientation
                CGRect imageRect = CGRectMake(((pdfPageWidth - imageWidth) / 2.),
                                              ((pdfPageHeight - imageHeight) / 2.),
                                              imageWidth, imageHeight);
                [image drawInRect:imageRect];
                CGContextFlush(context);
                
            }
            
            UIGraphicsEndPDFContext();
            
            DocLibraryEntry *current = [[DocLibraryEntry alloc] init];
            
            current.docEntryType = DOC_LIB_TYPE_CUST;
            current.customerID = del.customerID;
            current.url = @"";
            current.docName = docLabel.text;
            [current saveDocument:pdfData withCustomerID:del.customerID];
            
            //done, go ahead and remove progress and dismiss view
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [generateDocProgress removeFromSuperview];
                [SurveyAppDelegate showAlert:@"Document successfuly saved." withTitle:@"Success"];
                [self deleteTempImages];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
        
        
        
        
    }
}

-(void)deleteTempImages
{
    if (addedImages != nil && [addedImages count] > 0)
    {
        while ([addedImages count] > 0)
            [self deleteTempImage:0];
        addedImages = nil;
    }
}

-(void)deleteTempImage:(int)index
{
    SurveyImage *image = [addedImages objectAtIndex:index];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error;
    if ([fileManager fileExistsAtPath:image.path])
    {
        if (![fileManager removeItemAtPath:image.path error:&error])
            [SurveyAppDelegate showAlert:[error localizedDescription] withTitle:@"Error Deleting File"];
    }
    else
        [SurveyAppDelegate showAlert:image.path withTitle:@"File not found"];
    
    [addedImages removeObjectAtIndex:index];
}

#pragma mark UIActionSheet methods
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [actionSheet cancelButtonIndex])
    {
        switch (buttonIndex) {
            case ACTION_SHEET_TAKE_NEW_PHOTO:
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                {
                    if (picker == nil)
                    {
                        self.picker = [[UIImagePickerController alloc] init];
                        self.picker.delegate = self;
                    }
                    
                    picker.allowsEditing = NO;
                    picker.sourceType =UIImagePickerControllerSourceTypeCamera;
                    
                    [self.navigationController presentViewController:picker animated:YES completion:nil];
                }
                else
                {
                    [SurveyAppDelegate showAlert:@"This device does not have a camera.  Unable to add new photo." withTitle:@"Error"];
                }
                break;
            case ACTION_SHEET_ADD_EXISTING_PHOTO:
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
                {
                    if (picker == nil)
                    {
                        self.picker = [[UIImagePickerController alloc] init];
                        self.picker.delegate = self;
                    }
                    
                    picker.allowsEditing = NO;
                    picker.sourceType =UIImagePickerControllerSourceTypePhotoLibrary;
                    
                    
                    [self.navigationController presentViewController:picker animated:YES completion:nil];
                }
                else
                {
                    [SurveyAppDelegate showAlert:@"Unable to access photo library on this device.  Unable to add new photo." withTitle:@"Error"];
                }
                break;
        }
    }
}


#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex])
    {
        [self viewWillDisappear:YES];
        
        [self deleteTempImage:editingIDX];
        
        self.oneImageView.hidden = YES;
        self.allImagesView.hidden = NO;
        
        self.navigationItem.title = @"Attach Document";
        
        [self setNavigationItems];
        
        [self viewWillAppear:YES];
    }
}

#pragma mark UIImagePickerController methods
-(void)imagePickerController:(UIImagePickerController *)imgPicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [imgPicker dismissViewControllerAnimated:YES completion:nil];
    picker = nil;
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *attachDocTempDir = [SurveyAppDelegate getAttachDocTempDirectory];
    
    NSError *err;
    BOOL isDir;
    if (![fileManager fileExistsAtPath:attachDocTempDir isDirectory:&isDir])
    {
        if(![fileManager createDirectoryAtPath:attachDocTempDir withIntermediateDirectories:YES attributes:nil error:&err])
        {
            [SurveyAppDelegate showAlert:[err localizedDescription] withTitle:@"Error Creating Directory"];
            return;
        }
    }
    
    if (addedImages == nil)
        addedImages = [[NSMutableArray alloc] init];
    
    SurveyImage *surveyImage = [[SurveyImage alloc] init];
    surveyImage.path = [attachDocTempDir stringByAppendingPathComponent:
                        [NSString stringWithFormat:@"%@.jpg", [SurveyAppDelegate formatDateAndTime:[NSDate date] withDateFormat:@"YYYYmmddHHMMSS"]]];
    
    //prevent us from overwriting an existing file
    while ([fileManager fileExistsAtPath:surveyImage.path]) {
        surveyImage.path = [attachDocTempDir stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@_2.jpg", [SurveyAppDelegate formatDateAndTime:[NSDate date] withDateFormat:@"YYYYmmddHHMMSS"]]];
    }
    
    if (![fileManager createFileAtPath:surveyImage.path contents:imageData attributes:nil])
        [SurveyAppDelegate showAlert:surveyImage.path withTitle:@"Error Creating File"];
    else
        [addedImages addObject:surveyImage];
    
    
    [self viewWillAppear:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)imgPicker
{
    [imgPicker dismissViewControllerAnimated:YES completion:nil];
    picker = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setOneImageView:nil];
    [self setOneImageViewImage:nil];
    [self setAllImagesView:nil];
    [self setScrollView:nil];
    [self setDocLabel:nil];
    [super viewDidUnload];
}
@end
