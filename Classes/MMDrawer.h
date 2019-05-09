//
//  MMDrawer.h
//  Survey
//
//  Created by Tony Brame on 4/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagePrintParam.h"
#import "PrintSection.h"

enum DISCONNECTED_REPORTS {
	TOM,
	UG_OFS,
	UG_ESTIMATE,
	UG_EST_ASPL,
	UG_OFS_ASPL,
	LOCAL_EST,
	LOCAL_OFS,
	INT_EST_NET_ASPL,
	INT_EST_ASPL,
	INT_EST_NET,
	INT_EST,
	INT_OFS_NET,
	INT_OFS
};

#define TO_PRINTER(v) v
//#define TO_PRINTER(v) floor((v) / 72.0 * resolution)
#define MARGIN (72.0 * 0.2)

#define TO_PRINTER_PDF(v) floor((v) / 72.0 * _resolution)
#define MARGIN_PDF (72.0 * 0.2)

#define DEFAULT_FONT [UIFont systemFontOfSize:TO_PRINTER(12.0)]

#define SIZE_CHECK -1
#define NO_LIMIT -2

#define DIDNT_FIT_ON_PAGE -1
#define FORCE_PAGE_BREAK -2

@interface MMDrawer : NSObject {
	int currentPageY;
	int reportID;
	NSInteger resolution;
	PagePrintParam *params;
	CGContextRef context;
	
	//sections carried over from the last page
	NSMutableArray *previousPageSections;
	//sections to be carried over to the next page
	NSMutableArray *nextPageSections;
    //images carried over from the last page
    NSMutableDictionary *previousPageImages;
    //images to be carried over to the next page
    //key is index of printing after section
    //value holds an NSArray of UIImage, NSValue (CGPoint), NSValue (CGSize)
    NSMutableDictionary *nextPageImages; 
	
	//since it calls this multiple time for one page, we need to store the progress in a temp var
	//and commit to docProgress when we go to the next page...
	int tempDocProgress;
	int docProgress;
	
	//I cannot for the life of me figure out capping the height of the rect, so this is
	//used to subtract from the height when figuring out the remaining page pixels... 
	int takeOffBottom;
	
	BOOL endOfDoc;
	
	int estimateType;
	
	SEL footerMethod;
	SEL headerMethod;
	
}

@property (nonatomic) int reportID;
@property (nonatomic) NSInteger resolution;

-(NSDictionary*)availableReports;
-(BOOL)reportAvailable:(int)rptID;

-(void)preparePage;
-(void)finishSectionOnNextPage:(PrintSection*)section;
-(void)finishImageOnNextPage:(UIImage*)image withRefPoint:(CGPoint)point withSize:(CGSize)size;
-(BOOL)finishSectionsFromPreviousPage;
-(BOOL)printSection:(SEL)sectionSelector withProgressID:(int)progID;
-(void)printPageFooter;
-(void)printPageHeader;

-(int)drawOneSection:(PrintSection *) section;
-(int)drawOneSection:(PrintSection *) section atX:(int)x;

-(int)numPages:(PagePrintParam*)rectangle;
-(BOOL)getPage:(PagePrintParam*)parms;

-(void)drawImage:(UIImage*)image withCGRect:(CGRect)rect;

@end
