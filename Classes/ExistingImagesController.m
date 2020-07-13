//
//  ExistingImagesController.m
//  Survey
//
//  Created by Tony Brame on 7/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ExistingImagesController.h"
#import "SurveyAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "SurveyImage.h"
#import "SurveyImageViewer.h"
#import "PVOAutoInventoryController.h"
#import "PVOBulkyInventoryController.h"

@implementation ExistingImagesController
@synthesize lblOneImageDate;
@synthesize cmdDelete;

@synthesize scrollView, navBar, imagePaths, imageViewer, singleDamage, photosType, subID, oneImageView, oneImageViewImage;
@synthesize wireframeItemID;
@synthesize isOrigin, isAutoInventory;

-(IBAction)finishedEditing:(id)sender
{
	if(oneImageView.hidden)
        [self dismissViewControllerAnimated:YES completion:nil];
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
		scrollView.hidden = NO;
        
        oneImageViewImage.image = nil;
	}
	
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Images";
    
    if (photosType == IMG_PVO_VEHICLE_DAMAGES && subID == VT_PHOTO)
    {
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addImage:)];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(vehicleDone:)];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:addButton, doneButton, nil];
    }
    else
    {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishedEditing:)];
        self.navigationItem.leftBarButtonItem = doneButton;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}


-(void)viewWillAppear:(BOOL)animated
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (photosType == IMG_PVO_VEHICLE_DAMAGES)
    {
        NSMutableArray *imagesArray = [del.surveyDB getImagesList:del.customerID withPhotoType:photosType withSubID:subID loadAllItems:0];
        
        //NOTE: if the images are tied to vehicles the "getImageList" method pulls all vehicles for a photo type so we need to narrow it down to the vehicle in question...
        NSMutableArray *wireframeImages = [del.surveyDB getAllVehicleImages:wireframeItemID withCustomerID:del.customerID];
        NSMutableArray *finalImageList = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [imagesArray count]; i++)
        {
            SurveyImage *image = imagesArray[i];
            if ([wireframeImages containsObject:[NSNumber numberWithInt:image.imageID]])
            {
                [finalImageList addObject:image];
            }
        }
        
        self.imagePaths = finalImageList;

        
        //self.imagePaths = [del.surveyDB getImagesList:del.customerID withPhotoType:photosType withSubID:subID loadAllItems:0];
    }
    
	//hide oneImageView
	oneImageView.hidden = YES;
    
	//here is where i will add all of the images.
	//loop through my images, and create thumbnails
	CGSize imageSize;
	imageSize.width = 100;
	imageSize.height = 100;
	
	int buffer = 5;
	
	int added = 0;
	int currenty = 0;
    
	//remove all subviews from scroll
    //	for(int i = [scrollView.subviews count]-1; i >= 0 ; i--)
    //	{
    //		[[scrollView.subviews objectAtIndex:i] removeFromSuperview];
    //	}
    
	
	//get the current docs directory
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *header = @"", *temp = @"";
    
    int i = 0;
    for (SurveyImage *surveyImage in imagePaths)
    {
		NSString *inDocsPath = surveyImage.path;
		NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
		if([fileManager fileExistsAtPath:fullPath])
		{
            header = [del.surveyDB getImageDescription:surveyImage];
            if(![header isEqualToString:temp])
            {
                
                //start new section, add header
                temp = [NSString stringWithString:header];
                if(currenty != 0)//new row...
                    currenty += buffer + imageSize.height;
                
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, currenty, self.view.bounds.size.width, 30)];
                [view setBackgroundColor:[UIColor lightGrayColor]];
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.bounds.size.width * .9, 30)];
                lbl.text = header;
                [lbl setBackgroundColor:[UIColor clearColor]];
                
                [view addSubview:lbl];
                
                [scrollView addSubview:view];
                
                currenty += view.frame.size.height + buffer;
                
                added = 0;
            }
            else if(added % 3 == 0)//new row
                currenty += buffer + imageSize.height;
            
			CGRect location = CGRectMake(buffer + ((added % 3) * (buffer + imageSize.width)),
										 currenty,
										 imageSize.width,
										 imageSize.height);
			surveyImage.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
			surveyImage.imageButton.frame = location;
            [surveyImage.imageButton setBackgroundColor:[UIColor blackColor]];
            
            //lazy load this image
			//current = [UIImage imageWithContentsOfFile:fullPath];
			//[surveyImage.imageButton setBackgroundImage:current forState:UIControlStateNormal];
			
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
            
            NSOperationQueue *queue = [NSOperationQueue new];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(loadImage:)
                                                object:surveyImage];
            [queue addOperation:operation];
            
			added++;
		}
        i++;
	}
	
	scrollView.contentSize = CGSizeMake(315, currenty + buffer + imageSize.height);
	
	//self.view.frame = CGRectMake(0, 0, 320, 416);
	//scrollView.frame = CGRectMake(0, 0, 320, 416);
	//[self.view addSubview:scrollView];
	scrollView.hidden = NO;
	
	
	
	
	[super viewWillAppear:animated];
}

