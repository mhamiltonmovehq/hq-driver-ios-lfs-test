//
//  RoundedBorderView.m
//  Survey
//
//  Created by Tony Brame on 9/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RoundedBorderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RoundedBorderView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        //self.layer.cornerRadius = 10;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {    
    
    //[super drawRect:rect];
    
    // Get the contextRef
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // Set the border width
    CGContextSetLineWidth(contextRef, 1.0);
    
    // Set the border color to BLACK
    CGContextSetStrokeColorWithColor(contextRef, [UIColor blackColor].CGColor);
    
    // Draw the border along the view edge
    //CGContextStrokeRect(contextRef, rect);
    CGContextAddRoundedRect(contextRef, rect, 10);
    
}

void CGContextAddRoundedRect (CGContextRef c, CGRect rect, int corner_radius) 
{  
    int x_left = rect.origin.x;  
    int x_left_center = rect.origin.x + corner_radius;  
    int x_right_center = rect.origin.x + rect.size.width - corner_radius;  
    int x_right = rect.origin.x + rect.size.width;  
    int y_top = rect.origin.y;  
    int y_top_center = rect.origin.y + corner_radius;  
    int y_bottom_center = rect.origin.y + rect.size.height - corner_radius;  
    int y_bottom = rect.origin.y + rect.size.height;  
    
    /* Begin! */  
    CGContextBeginPath(c);  
    CGContextMoveToPoint(c, x_left, y_top_center);  
    
    /* First corner */  
    CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);  
    CGContextAddLineToPoint(c, x_right_center, y_top);  
    
    /* Second corner */  
    CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);  
    CGContextAddLineToPoint(c, x_right, y_bottom_center);  
    
    /* Third corner */  
    CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);  
    CGContextAddLineToPoint(c, x_left_center, y_bottom);  
    
    /* Fourth corner */  
    CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);  
    CGContextAddLineToPoint(c, x_left, y_top_center);  
    
    /* Done */  
    CGContextClosePath(c);  
    
    CGContextStrokePath(c);
    
}  



@end
