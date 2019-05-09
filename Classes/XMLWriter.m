//
//  XMLWriter.m
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XMLWriter.h"


@implementation XMLWriter

@synthesize file;

-(id)init
{
	if(self = [super init])
	{
		self.file = [[NSMutableString alloc] init];
		nodes = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void)writeStartDocument
{
	[nodes removeAllObjects];
	[file replaceCharactersInRange:NSMakeRange(0, [file length]) withString:@""];
	[file appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
}

-(void)writeStartElement:(NSString*)name
{	
	[nodes addObject:name];
	[file appendString:[NSString stringWithFormat:@"<%@>", name]];
}

-(void)writeElementString:(NSString*)name withDoubleData:(double)data
{
    [self writeElementString:name withData:[[NSNumber numberWithDouble:data] stringValue]];
}
-(void)writeElementString:(NSString*)name withIntData:(int)data
{
	[self writeElementString:name withIntData:data ignoreZero:NO];
}

-(void)writeElementString:(NSString*)name withIntData:(int)data ignoreZero:(BOOL)ignore
{
	if(data >= 0 || !ignore)//if ignoring zero, dont check for zero, write it anyways
		[self writeElementString:name withData:[[NSNumber numberWithInt:data] stringValue]];
}

-(void)writeElementString:(NSString*)name withData:(NSString*)data
{

	//need this data for wcfs
//	if(data != nil && [data length] > 0)
//	{
		[self writeStartElement:name];
		
		NSString *formattedString = [XMLWriter formatString:data];
		
		[file appendString:formattedString];
    
		[self writeEndElement];
//	}
	
}

-(void)writeExistingNode:(NSString*)data
{
    [file appendString:data];
}

+(NSString*)formatString:(NSString*)original
{
    if(original == nil)
        return [[NSString alloc] initWithString:@""];
    
    NSMutableString *retval = [[NSMutableString alloc] initWithString:original];
	
	//first replace all "&" strings with "A#M#P#;#"
	[retval replaceOccurrencesOfString:@"&" 
						  withString:@"A#M#P#;#" 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [retval length])];
	
	//\" to &quot;
	[retval replaceOccurrencesOfString:@"\"" 
						  withString:@"&quot;" 
							 options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	//' to &apos;
	[retval replaceOccurrencesOfString:@"'" 
							withString:@"&apos;" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	//< to &lt;
	[retval replaceOccurrencesOfString:@"<" 
							withString:@"&lt;" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	//> to &gt;
	[retval replaceOccurrencesOfString:@">" 
							withString:@"&gt;" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	//> to &gt;
	[retval replaceOccurrencesOfString:@">" 
							withString:@"&gt;" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	
	//"A#M#P#;#" to &amp;
	[retval replaceOccurrencesOfString:@"A#M#P#;#" 
							withString:@"&amp;" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [retval length])];
	
	
	//chars > 127 should be written as a number...
	unichar current;	
	for(int i = 0; i < [retval length]; i++)
	{
		current = [retval characterAtIndex:i];
		if(current > 127 || current < 32)
		{
			[retval replaceCharactersInRange:NSMakeRange(i, 1) 
								  withString:[NSString stringWithFormat:@"&#%d;", current]];// [[NSNumber numberWithUnsignedShort:current] stringValue]]];
		}
	}
	
	return retval;
}

-(void)writeAttribute:(NSString*)name withDoubleData:(double)data
{
    [self writeAttribute:name withData:[[NSNumber numberWithDouble:data] stringValue]];
}

-(void)writeAttribute:(NSString*)name withIntData:(int)data
{
    [self writeAttribute:name withData:[[NSNumber numberWithInt:data] stringValue]];
}

-(void)writeAttribute:(NSString*)name withData:(NSString*)data
{
	NSUInteger loc = [file length] - 1;
    if(data == nil)
        [file insertString:[NSString stringWithFormat:@" %@=\"\"", name] atIndex:loc];
    else
        [file insertString:[NSString stringWithFormat:@" %@=\"%@\"", name, [XMLWriter formatString:data]] atIndex:loc];
}

-(void)writeEndElement
{
	//look to see if it was ever written to...
//	NSString *nodeName = [nodes lastObject];
//	NSRange range;
//	range.length = [nodeName length];
//	range.location = ([file length]-1) - range.length;
//	
//	if([[file substringWithRange:range] compare:nodeName] == NSOrderedSame && 
//	   [file characterAtIndex:range.location-1] == '<')
//	{//it was <node> at the end, so just make it <node />
//		[file insertString:@" /" atIndex:[file length] - 1];
//	}
//	else
//		[file appendString:[NSString stringWithFormat:@"</%@>", nodeName]];
//	
//	[nodes removeLastObject];
    
    
    //look to see if it was ever written to...
    NSString *nodeName = [nodes lastObject];
    NSRange range;

    //check for a following > to see if the node was ever closed.
    range = [file rangeOfString:[@"<" stringByAppendingString:nodeName] options:NSBackwardsSearch];
    range = [file rangeOfString:@">" options:0 range:NSMakeRange(range.location, [file length] - range.location)];
    //make sure it isnt </nodeName[otherchars]>, or <nodeName[otherchars] />
    if(range.location == [file length]-1 && [file characterAtIndex:[file length]-1] != '/')
        [file insertString:@" /" atIndex:[file length] - 1];
    else
        [file appendString:[NSString stringWithFormat:@"</%@>", nodeName]];
    
    
    [nodes removeLastObject];
    
}

-(void)writeEndDocument
{
	while([nodes count] > 0)
		[self writeEndElement];
}

@end
