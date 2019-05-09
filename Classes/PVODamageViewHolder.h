//
//  PVODamageViewHolder.h
//  Survey
//
//  Created by Tony Brame on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PVODamageButtonController.h"
#import "PVODamageWheelController.h"
#import "PVOItemDetail.h"
#import "DriverData.h"
#import "PortraitNavController.h"

@class PVODamageViewHolder;
@protocol PVODamageViewHolderDelegate <NSObject>
@optional
-(void)wireframeDamagesChosen:(PVODamageViewHolder*)controller;
@end

//had to create this class since the App delegate couldnt conform to the UIAlertViewDelegate - can remove thisw once there is no longer an alert between screens.

@interface PVODamageViewHolder : NSObject <UIAlertViewDelegate> {
    PVODamageWheelController *wheelDamageController;
    PVODamageButtonController *buttonDamageController;
    PortraitNavController *nav;
    PVOItemDetail *item;
    BOOL nextItemButton;
    BOOL withWireframe;
    DriverData *driverInfo;
    
    int pvoLoadID;
    int pvoUnloadID;
    
    id<PVODamageControllerDelegate> delegate;
}

@property (nonatomic, retain) id<PVODamageControllerDelegate> delegate;
@property (nonatomic, retain) PVODamageWheelController *wheelDamageController;
@property (nonatomic, retain) PVODamageButtonController *buttonDamageController;
@property (nonatomic, retain) PortraitNavController *nav;
@property (nonatomic, retain) PVOItemDetail *item;
@property (nonatomic) BOOL withWireframe;

-(void)showWithWireframeOption:(BOOL)showNextItemButton;
-(void)show:(BOOL)showNextItemButton withLoadID:(int)loadID;
-(void)show:(BOOL)showNextItemButton withUnloadID:(int)unloadID;
-(void)show:(BOOL)showNextItemButton;

-(void)loadButtonController;
-(void)loadWheelController;

@end
