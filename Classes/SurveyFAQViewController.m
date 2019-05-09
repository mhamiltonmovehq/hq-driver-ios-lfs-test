    //
//  SurveyFAQViewController.m
//  Survey
//
//  Created by Tony Brame on 2/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SurveyFAQViewController.h"

@implementation SurveyFAQListItem

@synthesize url, description;

@end



@implementation SurveyFAQViewController

@synthesize tableView, webView, choices, activityView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	self.title = @"Frequently Asked Questions";
	
	self.choices = [NSMutableArray array];
	SurveyFAQListItem *current;
	for(int i = 0; i < 5; i++)
	{
		current = [[SurveyFAQListItem alloc] init];
		switch (i) {
			case 0:
				current.url = @"aWk267TX_0U";
				current.description = @"Find & Survey a Bulky Item";
				break;
			case 1:
				current.url = @"toKa45SLjm4";
				current.description = @"Hide Items/Rooms in Cubesheet";
				break;
			case 2:
				current.url = @"qjubSJkyEuM";
				current.description = @"Survey and Price a Crate";
				break;
			case 3:
				current.url = @"jsfFCQdhG1w";
				current.description = @"Add a New Item to Cubesheet";
				break;
			case 4:
				current.url = @"vGb76edKK0c";
				current.description = @"Add Custom Unpacking";
				break;
		}
		[choices addObject:current];
		
	}
	
    [super viewDidLoad];
}

-(IBAction)cmdDone_click:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [choices count];;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = nil;
	
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	SurveyFAQListItem *item = [choices objectAtIndex:indexPath.row];
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = item.description;
	
	cell.imageView.image = [UIImage imageNamed:@"icon_youtube.png"];
	   
	
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	SurveyFAQListItem *item = [choices objectAtIndex:indexPath.row];
	
	NSString *htmlString = [NSString stringWithFormat:@"<html><head>"
	"<meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = 212\"/></head>"
	"<body style=\"background:#F00;margin-top:0px;margin-left:0px\">"
	"<div><object width=\"212\" height=\"172\">"
	"<param name=\"movie\" value=\"http://www.youtube.com/v/%@&f=gdata_videos&c=ytapi-my-clientID&d=nGF83uyVrg8eD4rfEkk22mDOl3qUImVMV6ramM\"></param>"
	"<param name=\"wmode\" value=\"transparent\"></param>"
	"<embed src=\"http://www.youtube.com/v/%@&f=gdata_videos&c=ytapi-my-clientID&d=nGF83uyVrg8eD4rfEkk22mDOl3qUImVMV6ramM\""
	"type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"212\" height=\"172\"></embed>"
	"</object></div></body></html>", item.url, item.url];
	
	[webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://www.your-url.com"]];
	
	tableView.hidden = YES;
	webView.hidden = YES;
	
}


@end
