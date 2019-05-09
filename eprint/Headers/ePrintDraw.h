//
//  ePrintDraw.h
//  ePrint Library
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
	ePrintA4 = 0,
	ePrintLetter,
	ePrintA3,
	ePrintA5,
	ePrintB4,
	ePrintB5,
	ePrintHalfLetter,
	ePrintLegal,
	ePrintL,
	ePrint2L,
	ePrintKG,
	ePrintPostCard,
	ePrint8x11,
	
	ePrintSizeLast = ePrint8x11
	
} ePrintPaperSize;

typedef enum {
	ePrintPortrait = 0,
	ePrintLandscape
} ePrintOrientation;

@interface ePrintDraw : NSObject {
	CGRect				_contentRect;
	CGRect				*_drawImageRectArray;
	NSUInteger			_drawImageCount;

}

// content rectangle
@property (nonatomic) CGRect			contentRect;

// sepia rectangle & number
@property (nonatomic) CGRect			*drawImageRectArray;
@property (nonatomic) NSUInteger		drawImageCount;


- (void)beginJob;
- (void)endJob;
- (void)beginPage;
- (void)endPage;
- (BOOL)isEndPage;
- (NSUInteger)pageNumber;
- (BOOL)isRotate;

@end
