//
//  IGCPrinter.m
//  ePrintSampleNavi
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//

#import "IGCPrinter.h"
#import "SurveyAppDelegate.h"
#import "PagePrintParam.h"

@implementation IGCPrinter

@synthesize resolution = _resolution;
@synthesize _docDrawer;

- (void)setupWithDrawer:(IGCDrawer *)drawer;
{
	getPage = @selector(getPage:);
	numPages = @selector(numPages:);
	
	self._docDrawer = drawer;
	self._docDrawer.resolution = _resolution;
	
	CGSize paperSize = CGSizeMake(595, 842);	// A4 72dpi
	_contentRect = CGRectMake(TO_PRINTER_PDF(0), TO_PRINTER_PDF(0), TO_PRINTER_PDF(paperSize.width - MARGIN_PDF*2), TO_PRINTER_PDF(paperSize.height - MARGIN_PDF*2));
	
	//use this since I have to pass a complex object using the performSelector: withObject: mehtod
	PagePrintParam *parm = [[PagePrintParam alloc] init];
	parm.contentRect = _contentRect;
	_totalPages = (int)[_docDrawer performSelector:numPages withObject:parm];
	[parm release];
	
	lastPage = 1;
	
}

-(void) dealloc
{
	[_docDrawer release];
	[super dealloc];
}


- (SEL)getCallback
{
	return @selector(callBackDrawSample:);
}

- (void)beginJob
{
	_pageNumber = 0;
}

- (void)endJob
{
}

- (void)beginPage
{
	_pageNumber++;
}

- (void)endPage
{
}

- (BOOL)isEndPage
{
	if(_pageNumber == _totalPages) {
		return YES;
	} else {
		return NO;
	}
}

- (NSUInteger)pageNumber
{
	return _totalPages;
}


- (void)callBackDrawSample:(CGContextRef)context
{
	PagePrintParam *parm = [[PagePrintParam alloc] init];
	parm.contentRect = _contentRect;
	parm.pageNum = _pageNumber;
	parm.context = context;
	parm.totalPages = _totalPages;
	
	if(lastPage != _pageNumber) 
		parm.newPage = YES;// ... tell the drawer to commit the tempDocProgress...
	
	lastPage = _pageNumber;
	
	[_docDrawer performSelector:getPage withObject:parm];
	
	[parm release];
}


@end
