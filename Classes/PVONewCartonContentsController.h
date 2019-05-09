//
//  PVONewCartonContentsController.h
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVOCartonContent.h"

#define PVO_NEW_CONTENTS_NAME 0
#define PVO_NEW_CONTENTS_CODE 1

@class PVONewCartonContentsController;
@class PVOCartonContent;

@protocol PVONewCartonContentsControllerDelegate <NSObject>
@optional
-(void)addContentsController:(PVONewCartonContentsController*)controller addedContent:(PVOCartonContent*)item;
@end


@interface PVONewCartonContentsController : UITableViewController <UITextFieldDelegate> {
    PVOCartonContent *content;
    UITextField *tboxCurrent;
    id<PVONewCartonContentsControllerDelegate> delegate;
}

@property (nonatomic, strong) PVOCartonContent *content;
@property (nonatomic, strong) UITextField *tboxCurrent;
@property (nonatomic, strong) id<PVONewCartonContentsControllerDelegate> delegate;


-(IBAction)textFieldDoneEditing:(id)sender;
-(void)updateValueWithField:(id)field;

-(IBAction)saveItem:(id)sender;
-(IBAction)cancel:(id)sender;

@end
