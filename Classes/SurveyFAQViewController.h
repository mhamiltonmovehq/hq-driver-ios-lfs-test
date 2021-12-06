//
//  SurveyFAQViewController.h
//  Survey
//
//  Created by Tony Brame on 2/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface SurveyFAQListItem : NSObject {
	NSString *url;
	NSString *description;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *description;

@end



@interface SurveyFAQViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView *tableView;
	IBOutlet WKWebView *webView;
	IBOutlet UIActivityIndicatorView *activityView;
	
	NSMutableArray *choices;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;

@property (nonatomic, retain) NSMutableArray *choices;

-(IBAction)cmdDone_click:(id)sender;

@end
