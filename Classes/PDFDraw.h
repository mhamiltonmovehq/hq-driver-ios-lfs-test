//
//  MyDraw.h
//  ePrintSampleNavi
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//

#import <Foundation/Foundation.h>
#import "ePrintDraw.h"

@interface PDFDraw : ePrintDraw {
	NSInteger		_resolution;
	NSInteger		_pageNumber;
	NSInteger		_totalPages;
	CGRect			_rects[1];
	CGDataProviderRef _dataProvRef;
	CGPDFDocumentRef _pdfRef;
}

@property (nonatomic) NSInteger resolution;
@property (nonatomic, retain) NSString *pdfPath;

- (void)setup;
- (SEL)getCallback;

- (void)callBackDrawSample:(CGContextRef)context;

@end
