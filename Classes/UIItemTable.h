//
//  UIItemTable.h
//  Survey
//
//  Created by Tony Brame on 11/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PassTouchPoint : NSObject
{
	CGPoint point;
}

@property (nonatomic) CGPoint point;

@end



@interface UIItemTable : UITableView {
	CGPoint mystartTouchPosition;
	BOOL goneOverYDiff;
	
	NSObject *caller;
	SEL rightCallback;
	SEL leftCallback;
	//had to add this so it didnt reselect the row when the user lifted their finger.
	BOOL justProcessedSwipe;
}

@property (nonatomic) SEL rightCallback;
@property (nonatomic) SEL leftCallback;
@property (nonatomic) BOOL justProcessedSwipe;
@property (nonatomic, retain) NSObject *caller;

@end
