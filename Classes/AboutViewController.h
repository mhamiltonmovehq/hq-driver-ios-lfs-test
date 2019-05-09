//
//  AboutViewController.h
//  Survey
//
//  Created by Tony Brame on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

 
@interface AboutViewController : UIViewController {
    IBOutlet UILabel *labelVersion;
    IBOutlet UILabel *labelCopyright;
    IBOutlet UITextView *viewHeaders;
    IBOutlet UITextView *viewData;
    UIImageView *imgLogo;
}

@property (strong, nonatomic) IBOutlet UIImageView *imgLogo;
@property (nonatomic, strong) UILabel *labelVersion;
@property (nonatomic, strong) UILabel *labelCopyright;
@property (nonatomic, strong) UITextView *viewHeaders;
@property (nonatomic, strong) UITextView *viewData;
@property (nonatomic, strong) IBOutlet UILabel *labelBuildConfiguration;

-(IBAction)done:(id)sender;

@end
