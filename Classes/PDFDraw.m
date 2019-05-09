//
//  MyDraw.m
//  ePrintSampleNavi
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//

#import "PDFDraw.h"
#import "SurveyAppDelegate.h"

#define TO_PRINTER(v) floor((v) / 72.0 * _resolution)
#define MARGIN (72.0 * 0.2)
@implementation PDFDraw

@synthesize resolution = _resolution;
- (void)setup
{
	CGSize paperSize = CGSizeMake(595, 842);	// A4 72dpi
	_contentRect = CGRectMake(TO_PRINTER(0), TO_PRINTER(0), TO_PRINTER(paperSize.width - MARGIN*2), TO_PRINTER(paperSize.height - MARGIN*2));
}

-(void)dealloc
{
    self.pdfPath = nil;
}

- (SEL)getCallback
{
	return @selector(callBackDrawSample:);
}

- (void)beginJob
{
    //NSString *pdfPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"printme.pdf"];
    NSString *path = self.pdfPath;
    if(self.pdfPath == nil)
        path = [[SurveyAppDelegate getDocsDirectory] stringByAppendingPathComponent:@"temp.pdf"];
    
	_dataProvRef = CGDataProviderCreateWithFilename([path UTF8String]);
	_pdfRef = CGPDFDocumentCreateWithProvider(_dataProvRef);
	_pageNumber = 0;
	_totalPages = CGPDFDocumentGetNumberOfPages(_pdfRef);
}

- (void)endJob
{
	CGPDFDocumentRelease(_pdfRef);
	CGDataProviderRelease(_dataProvRef);	
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

/*
 NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 CGRect printRect = _contentRect;
 CGContextSaveGState(context);
 
 CGContextSetShouldAntialias(context, false);
 CGContextSetAllowsAntialiasing(context, false);
 
 UIGraphicsPushContext(context);
 
 // clear
 CGContextSetRGBFillColor(context, 1.,1.,1.,1.);
 CGContextFillRect(context, printRect);
 
 // text
 CGContextSaveGState(context);
 CGAffineTransform transImage = CGAffineTransformMake(1, 0, 0, -1, 0, floor(_contentRect.size.height));
 CGContextConcatCTM(context, transImage);
 [[UIColor blackColor] set];
 UIFont *font = [UIFont systemFontOfSize:TO_PRINTER(12.0)];
 CGRect rect = CGRectMake(TO_PRINTER(20.), TO_PRINTER(20.), TO_PRINTER(200.), TO_PRINTER(20.));
 NSString *str = [NSString stringWithFormat:@"Test print. (page : %d)", _pageNumber];
 [str drawInRect:rect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentLeft];
 CGContextRestoreGState(context);
 
 // image
 UIImage *image1 = [UIImage imageNamed:@"photo1.jpg"];
 CGSize	tmpSize1 = [image1 size];
 CGFloat ratio = (72.0 * 2) / tmpSize1.width;
 tmpSize1.width = tmpSize1.width * ratio;
 tmpSize1.height = tmpSize1.height * ratio;
 
 CGRect imageRect1 = CGRectMake(TO_PRINTER(20.), TO_PRINTER(50.), TO_PRINTER(tmpSize1.width), TO_PRINTER(tmpSize1.height));
 imageRect1 = CGRectApplyAffineTransform(imageRect1, transImage);
 CGContextDrawImage(context, imageRect1, image1.CGImage);
 
 UIImage *image2 = [UIImage imageNamed:@"photo2.jpg"];
 // change the size to the 72 dpi.
 CGSize	tmpSize2 = [image2 size];
 ratio = (72.0 * 2) / tmpSize2.width;
 tmpSize2.width = tmpSize2.width * ratio;
 tmpSize2.height = tmpSize2.height * ratio;
 CGRect imageRect2 = CGRectMake(TO_PRINTER(20.), TO_PRINTER(200.), TO_PRINTER(tmpSize2.width), TO_PRINTER(tmpSize2.height));
 // for sepia
 _rects[0] = imageRect2;
 _drawImageCount = 1;
 _drawImageRectArray = _rects;
 CGContextDrawImage(context, imageRect2, image2.CGImage);
 
 // outer frame
 CGContextStrokeRect(context, CGRectInset(printRect, TO_PRINTER(15.), TO_PRINTER(15.)));
 
 UIGraphicsPopContext();
 CGContextRestoreGState(context);
 
 CGContextFlush(context);
 
 [pool release];
 */

- (void)callBackDrawSample:(CGContextRef)context
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @autoreleasepool {
   
	CGRect printRect = _contentRect;
	CGContextSaveGState(context);
	
	// clear the print rectangle
	CGContextSetRGBFillColor(context, 1.,1.,1.,1.);
	CGContextFillRect(context, printRect);
	
	CGPDFPageRef pageRef = CGPDFDocumentGetPage(_pdfRef, _pageNumber);
	if(pageRef)
	{
		//CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pageRef, kCGPDFMediaBox, printRect, 0, true);
		//CGContextConcatCTM(context, pdfTransform);
		
		CGRect pdfRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
		CGFloat angle = (CGFloat)CGPDFPageGetRotationAngle(pageRef);
		CGAffineTransform tr = CGAffineTransformMakeRotation(-angle*M_PI/180.);
		CGRect rotateRect = CGRectApplyAffineTransform(pdfRect, tr);
		CGFloat wr = printRect.size.width / rotateRect.size.width;
		CGFloat hr = printRect.size.height / rotateRect.size.height;
		CGFloat ratio;
		if(wr > hr) {
			ratio = hr;
		} else {
			ratio = wr;
		}
		CGSize destSize = CGSizeMake(rotateRect.size.width * ratio, rotateRect.size.height * ratio);
		CGPoint offset = CGPointMake(printRect.origin.x + (printRect.size.width - destSize.width) / 2, printRect.origin.y + (printRect.size.height - destSize.height) / 2);
		
		CGFloat destWidth = CGRectGetMinX(rotateRect) * ratio * -1 + offset.x;
		CGFloat destHeight = CGRectGetMinY(rotateRect) * ratio * -1 + offset.y;
		CGAffineTransform t = CGAffineTransformMake(cos(angle*M_PI/180.), -sin(angle*M_PI/180.), sin(angle*M_PI/180.), cos(angle*M_PI/180.),destWidth, destHeight);
		CGContextConcatCTM(context, t);		
		CGContextScaleCTM(context, ratio,ratio);
		//
		
		CGContextDrawPDFPage(context, pageRef);
	}

	
	CGContextRestoreGState(context);
	
	CGContextFlush(context);
	
	//[pool release];
    }
}


@end
