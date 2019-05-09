//
//  PrintSection.m
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "PrintSection.h"
#import "MMDrawer.h"
#import "CellValue.h"

@implementation PrintSection

@synthesize borderType;
@synthesize cells;
@synthesize borderWidth;
@synthesize values;
@synthesize resolution, forcePageBreakAfterSection;

-(id)initWithRes:(NSInteger)res
{
	if(self = [super init])
	{
		self.values = [NSMutableDictionary dictionary];
		resolution = res;
		borderType = BORDER_NONE;
		cells = [[NSMutableArray alloc] init];
		borderWidth = 1;
		resumeRow = 0;
		forcePageBreakAfterSection = FALSE;
	}
	return self;
}

-(void)addCell:(PrintCell*)cell
{
	
	[cells addObject:cell];
	
}

-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType withWidth:(int)width withAlign:(int)align
{
	if(cells == 0)
		return;
	
	PrintCell *newcell = [[cells objectAtIndex:[cells count]-1] copy];
	newcell.cellName = newCellName;
	newcell.cellType = newCellType;
	newcell.width = width;
	newcell.textPosition = align;
	[cells addObject:newcell];
}

-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType withWidth:(int)width
{
	if(cells == 0)
		return;
	
	PrintCell *newcell = [[cells objectAtIndex:[cells count]-1] copy];
	newcell.cellName = newCellName;
	newcell.cellType = newCellType;
	newcell.width = width;
	[cells addObject:newcell];
}

-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType
{
	if(cells == 0)
		return;
	
	PrintCell *newcell = [[cells objectAtIndex:[cells count]-1] copy];
	newcell.cellName = newCellName;
	newcell.cellType = newCellType;
	[cells addObject:newcell];
}

-(int)width
{
	int total = 0;
	
	for(int i = 0; i < [cells count]; i++)
	{
		PrintCell *cell = [cells objectAtIndex:i];
		total += cell.width;
	}
	
	return total;
}

-(int)height
{
	int totalHeight = 0;
	int rowCount= [self rowCount];
	for(int row = resumeRow; row < rowCount; row++)
	{
		totalHeight += [self rowHeight:row];
	}
	
	return totalHeight;
}

-(int)rowHeight:(int)rowIdx
{
	int highest = 0;
	
	PrintCell *cell;
	NSArray *colVals;

	for(int col = 0; col < [cells count]; col++)
	{
		cell = [cells objectAtIndex:col];
		
		//get all column values
		colVals = [values objectForKey:cell.cellName];
		
		//get the value that I want
		if(rowIdx >= [colVals count])
			continue;
		
		CellValue *myValues = [colVals objectAtIndex:rowIdx];
		
		if([cell heightWithText:myValues.label == nil ? myValues.cellValue : myValues.label] > highest)
		{
			highest = [cell heightWithText:myValues.label == nil ? myValues.cellValue : myValues.label];
		}
	}
	
	return highest;
}

-(int)rowCount
{
	NSArray *keys = [values allKeys];
	NSArray *cellVals;
	
	if([keys count] == 0)
		return 0;
	
	int vals = 0;
	
	for(int i = 0; i < [keys count]; i++)
	{
		cellVals = [values objectForKey:[keys objectAtIndex:i]];
		if([cellVals count] > vals)
			vals = [cellVals count];
	}
	
	return vals;
}

-(void)addColumnValues:(NSArray*)vals withColName:(NSString*)colName
{
	[values setObject:vals forKey:colName];
}

-(int)drawSection:(CGContextRef)context withPosition:(CGPoint)position andRemainingPX:(int)remainingPX
{
	
	//logic added for continuing sections (need to remember X)...
	BOOL continuingOnNewPage = position.x == -1;
	if(continuingOnNewPage)
		position.x = myX;
	else
		myX = position.x;
	
	int currentX = position.x;
	int currentY = position.y;
	
	PrintCell *cell;
	NSArray *colVals;
	int rowCount= [self rowCount];
	int drawnHeight = 0;
	BOOL finished = TRUE;
	int prevResume = resumeRow;
	
	for(; resumeRow < rowCount; resumeRow++)
	{
		//new row...
		currentX = position.x;
		
		//check to see if the row will fit in the remainging
		if([self rowHeight:resumeRow] > remainingPX)
		{//stop here, and return that we couldn't fit it on this page...
			//CGContextRestoreGState(context);
			finished = FALSE;
			goto drawBorders;
		}
		
		//will fit, draw row...
		for(int col = 0; col < [cells count]; col++)
		{
			cell = [cells objectAtIndex:col];
			
			//get all column values
			colVals = [values objectForKey:cell.cellName];
			
			//get the value that I want
			if(resumeRow >= [colVals count] )
			{//increase currentX to account for the column (so they line up)
				currentX += cell.width;
				continue;
			}
			
			CellValue *myValues = [colVals objectAtIndex:resumeRow];
			
			cell.strikethroughLabel = myValues.strikethrough;
            
			//sooo.... draw the cell
            if (context != NULL)
            {
                [cell drawCell:context
                  withPosition:CGPointMake(currentX, currentY) 
                     withLabel:myValues.label 
                     withValue:myValues.cellValue];
            }
			
			//increase the current width for new column
			currentX += cell.width;
		}
		
		drawnHeight += [self rowHeight:resumeRow];
		remainingPX -= [self rowHeight:resumeRow];
		
		//increase the hieght for new row
		currentY += [self rowHeight:resumeRow];
	}
	
	//if wwe are continuing this on a new page, we dont want to leave resume row where it was, 
	//since it will call this same object a few times...
	
	//this may cause an issue when a section may span more than two pages...
	if(continuingOnNewPage)
		resumeRow = prevResume;
	
drawBorders:
	
	//draw borders...
    if (context != NULL)
    {
        CGContextSaveGState(context);
        
        CGContextSetLineWidth(context, borderWidth);
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        
        if(borderType & BORDER_TOP)
        {
            CGContextMoveToPoint(context, position.x, position.y);
            CGContextAddLineToPoint(context, position.x + [self width], position.y);
            CGContextStrokePath(context);
        }
        
        if(borderType & BORDER_RIGHT)
        {
            CGContextMoveToPoint(context, position.x + [self width], position.y);
            CGContextAddLineToPoint(context, position.x + [self width], position.y + drawnHeight);
            CGContextStrokePath(context);
        }
        
        
        if(borderType & BORDER_BOTTOM && finished)
        {
            CGContextMoveToPoint(context, position.x + [self width], position.y + drawnHeight);
            CGContextAddLineToPoint(context, position.x, position.y + drawnHeight);
            CGContextStrokePath(context);
        }
        
        
        if(borderType & BORDER_LEFT)
        {
            CGContextMoveToPoint(context, position.x, position.y + drawnHeight);
            CGContextAddLineToPoint(context, position.x, position.y);
            CGContextStrokePath(context);
        }
        
        CGContextRestoreGState(context);
    }
	
	
	//completed...
	if(forcePageBreakAfterSection && finished)
		return FORCE_PAGE_BREAK;
	else
		return finished ? drawnHeight : DIDNT_FIT_ON_PAGE;	
}

@end
