//
//  PVOItemComment.m
//  Survey
//
//  Created by Justin Little on 7/7/14.
//
//

#import "PVOItemComment.h"


@implementation PVOItemComment

@synthesize comment, commentType;


-(void)flushToXML:(XMLWriter*)retval
{
    [retval writeStartElement:@"comment"];
    [retval writeAttribute:@"type" withData:[NSString stringWithFormat:@"%d", self.commentType]];
    [retval writeAttribute:@"note" withData:comment];
    [retval writeEndElement];
}


@end