-(IBAction)addImage:(id)sender
{
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(imageViewer == nil)
        imageViewer = [[SurveyImageViewer alloc] init];
    
    imageViewer.photosType = IMG_PVO_VEHICLE_DAMAGES;
//    imageViewer.vehicle = vehicle;
    imageViewer.wireframeItemID = wireframeItemID;
    imageViewer.subID = subID;
    imageViewer.customerID = del.customerID;
    
    imageViewer.caller = self.view;
    
    imageViewer.viewController = self;
    
    [imageViewer loadPhotos];
    
}

- (IBAction)vehicleDone:(id)sender
{
    //jump back to nav list
    //Vehicle damages can be accessed from "bulky inventory" and legacy auto inventory... need better handling
    if (isAutoInventory)
    {
        PVOAutoInventoryController *navController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOAutoInventoryController class]])
                navController = view;
        }
        [self.navigationController popToViewController:navController animated:YES];
    }
    else
    {
        //next item... so jump back to item list, and tap add button...
        PVOBulkyInventoryController *itemController = nil;
        for (id view in [self.navigationController viewControllers]) {
            if([view isKindOfClass:[PVOBulkyInventoryController class]])
                itemController = view;
        }
        
        [self.navigationController popToViewController:itemController animated:YES];
    }
}

-(void)loadImage:(SurveyImage*)imageDetails
{
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *inDocsPath = imageDetails.path;
    NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
    
	CGSize imageSize;
	imageSize.width = 100;
	imageSize.height = 100;
    
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:fullPath];
    
    UIImage *newimg = [SurveyAppDelegate resizeImage:img withNewSize:imageSize];
    
    NSArray *array = [[NSArray alloc] initWithObjects:imageDetails, newimg, nil];
    [self performSelectorOnMainThread:@selector(imageLoaded:) 
                           withObject:array
                        waitUntilDone:YES];
 
}

-(void)imageLoaded:(NSArray*)data
{
    SurveyImage *imageDetails = [data objectAtIndex:0];
    UIImage *image = [data objectAtIndex:1];
    
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    NSString *inDocsPath = imageDetails.path;
    NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attribs;
    NSDate *create;
    UILabel *lblDateTime;
    CGRect location;
    
    //remove spinner
    [[imageDetails.imageButton viewWithTag:1000] removeFromSuperview];
    
    [imageDetails.imageButton setBackgroundImage:image forState:UIControlStateNormal];
    
    cmdDelete.enabled = YES;
    
    attribs = [fileManager attributesOfItemAtPath:fullPath error:nil];
    if(attribs != nil)
    {
        if([attribs objectForKey:NSFileCreationDate] != nil)
        {
            location = imageDetails.imageButton.frame;
            create = [attribs objectForKey:NSFileCreationDate];
            location = CGRectMake(location.origin.x,
                                  (location.origin.y + location.size.height) - 25, //move it up three px from the bottom of the image 
                                  location.size.width, 
                                  22);
            lblDateTime = [[UILabel alloc] initWithFrame:location];
            lblDateTime.backgroundColor = [UIColor clearColor];
            lblDateTime.textColor = [UIColor redColor];
            lblDateTime.textAlignment = NSTextAlignmentCenter;
            lblDateTime.text = [SurveyAppDelegate formatDate:create];
            lblDateTime.font = [UIFont systemFontOfSize:14];
            [scrollView addSubview:lblDateTime];
        }
    }
}

-(void)imageSelected:(id)sender
{
	UIButton *btn = (UIButton*)sender;
	editingIDX = btn.tag;
	
	//get the current docs directory
	NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
	
	SurveyImage *image = [imagePaths objectAtIndex:btn.tag];
	NSString *inDocsPath = image.path;
	NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
	
    UIImage *current = [[UIImage alloc] initWithContentsOfFile:fullPath];
	
    if (photosType == IMG_PVO_VEHICLE_DAMAGES && subID == VT_PHOTO)
    {
        if(singleDamage == nil)
            singleDamage = [[PVODamageSingleController alloc] initWithNibName:@"PVODamageSingleView" bundle:nil];
        
        LandscapeNavController *navCtl = [[LandscapeNavController alloc] initWithRootViewController:singleDamage];
        navCtl.modalPresentationStyle = UIModalPresentationFullScreen;

        //navCtl.navigationBar.barStyle = UIBarStyleBlack;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        
//        singleDamage.vehicle = vehicle;
        singleDamage.wireframeItemID = wireframeItemID;
//        singleDamage.wireframeTypeID = wireframeTypeID;
        singleDamage.viewType = VT_PHOTO;
        singleDamage.imageId = image.imageID;
        singleDamage.photo =  current;
        singleDamage.isOrigin = isOrigin;
        singleDamage.isAutoInventory = isAutoInventory;
        
        [self presentViewController:navCtl animated:YES completion:nil];
        
        //[SurveyAppDelegate setDefaultBackButton:self];
        //[self.navigationController pushViewController:singleDamage animated:YES];
    }
    else
    {
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
	
	scrollView.hidden = YES;
	oneImageView.hidden = NO;
	
        //put date time stamp on it
    	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *attribs = [fileManager attributesOfItemAtPath:fullPath error:nil];
    	if(attribs != nil)
    	{
        	if([attribs objectForKey:NSFileCreationDate] != nil)
        	{
//            		NSDate *create = [attribs objectForKey:NSFileCreationDate];
//            		lblOneImageDate.text = [SurveyAppDelegate formatDate:create];
	            	lblOneImageDate.text = @"";
        	}
    	}
    }
}

