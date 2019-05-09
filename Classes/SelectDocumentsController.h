//
//  SelectDocumentsController.h
//  Survey
//
//  Created by Chris Jenkins on 9/3/15.
//
//

#import <UIKit/UIKit.h>

@interface SelectDocumentsController : UITableViewController
{
    NSMutableArray *docs;
}

@property (nonatomic, retain) NSMutableArray *docs;

@end