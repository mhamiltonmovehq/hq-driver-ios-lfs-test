//
//  PVOCommentsController.h
//  MobileMover
//
//  Created by David Yost on 9/15/15.
//  Copyright (c) 2015 IGC Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PVOCommentsController;
@protocol PVOCommentsControllerDelegate <NSObject>
@optional
-(void)commentControllerWillDisappear:(PVOCommentsController*)controller;
@end

@interface PVOCommentsController : UIViewController
{
    id<PVOCommentsControllerDelegate> delegate;
}

@property (nonatomic, retain) id<PVOCommentsControllerDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITextView *tboxComments;

@end
