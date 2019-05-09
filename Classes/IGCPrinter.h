//
//  IGCPrinter.h
//  ePrintSampleNavi
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//

#import <Foundation/Foundation.h>
#import "ePrintDraw.h"
//#import "IGCDrawing.h"
#import "IGCDrawer.h"



@interface IGCPrinter : ePrintDraw {
	NSInteger		_resolution;
	NSInteger		_pageNumber;
	NSInteger		_totalPages;
	CGRect			_rects[1];
	//id<NSObject,IGCDrawing> _docDrawer;
	IGCDrawer *_docDrawer;
	
	SEL getPage;
	SEL numPages;
	int lastPage;
}

@property (nonatomic) NSInteger resolution;
@property (nonatomic, retain) IGCDrawer *_docDrawer;

- (void)setupWithDrawer:(IGCDrawer *)drawer;
- (SEL)getCallback;

- (void)callBackDrawSample:(CGContextRef)context;

@end
