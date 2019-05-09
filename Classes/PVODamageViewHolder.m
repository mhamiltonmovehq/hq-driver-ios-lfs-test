//
//  PVODamageViewHolder.m
//  Survey
//
//  Created by Tony Brame on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVODamageViewHolder.h"
#import "SurveyAppDelegate.h"

@implementation PVODamageViewHolder

@synthesize wheelDamageController;
@synthesize buttonDamageController;
@synthesize nav, delegate;
@synthesize item;
@synthesize withWireframe;

-(void)show:(BOOL)showNextItemButton withLoadID:(int)loadID
{
    pvoLoadID = loadID;
    pvoUnloadID = 0;
    if (withWireframe)
        [self showWithWireframeOption:showNextItemButton];
    else
        [self show:showNextItemButton];
}

-(void)show:(BOOL)showNextItemButton withUnloadID:(int)unloadID
{
    pvoLoadID = 0;
    pvoUnloadID = unloadID;
    if (withWireframe)
        [self showWithWireframeOption:showNextItemButton];
    else
        [self show:showNextItemButton];
}

-(void)show:(BOOL)showNextItemButton
{
    nextItemButton = showNextItemButton;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    if(data.buttonPreference == PVO_DRIVER_DAMAGE_BUTTON)
        [self loadButtonController];
    else if(data.buttonPreference == PVO_DRIVER_DAMAGE_WHEEL)
        [self loadWheelController];
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"View Type" 
                                                        message:@"Please select the view type for the damage controller" 
                                                       delegate:self 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:@"Button", @"Wheel", @"Button, Don't Ask Again", @"Wheel, Don't Ask Again", nil];
        [alert show];
        
    }
}

-(void)showWithWireframeOption:(BOOL)showNextItemButton
{
    nextItemButton = showNextItemButton;
    
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    DriverData *data = [del.surveyDB getDriverData];
    if(data.buttonPreference == PVO_DRIVER_DAMAGE_BUTTON)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"View Type"
                                                        message:@"Please select the view type for the damage controller"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Button", @"Wireframe Image", nil];
        [alert show];
        
    }
    else if(data.buttonPreference == PVO_DRIVER_DAMAGE_WHEEL)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"View Type"
                                                        message:@"Please select the view type for the damage controller"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Wheel", @"Wireframe Image", nil];
        [alert show];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"View Type"
                                                        message:@"Please select the view type for the damage controller"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Button", @"Wheel", @"Wireframe Image", @"Button, Don't Ask Again", @"Wheel, Don't Ask Again", nil];
        [alert show];
        
    }
}

-(void)loadButtonController
{
    if(buttonDamageController == nil)
        buttonDamageController = [[PVODamageButtonController alloc] initWithNibName:@"PVODamageButtonView" bundle:nil];
    buttonDamageController.title = @"Damage";
    buttonDamageController.details = item;
    buttonDamageController.showNextItem = nextItemButton;
    buttonDamageController.pvoLoadID = pvoLoadID;
    buttonDamageController.pvoUnloadID = pvoUnloadID;
    buttonDamageController.delegate = delegate;
    [nav pushViewController:buttonDamageController animated:YES];
}

-(void)loadWheelController
{
    if(wheelDamageController == nil)
        wheelDamageController = [[PVODamageWheelController alloc] initWithNibName:@"PVODamageWheelView" bundle:nil];
    wheelDamageController.title = @"Damage";
    wheelDamageController.details = item;
    wheelDamageController.showNextItem = nextItemButton;
    wheelDamageController.pvoLoadID = pvoLoadID;
    wheelDamageController.pvoUnloadID = pvoUnloadID;
    wheelDamageController.delegate = delegate;
    [nav pushViewController:wheelDamageController animated:YES];
}

#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex != [alertView cancelButtonIndex])
    {
        if (withWireframe)
        {
            SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
            DriverData *data = [del.surveyDB getDriverData];
            if(data.buttonPreference == PVO_DRIVER_DAMAGE_BUTTON)
            {
                if(buttonIndex == 0)
                    [self loadButtonController];
                else
                {
                    //call back to delegate and load the wireframe controller
                    if (delegate != nil && [delegate respondsToSelector:@selector(wireframeDamagesChosen:)])
                        [delegate performSelector:@selector(wireframeDamagesChosen:) withObject:self];
                }
            }
            else if(data.buttonPreference == PVO_DRIVER_DAMAGE_WHEEL)
            {
                if(buttonIndex == 0)
                    [self loadWheelController];
                else
                {
                    //call back to delegate and load the wireframe controller
                    if (delegate != nil && [delegate respondsToSelector:@selector(wireframeDamagesChosen:)])
                        [delegate performSelector:@selector(wireframeDamagesChosen:) withObject:self];
                }
            }
            else
            {
                if(buttonIndex == 0 || buttonIndex == 3)
                {
                    [self loadButtonController];
                    
                    if(buttonIndex == 3)
                    {
                        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                        DriverData *data = [del.surveyDB getDriverData];
                        data.buttonPreference = PVO_DRIVER_DAMAGE_BUTTON;
                        [del.surveyDB updateDriverData:data];
                    }
                }
                else if(buttonIndex == 1 || buttonIndex == 4)
                {
                    [self loadWheelController];
                    
                    if(buttonIndex == 4)
                    {
                        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                        DriverData *data = [del.surveyDB getDriverData];
                        data.buttonPreference = PVO_DRIVER_DAMAGE_WHEEL;
                        [del.surveyDB updateDriverData:data];
                    }
                }
                else if(buttonIndex == 2)
                {
                    //call back to delegate and load the wireframe controller
                    if (delegate != nil && [delegate respondsToSelector:@selector(wireframeDamagesChosen:)])
                        [delegate performSelector:@selector(wireframeDamagesChosen:) withObject:self];
                }
            }
        }
        else
        {
        
            if(buttonIndex == 0 || buttonIndex == 2)
            {
                [self loadButtonController];
                
                if(buttonIndex == 2)
                {
                    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                    DriverData *data = [del.surveyDB getDriverData];
                    data.buttonPreference = PVO_DRIVER_DAMAGE_BUTTON;
                    [del.surveyDB updateDriverData:data];
                }
            }
            else if(buttonIndex == 1 || buttonIndex == 3)
            {
                [self loadWheelController];
                
                if(buttonIndex == 3)
                {
                    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
                    DriverData *data = [del.surveyDB getDriverData];
                    data.buttonPreference = PVO_DRIVER_DAMAGE_WHEEL;
                    [del.surveyDB updateDriverData:data];
                }
            }
        }
    }
}

@end
