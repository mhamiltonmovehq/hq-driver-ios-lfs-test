//
//  DetailViewController.h
//  Mobile Mover Auto
//
//  Created by David Yost on 11/18/15.
//
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

