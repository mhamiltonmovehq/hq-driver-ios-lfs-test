//
//  UIItemTable.m
//  Survey
//
//  Created by Tony Brame on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UIItemTable.h"
#import "SurveyAppDelegate.h"

@implementation PassTouchPoint

@synthesize point;

@end


@implementation UIItemTable

@synthesize rightCallback, leftCallback, caller, justProcessedSwipe;


#define MIN_X_DRAG 100

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	justProcessedSwipe = FALSE;
	[self setScrollEnabled:FALSE];
	UITouch *touch = [touches anyObject];
	mystartTouchPosition = [touch locationInView:self];
	//goneOverYDiff = FALSE;
	
	[super touchesBegan:touches withEvent:event];
	
	//NSLog(@"table touchesBegan");
}	

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	CGPoint newTouch = [[touches anyObject] locationInView:self];
	//double Ychange = abs(mystartTouchPosition.y - newTouch.y) + 0.01;
	
	double Xchange = (mystartTouchPosition.x - newTouch.x) + 0.01;
	
	BOOL right = Xchange < 0;
	if(right)
		Xchange *= -1;
	
	if(Xchange > MIN_X_DRAG)
	{
		//the alert causes no touchesEnded to be sent, which makes for some problems with selecting the 
		//row agin.  i dont think this will be an issue when pushing another view, since the queue should
		//be cleared when it reloads...
		
		PassTouchPoint *pt = [[PassTouchPoint alloc] init];
		pt.point = mystartTouchPosition;
		
		if(right)
		{
			//NSLog(@"RIGHT");
			if([caller respondsToSelector:rightCallback])
			{
				[caller performSelector:rightCallback withObject:pt];
			}
		}
		//NSLog(@"RIGHT");
		//[SurveyAppDelegate showAlert:@"" withTitle:@"Right"];
		else
		{
			//NSLog(@"LEFT");
			if([caller respondsToSelector:leftCallback])
			{
				[caller performSelector:leftCallback withObject:pt];
			}
		}
				
		//send an up-touch to account for the one left out
		[self touchesEnded:touches withEvent:event];
		
		justProcessedSwipe = TRUE;
		
		//NSLog(@"LEFT");
		//[SurveyAppDelegate showAlert:@"" withTitle:@"Left"];
	}
	else
		[super touchesMoved:touches withEvent:event];
	
	//NSLog(@"table touchesMoved");
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[self setScrollEnabled:YES];
	[super touchesEnded:touches withEvent:event];
	//NSLog(@"table touchesEnded");
}

@end
