//
//  PVOAttachDocControllerViewController.h
//  Survey
//
//  Created by Lee Zumstein on 8/19/14.
//
//

#import <UIKit/UIKit.h>
#import "PVOAttachDocItem.h"
#import "SurveyImage.h"
#import "SmallProgressView.h"

#define ACTION_SHEET_TAKE_NEW_PHOTO 0
#define ACTION_SHEET_ADD_EXISTING_PHOTO 1

@interface PVOAttachDocController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate,
        UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    int editingIDX;
}

@property (nonatomic, strong) UIView *caller;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIImagePickerController *picker;

@property (strong, nonatomic) IBOutlet UIView *oneImageView;
@property (strong, nonatomic) IBOutlet UIImageView *oneImageViewImage;
@property (strong, nonatomic) IBOutlet UIView *allImagesView;
@property (strong, nonatomic) IBOutlet UILabel *docLabel;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) int navItemID;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSArray *attachDocOptions;
@property (nonatomic, strong) PVOAttachDocItem *selectedDoc;
@property (nonatomic, strong) NSMutableArray *addedImages;

@property (nonatomic) BOOL firstLoad;
@property (nonatomic, strong) SmallProgressView *generateDocProgress;

-(void)promptForDocument;
-(void)attachDocSelected:(NSNumber*)index;

-(IBAction)cmdDelete:(id)sender;
-(IBAction)cmdSave:(id)sender;

-(void)setNavigationItems;
-(void)cancelOrDoneSelected:(id)sender;

-(void)loadImage:(SurveyImage*)imageDetails;
-(void)imageLoaded:(NSArray*)data;
-(void)imageSelected:(id)sender;
-(void)deleteTempImages;
-(void)deleteTempImage:(int)index;

@end
