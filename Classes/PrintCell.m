//
//  PrintCell.m
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "PrintCell.h"
#import "MMDrawer.h"
#import "SurveyAppDelegate.h"

@implementation PrintCell

@synthesize font;
@synthesize width;
@synthesize overrideHeight;
@synthesize cellHeight;
@synthesize cellType;
@synthesize underlineValue, underlineValueOnlyText, underlineLabel, strikethroughLabel;
@synthesize borderType;
@synthesize /*cellHeader, cellValue, */cellName;
@synthesize textPosition, resolution, wordWrap;
@synthesize padding;

static CGContextRef staticContext;
static UIFont *staticFont;

-(id)initWithRes:(NSInteger)res
{
	if(self = [super init])
	{
		resolution = res;
		self.font = DEFAULT_FONT;
		width = TO_PRINTER(200.0);
		overrideHeight = FALSE;
		cellType = CELL_LABEL;
		//self.cellHeader = @"";
		self.cellName = @"";
		//self.cellValue = @"";
		textPosition = NSTextAlignmentLeft;
		underlineValue = TRUE;
		borderType = BORDER_NONE;
		padding = TO_PRINTER(2.);
		resolution = res;
		borderWidth = 1;
		wordWrap = FALSE;
		//in px
		labelValSpacer = TO_PRINTER(5.0);
	}
	
	return self;
}

-(id)copyWithZone:(NSZone *)zone
{
	PrintCell *cell = [[PrintCell alloc] initWithRes:resolution];
	
	cell.font = font;
	cell.width = width;
	cell.overrideHeight = overrideHeight;
	cell.cellType = cellType;
	cell.cellName = cellName;
	cell.textPosition = textPosition;
	cell.underlineValue = underlineValue;
	cell.borderType = borderType;
	cell.padding = padding;
	cell.wordWrap = wordWrap;
	cell.underlineValueOnlyText = underlineValueOnlyText;
	cell.underlineLabel = underlineLabel;
	
	return cell;
}

-(NSDictionary*)getAttributesDictionary
{
    return [self getAttributesDictionary:[self getNSTextAlignment]];
}

-(NSDictionary*)getAttributesDictionary:(NSTextAlignment)alignment
{
    //used to convert to the new stuff used for iOS 7
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    if (wordWrap) paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = alignment;
    return @{
             NSFontAttributeName : self.font,
             NSParagraphStyleAttributeName : paragraphStyle,
             NSForegroundColorAttributeName : [UIColor blackColor]
             };
}

-(NSTextAlignment)getNSTextAlignment
{
    //used to convert to the new stuff used for iOS 7
    switch (self.textPosition) {
        case NSTextAlignmentLeft:
        default:
            return NSTextAlignmentLeft;
        case UITextAlignmentCenter:
            return NSTextAlignmentCenter;
        case UITextAlignmentRight:
            return NSTextAlignmentRight;
    }
}

-(int)heightWithText:(NSString*)text
{
	if(overrideHeight)
		return cellHeight;
	else
    {
        return ([self getDrawnSize:text withAlign:[self getNSTextAlignment]].height + (padding * 2)/*for top and bottom*/);
    }
}

-(CGSize)getDrawnSize:(NSString*)text
{
    return [self getDrawnSize:text withAlign:[self getNSTextAlignment]];
}

