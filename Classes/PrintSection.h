//
//  PrintSection.h
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrintCell.h"

@interface PrintSection : NSObject {
	int borderType;
	NSMutableArray *cells;
	int borderWidth;
	NSMutableDictionary *values;
	NSInteger resolution;
	int resumeRow;
	int myX;
	
	//forces this section to be the last one on the page...
	BOOL forcePageBreakAfterSection;
}

@property (nonatomic) NSInteger resolution;
@property (nonatomic) int borderType;
@property (nonatomic) int borderWidth;
@property (nonatomic) BOOL forcePageBreakAfterSection;

@property (nonatomic, retain) NSMutableArray *cells;
@property (nonatomic, retain) NSMutableDictionary *values;

-(id)initWithRes:(NSInteger)res;

-(void)addCell:(PrintCell*)cell;
-(int)width;
-(int)height;
-(int)rowHeight:(int)rowIdx;
-(int)rowCount;

-(void)addColumnValues:(NSArray*)vals withColName:(NSString*)colName;

-(int)drawSection:(CGContextRef)context withPosition:(CGPoint)position andRemainingPX:(int)remainingPX;

-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType;
-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType withWidth:(int)width;
-(void)duplicateLastCell:(NSString*)newCellName withType:(int)newCellType withWidth:(int)width withAlign:(int)align;

@end
