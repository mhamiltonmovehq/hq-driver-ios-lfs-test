//
//  MMDrawer.m
//  Survey
//
//  Created by Tony Brame on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMDrawer.h"
#import "SurveyAppDelegate.h"
#import "PrintCell.h"
#import "CellValue.h"
#import "CustomerUtilities.h"


@implementation MMDrawer

@synthesize reportID, resolution;


//this needs overridden
-(NSDictionary*)availableReports
{
	return nil;
}

-(BOOL)reportAvailable:(int)rptID
{
	BOOL found = NO;
	
	NSDictionary *dict = [self availableReports];
	NSArray *keys = [dict allKeys];
	for(int i = 0; i < [keys count]; i++)
	{
		NSNumber *mynum = [dict objectForKey:[keys objectAtIndex:i]];
		if([mynum intValue] == rptID)
		{
			found = YES;
			break;
		}
	}
	
	return found;
}

-(id)init
{
	if(self = [super init])
	{
		previousPageSections = nil;
		nextPageSections = nil;
        nextPageImages = nil;
		currentPageY = 0;
		endOfDoc = FALSE;
		tempDocProgress = 0;
		docProgress = 0;
		footerMethod = nil;
	}
	
	return self;
}

-(void)finishSectionOnNextPage:(PrintSection*)section
{
	if(nextPageSections == nil)
		nextPageSections = [[NSMutableArray alloc] init];
	[nextPageSections addObject:section];
}

-(void)finishImageOnNextPage:(UIImage*)image withRefPoint:(CGPoint)point withSize:(CGSize)size
{
    if(nextPageImages == nil)
        nextPageImages = [[NSMutableDictionary alloc] init];
    if (image != nil) {
        [nextPageImages setValue:[NSArray arrayWithObjects:image, [NSValue valueWithCGPoint:point], [NSValue valueWithCGSize:size], nil]
                          forKey:[NSString stringWithFormat:@"%lu", (nextPageSections != nil ? [nextPageSections count]-1 : -1)]];
    }
}