-(CGSize)getDrawnSize:(NSString*)text withAlign:(NSTextAlignment)alignment
{
    if ([SurveyAppDelegate iOS7OrNewer] && [text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
    {
        CGSize drawnSize = [text boundingRectWithSize:CGSizeMake(width - padding, 8000.)
                                              options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                           attributes:[self getAttributesDictionary:alignment]
                                              context:nil].size;
        //we sometimes get fractions, need to always round up
        drawnSize.width = ceilf(drawnSize.width);
        drawnSize.height = ceilf(drawnSize.height);
        return drawnSize;
    }
    else
    {
        //deprecated as of iOS 7+
        return [text sizeWithFont:font
                constrainedToSize:CGSizeMake(width - padding, 8000.)
                    lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping];
    }
}

-(void)drawCell:(CGContextRef)context withPosition:(CGPoint)position withLabel:(NSString*)lab withValue:(NSString*)val
{
	CGContextSaveGState(context);
	
	[[UIColor blackColor] set];
	
	
	CGContextSetLineWidth(context, borderWidth);
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
	
	CGRect rect = CGRectMake(position.x + padding,
							 position.y + padding, 
							 width - padding,
							 [self heightWithText:lab == nil ? val : lab] - (padding*2));
	
	CGSize drawn;
	CGPoint from, to;
	
	if(cellType == CELL_LABEL)
	{
		if ([SurveyAppDelegate iOS7OrNewer] && [lab respondsToSelector:@selector(drawInRect:withAttributes:)])
        {
            [lab drawInRect:rect withAttributes:[self getAttributesDictionary]];
            drawn = [self getDrawnSize:lab];
        }
        else
        {
            //deprecated as of iOS 7+
            drawn = [lab drawInRect:rect
                           withFont:font 
                      lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping 
                          alignment:textPosition];
        }
		
		if(underlineLabel)
		{
			from = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
			CGContextMoveToPoint(context, from.x, from.y);
			to = CGPointMake(rect.origin.x + drawn.width, rect.origin.y + rect.size.height);
			CGContextAddLineToPoint(context, to.x, to.y);
			CGContextStrokePath(context);
		}
        
		if(strikethroughLabel)//strikethrough
		{
			from = CGPointMake(rect.origin.x, rect.origin.y + (rect.size.height / 2));
			CGContextMoveToPoint(context, from.x, from.y);
			to = CGPointMake(rect.origin.x + drawn.width, rect.origin.y + (rect.size.height / 2));
			CGContextAddLineToPoint(context, to.x, to.y);
			CGContextStrokePath(context);
		}
	}
	else if(cellType == CELL_TEXT)
	{
		
		//always align a text field center...
        if ([SurveyAppDelegate iOS7OrNewer] && [val respondsToSelector:@selector(drawInRect:withAttributes:)])
        {
            [val drawInRect:rect withAttributes:[self getAttributesDictionary:NSTextAlignmentCenter]];
            drawn = [self getDrawnSize:val withAlign:NSTextAlignmentCenter];
        }
        else
        {
            //deprecated as of iOS 7+
            drawn = [val drawInRect:rect
                          withFont:font 
                     lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping 
                         alignment:UITextAlignmentCenter];
        }
		
		
		if(underlineValue)
		{
			from = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
			CGContextMoveToPoint(context, from.x, from.y);
			
			if(underlineValueOnlyText)
				to = CGPointMake(rect.origin.x + drawn.width, rect.origin.y + rect.size.height);
			else
				to = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
			
			CGContextAddLineToPoint(context, to.x, to.y);
			CGContextStrokePath(context);
		}
	}
	else if(cellType == CELL_TEXT_LABEL)
	{
        //draw label on left
        if ([SurveyAppDelegate iOS7OrNewer] && [lab respondsToSelector:@selector(drawInRect:withAttributes:)])
        {
            [lab drawInRect:rect withAttributes:[self getAttributesDictionary:NSTextAlignmentLeft]];
            drawn = [self getDrawnSize:lab withAlign:NSTextAlignmentLeft];
        }
        else
        {
            //deprecated as of iOS 7++
            drawn = [lab drawInRect:rect
                           withFont:font 
                      lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping 
                          alignment:NSTextAlignmentLeft];
        }
		
		
		if(underlineLabel)
		{
			from = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
			CGContextMoveToPoint(context, from.x, from.y);
			to = CGPointMake(rect.origin.x + drawn.width, rect.origin.y + rect.size.height);
			CGContextAddLineToPoint(context, to.x, to.y);
			CGContextStrokePath(context);
		}
		
		rect.origin.x += (drawn.width + labelValSpacer);
		rect.size.width -= (drawn.width + labelValSpacer);
		
        if ([SurveyAppDelegate iOS7OrNewer] && [val respondsToSelector:@selector(drawInRect:withAttributes:)])
        {
            [val drawInRect:rect withAttributes:[self getAttributesDictionary]];
            drawn = [self getDrawnSize:val];
        }
        else
        {
            //deprecated as of iOS 7++
            drawn = [val drawInRect:rect
                   withFont:font 
              lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping 
                  alignment:textPosition];
        }
		
		if(underlineValue)
		{
			from = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
			CGContextMoveToPoint(context, from.x, from.y);
			
			if(underlineValueOnlyText)
				to = CGPointMake(rect.origin.x + drawn.width, rect.origin.y + rect.size.height);
			else
				to = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
			
			CGContextAddLineToPoint(context, to.x, to.y);
			CGContextStrokePath(context);
		}
		
	}
	else if(cellType == CELL_CHECKBOX)
	{//draw label on left, right after check box
		
		CGRect boxRect = rect;
		//make it sqaure
		boxRect.size.width = rect.size.height;
		//drawr it
		CGContextStrokeRect(context, boxRect);
		if([val isEqualToString:@"1"])
		{
			//check it (X)
			//CGContextSetLineWidth(context, 2.0);   //taking this out, looked a little goofy being so large
			CGContextMoveToPoint(context, boxRect.origin.x, boxRect.origin.y);
			CGContextAddLineToPoint(context, boxRect.origin.x + boxRect.size.width, boxRect.origin.y + boxRect.size.height);
			CGContextStrokePath(context);
			CGContextMoveToPoint(context, boxRect.origin.x + boxRect.size.width, boxRect.origin.y);
			CGContextAddLineToPoint(context, boxRect.origin.x, boxRect.origin.y + boxRect.size.height);
			CGContextStrokePath(context);
		}
		
		//draw the label after it...
		rect.origin.x += (boxRect.size.width + labelValSpacer);
		rect.size.width -= (boxRect.size.width + labelValSpacer);
		
        if ([SurveyAppDelegate iOS7OrNewer] && [lab respondsToSelector:@selector(drawInRect:withAttributes:)])
        {
            [lab drawInRect:rect withAttributes:[self getAttributesDictionary:NSTextAlignmentLeft]];
            drawn = [self getDrawnSize:lab withAlign:NSTextAlignmentLeft];
        }
        else
        {
            //deprecated as of iOS 7++
            drawn = [lab drawInRect:rect
                           withFont:font 
                      lineBreakMode:wordWrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping 
                          alignment:NSTextAlignmentLeft];
        }
	}
	
	
	if(borderType & BORDER_TOP)
	{
		CGContextMoveToPoint(context, position.x, position.y);
		CGContextAddLineToPoint(context, position.x + [self width], position.y);
		CGContextStrokePath(context);
	}
	
	if(borderType & BORDER_RIGHT)
	{
		CGContextMoveToPoint(context, position.x + [self width], position.y);
		CGContextAddLineToPoint(context, position.x + [self width], position.y + [self heightWithText:lab == nil ? val : lab]);
		CGContextStrokePath(context);
	}
	
	if(borderType & BORDER_BOTTOM)
	{
		CGContextMoveToPoint(context, position.x + [self width], position.y + [self heightWithText:lab == nil ? val : lab]);
		CGContextAddLineToPoint(context, position.x, position.y + [self heightWithText:lab == nil ? val : lab]);
		CGContextStrokePath(context);
	}
	
	if(borderType & BORDER_LEFT)
	{
		CGContextMoveToPoint(context, position.x, position.y + [self heightWithText:lab == nil ? val : lab]);
		CGContextAddLineToPoint(context, position.x, position.y);
		CGContextStrokePath(context);
	}
	
	
	CGContextRestoreGState(context);
}

+ (void)staticContextSet:(CGContextRef)context
{
    staticContext = context;
}

+ (void)staticFontSet:(UIFont *)font
{
    staticFont = font;
}

+ (void)staticLineWidthSet:(CGFloat)lineWidth
{
    if(staticContext == NULL)
        return;
    
    CGContextSetLineWidth(staticContext, lineWidth);
}

+ (void)drawTextCellLabel:(NSString *)labelText x:(CGFloat)x y:(CGFloat)y width:(int)theWidth font:(UIFont *)theFont border:(int)theBorder align:(UITextAlignment)theAlign
{
    PrintCell *cell = [[PrintCell alloc] initWithRes:0];
	cell.cellName = @"Cell";
	cell.cellType = CELL_LABEL;
	cell.width = theWidth;
	cell.font = theFont;
    cell.textPosition = theAlign;
    cell.borderType = theBorder;
    if ([labelText hasSuffix:@"_"])
    {
        labelText = [labelText substringToIndex:[labelText length] - 1];
        cell.underlineLabel = YES;
    }
    
    [cell drawCell:staticContext withPosition:CGPointMake(x, y) withLabel:labelText withValue:nil];
    
}

+ (void)drawTextCellLabel:(NSString *)labelText x:(CGFloat)x y:(CGFloat)y width:(int)theWidth align:(UITextAlignment)theAlign
{
    [PrintCell drawTextCellLabel:labelText x:x y:y width:theWidth font:staticFont border:BORDER_NONE align:theAlign];
}

+ (void)drawLine:(CGPoint)from to:(CGPoint)to
{
    if(staticContext == NULL)
        return;
    
    CGContextMoveToPoint(staticContext, from.x, from.y);
    CGContextAddLineToPoint(staticContext, to.x, to.y);
    CGContextStrokePath(staticContext);
}

+ (void)drawRectangle:(CGRect)rect
{
    if(staticContext == NULL)
        return;
    
    CGContextAddRect(staticContext, rect);
    CGContextStrokePath(staticContext);
}

@end
