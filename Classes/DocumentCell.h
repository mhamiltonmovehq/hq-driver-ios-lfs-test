//
//  DocumentCell.h
//  Survey
//
//  Created by DThomas on 8/11/14.
//
//

#import <UIKit/UIKit.h>

@interface DocumentCell : UITableViewCell{
    
    IBOutlet UITextField *tboxDocuments;
    IBOutlet UIImageView *tboxCheck;
    IBOutlet UILabel *tboxDocumentsLabel;
}

@property (strong, nonatomic) IBOutlet UITextField *tboxDocuments;
@property (strong, nonatomic) IBOutlet UIImageView *tboxCheck;
@property (strong, nonatomic) IBOutlet UILabel *tboxDocumentsLabel;

@end
