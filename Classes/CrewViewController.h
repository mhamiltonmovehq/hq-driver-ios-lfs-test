//
//  CrewViewController.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 1/12/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CrewViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

NS_ASSUME_NONNULL_END
