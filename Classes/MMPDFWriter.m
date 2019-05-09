//
//  Survey
//
//  Created by Tony Brame on 12/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MMPDFWriter.h"
#import "MMDrawer.h"
#import "PagePrintParam.h"

@implementation MMPDFWriter


-(void)createPDF:(NSString*)pdfFileName withDrawer:(MMDrawer*)printDrawer
{
    PagePrintParam *parm = [[PagePrintParam alloc] init];
    //standard 8.5 x 11
    parm.contentRect = CGRectMake(0, 0, 612, 792);
    
    //grab page count (dry run)
    parm.totalPages = [printDrawer numPages:parm];
    
    //begin context with default page size
    UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectZero, nil);
    
    for(int i = 1; i <= parm.totalPages; i++)
    {
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 612, 792), nil);
        
        //grab the context (grabbing here since idk if it's updated with a new page)
        parm.context = UIGraphicsGetCurrentContext();
        parm.pageNum = i;
        parm.newPage = i > 1;
        
        // Core Text draws from the bottom-left corner up, so flip
        // the current transform prior to drawing.
        CGContextTranslateCTM(parm.context, 0, 792);
        CGContextScaleCTM(parm.context, 1.0, -1.0);
        
        [printDrawer getPage:parm];
        
    }
    
    UIGraphicsEndPDFContext();
}

@end