- (IBAction)cmdEmailClick:(id)sender 
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Action With Image"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Email", @"Save To Camera Roll", @"Copy To Clipboard", nil];
    [as showInView:self.view];
    
}

-(IBAction)deleteImage:(id)sender
{
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                 message:@"Would you like to remove the selected photo?"
                                                delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"Yes", nil];
	av.tag = editingIDX;
	[av show];
	
	
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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

-(void)viewWillDisappear:(BOOL)animated
{
    for (id view in scrollView.subviews) {
        //make sure i get rid of cahced images
        if([view class] == [UIButton class])
            [view setBackgroundImage:nil forState:UIControlStateNormal];
        
        [view removeFromSuperview];
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    for (id view in scrollView.subviews) {
        //make sure i get rid of cahced images
        if([view class] == [UIButton class])
            [view setBackgroundImage:nil forState:UIControlStateNormal];
        
        [view removeFromSuperview];
    }
    
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
    [self setCmdDelete:nil];
    [self setLblOneImageDate:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [alertView cancelButtonIndex])
	{
		[self viewWillDisappear:YES];
        
		SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
		SurveyImage *image = [imagePaths objectAtIndex:alertView.tag];
		[del.surveyDB deleteImageEntry:image.imageID];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
		NSString *inDocsPath = image.path;
		NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
		NSError *error;
		if([fileManager fileExistsAtPath:fullPath])
		{
			if(![fileManager removeItemAtPath:fullPath error:&error])
			{
				[SurveyAppDelegate showAlert:[error localizedDescription] withTitle:@"Error Deleting File"];
			}
		}
		else
		{
			[SurveyAppDelegate showAlert:fullPath withTitle:@"File not found"];
		}
		
		[imagePaths removeObjectAtIndex:alertView.tag];
		
		[self viewWillAppear:YES];
	}
}

#pragma mark UIActionSheet methods

-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex != [actionSheet cancelButtonIndex])
	{
        NSString *appName = @"Mobile Mover";
#ifdef ATLASNET
        appName = @"AtlasNet";
#endif
        //get the current docs directory
        NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
        
        SurveyImage *image = [imagePaths objectAtIndex:editingIDX];
        NSString *inDocsPath = image.path;
        NSString *fullPath = [docsDir stringByAppendingPathComponent:inDocsPath];
        
        UIImage *current = [UIImage imageWithContentsOfFile:fullPath];
        
		if(buttonIndex == 0)
        {
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                
                mailer.mailComposeDelegate = self;
                [mailer setSubject:[NSString stringWithFormat:@"%@ Image", appName]];
                
                NSData *imageData = UIImageJPEGRepresentation(current, 1.0);
                [mailer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"image.jpeg"];
                
                NSString *emailBody = @"Please review the attached image.";
                [mailer setMessageBody:emailBody isHTML:NO];
                
                [self presentViewController:mailer animated:YES completion:nil];
                
                
            }
            else
                [SurveyAppDelegate showAlert:@"Your device doesn't support this functionality." withTitle:@"Unable To Email"];
        }
        else if (buttonIndex == 1)
        {
            UIImageWriteToSavedPhotosAlbum(current, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        else if (buttonIndex == 2)
        {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            NSData *imageData = UIImageJPEGRepresentation(current, 1.0);
            [pasteboard setData:imageData forPasteboardType:(id)kUTTypeJPEG];
            //[pasteboard setData:imageData forPasteboardType:@"image.jpeg"];
        }
	}
	
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL)
        [SurveyAppDelegate showAlert:[error localizedDescription] withTitle:@"Image Save Error"];
    else
        [SurveyAppDelegate showAlert:@"Image Saved to camera roll successfully." withTitle:@"Success"];
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultFailed)
        [SurveyAppDelegate showAlert:@"Send Failed, unable to send email." withTitle:@"Unable To Email"];
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