-(BOOL)finishSectionsFromPreviousPage
{
	int highestSection = 0;
	PrintSection *currentSection;
	int printResult = 0;
    
    if (previousPageImages != nil && [previousPageImages objectForKey:[NSString stringWithFormat:@"%d", -1]] != nil)
    {
        NSArray *details = [previousPageImages objectForKey:[NSString stringWithFormat:@"%d", -1]];
        CGPoint point = [[details objectAtIndex:1] CGPointValue];
        CGSize size = [[details objectAtIndex:2] CGSizeValue];
        [self drawImage:[details objectAtIndex:0]
             withCGRect:CGRectMake(params.contentRect.origin.x + point.x,
                                   currentPageY + point.y,
                                   size.width,
                                   size.height)];
    }
	
	if(previousPageSections != nil)
	{
        int addedHeight = 0;
		for(int i = 0; i < [previousPageSections count]; i++)
		{
			currentSection = [previousPageSections objectAtIndex:i];
			
            //taking this out for PVO reports
//			if(highestSection < [currentSection height] && highestSection != DIDNT_FIT_ON_PAGE)
//				highestSection = [currentSection height];
			
            if (previousPageImages != nil) //only used for printing images
                addedHeight += [currentSection height];
			printResult = [currentSection drawSection:context
										 withPosition:CGPointMake(params.contentRect.origin.x, currentPageY) //-1, params.contentRect.origin.y) 
									   andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
            
            //print images
            if(previousPageImages != nil)
            {
                NSArray *details = [previousPageImages objectForKey:[NSString stringWithFormat:@"%d", i]];
                if (details != nil)
                {
                    CGPoint point = [[details objectAtIndex:1] CGPointValue];
                    CGSize size = [[details objectAtIndex:2] CGSizeValue];
                    if(printResult == FORCE_PAGE_BREAK || printResult >= 0)
                    {
                        [self drawImage:[details objectAtIndex:0]
                             withCGRect:CGRectMake(params.contentRect.origin.x + point.x,
                                                   currentPageY + addedHeight + point.y,
                                                   size.width,
                                                   size.height)];
                    }
                    else
                    {
                        if(nextPageImages == nil)
                            nextPageImages = [[NSMutableDictionary alloc] init];
                        [nextPageImages setValue:[NSArray arrayWithArray:details]
                                          forKey:[NSString stringWithFormat:@"%lu", (unsigned long)(nextPageSections != nil ? [nextPageSections count] : 0)]];
                    }
                }
            }
            
			if(printResult == FORCE_PAGE_BREAK)
			{
				highestSection = DIDNT_FIT_ON_PAGE;
				break;
			}
			else if(printResult == DIDNT_FIT_ON_PAGE)
			{
				if(nextPageSections	== nil)
					nextPageSections = [[NSMutableArray alloc] init];
				[nextPageSections addObject:currentSection];
				highestSection = DIDNT_FIT_ON_PAGE;
			}
			else
            {
                highestSection += printResult;
                currentPageY += printResult;
            }
		}
		
		//[previousPageSections removeAllObjects];
		
		if(highestSection == DIDNT_FIT_ON_PAGE)
		{
			//moving on, make sure that the tempDocProgress is set to current progress, or it gets overwritten
			tempDocProgress = docProgress;
			return FALSE;
		}
        //taking this out for PVO reports
//		else
//			currentPageY += highestSection;
		
	}
	
	return TRUE;
}

//will return false indicating it didnt fit on the page...
-(BOOL)printSection:(SEL)sectionSelector withProgressID:(int)progID
{
	int printedHeight = 0;
	if(docProgress < progID)
	{
		tempDocProgress = progID;
		printedHeight = (int)[self performSelector:sectionSelector];
		if(printedHeight == DIDNT_FIT_ON_PAGE || printedHeight == FORCE_PAGE_BREAK)
			return FALSE;
	}
	
	return TRUE;
}


//this needs overridden
-(BOOL)getPage:(PagePrintParam*)parms
{
	
	return FALSE;
	
}

-(int)numPages:(PagePrintParam*)rectangle
{
	SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
	ShipmentInfo *inf = [del.surveyDB getShipInfo:del.customerID];
	estimateType = inf.type;
	
	//profrm a dry run, and see how many pages are printed...
	takeOffBottom = TO_PRINTER(50.);
	
	//i have no print params now... so, try it out.. (maybe need a context init here?)
	int i = 0;
	PagePrintParam *poo = [[PagePrintParam alloc] init];
	
	while(!endOfDoc)
	{
		poo.pageNum = i;
		poo.newPage = i > 0;
		poo.contentRect = rectangle.contentRect;
		[self getPage:poo];
		i++;
	}
		
	previousPageSections = nil;
	nextPageSections = nil;
    previousPageImages = nil;
    nextPageImages = nil;
	currentPageY = 0;
	endOfDoc = FALSE;
	tempDocProgress = 0;
	docProgress = 0;
	
	return i;	
}


-(void)preparePage
{
	
	//moving on to the next page... commit the progress, and update the section references
	if(params.newPage)
	{
		docProgress = tempDocProgress;
		
		if(previousPageSections != nil)
		{
			previousPageSections = nil;
		}
		if(nextPageSections != nil)
			previousPageSections = [nextPageSections mutableCopyWithZone:NSDefaultMallocZone()];
        
        if(previousPageImages != nil)
        {
            previousPageImages = nil;
        }
        
        if(nextPageImages != nil)
            previousPageImages = [nextPageImages mutableCopyWithZone:NSDefaultMallocZone()];
		
	}
	
	if(footerMethod != nil)
	{
		takeOffBottom = TO_PRINTER(50.) + (int)[self performSelector:footerMethod withObject:NO];
	}
	
	if(nextPageSections != nil)
	{//clear it out so it can be rebuilt...
		nextPageSections = nil;
	}
    
    if(nextPageImages != nil)
    {
        nextPageImages = nil;
    }
	
	tempDocProgress = 0;
	currentPageY = params.contentRect.origin.y;
    
	if(headerMethod != nil)
	{
		currentPageY += (int)[self performSelector:headerMethod withObject:NO];
	}
}

- (int) drawOneSection: (PrintSection *) section  
{
	return [self drawOneSection:section atX:0];
}

-(int)drawOneSection:(PrintSection *) section atX:(int)x
{
	//place it
	CGPoint pos = params.contentRect.origin;
	pos.x +=  x;
	pos.y = currentPageY;	
	
	//print it, check to make sure it fit... 
	//if not, store it in the collection of items to continue...
	int drawn = [section drawSection:context 
						withPosition:pos 
					  andRemainingPX:(params.contentRect.size.height-takeOffBottom)-currentPageY];
	if(drawn == DIDNT_FIT_ON_PAGE)
		[self finishSectionOnNextPage:section];
	
	currentPageY += drawn;
	return drawn;
}

-(void)printPageFooter
{
	if(footerMethod == nil)
		return;
	
	[self performSelector:footerMethod withObject:nil];
}

-(void)printPageHeader
{
	if(headerMethod == nil)
		return;
	
	[self performSelector:headerMethod withObject:nil];
}


-(void)drawImage:(UIImage*)image withCGRect:(CGRect)rect
{
    if (params != nil && context != NULL)
    {
        CGContextDrawImage(context, rect, image.CGImage);
    }
}

@end
