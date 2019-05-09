//
//  XMLWriter.h
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XMLWriter : NSObject {
	NSMutableArray *nodes;
	NSMutableString *file;
}

@property (nonatomic, retain) NSMutableString *file;

-(void)writeStartDocument;
-(void)writeStartElement:(NSString*)name;
-(void)writeElementString:(NSString*)name withDoubleData:(double)data;
-(void)writeElementString:(NSString*)name withData:(NSString*)data;
-(void)writeElementString:(NSString*)name withIntData:(int)data;
-(void)writeElementString:(NSString*)name withIntData:(int)data ignoreZero:(BOOL)ignore;
-(void)writeAttribute:(NSString*)name withDoubleData:(double)data;
-(void)writeAttribute:(NSString*)name withIntData:(int)data;
-(void)writeAttribute:(NSString*)name withData:(NSString*)data;
-(void)writeExistingNode:(NSString*)data;
-(void)writeEndElement;
-(void)writeEndDocument;
+(NSString*)formatString:(NSString*)original;

@end
