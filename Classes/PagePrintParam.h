//
//  PagePrintParam.h
//  Survey
//
//  Created by Tony Brame on 3/8/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PagePrintParam : NSObject {
	CGContextRef context;
	CGRect contentRect;
	NSInteger pageNum;
	NSInteger totalPages;
	BOOL newPage;
}

@property (nonatomic) CGContextRef context;
@property (nonatomic) CGRect contentRect;
@property (nonatomic) NSInteger pageNum;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic) BOOL newPage;

@end
