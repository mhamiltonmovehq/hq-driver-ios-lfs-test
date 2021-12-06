//
//  ActivationErrorController.h
//  Survey
//
//  Created by Tony Brame on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ActivationErrorController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
}

@property (nonatomic, retain) UITableView *tv;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) UITextView *tboxMessage;
@property (retain, nonatomic) IBOutlet UIButton *btnEnter_Credentials;

- (IBAction)cmdEnter_Credentials:(id)sender;

@end
