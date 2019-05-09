//
//  CellValue.h
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CellValue : NSObject {
    NSString *label;
    NSString *cellValue;
    BOOL strikethrough;
}

@property (nonatomic) BOOL strikethrough;

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *cellValue;

-(id)initWithValue:(NSString*)val withLabel:(NSString*)lab;
-(id)initWithValue:(NSString*)val;
-(id)initWithDoubleValue:(double)val;
-(id)initWithIntValue:(int)val;
-(id)initWithLabel:(NSString*)lab;

+(CellValue*)cellWithValue:(NSString*)val;
+(CellValue*)cellWithIntValue:(int)val;
+(CellValue*)cellWithDoubleValue:(double)val;
+(CellValue*)cellWithLabel:(NSString*)lab;
+(CellValue*)cellWithValue:(NSString*)val withLabel:(NSString*)lab;

@end
