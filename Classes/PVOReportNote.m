//
//  PVOReportNote.m
//  Survey
//
//  Created by Justin Little on 12/9/14.
//
//

#import "PVOReportNote.h"

@implementation PVOReportNote

@synthesize pvoReportNoteID, pvoReportNoteTypeID, reportNote;


-(id)init
{
    if(self = [super init])
    {
        pvoReportNoteTypeID = -1;
        reportNote = @"";
    }
    return self;
}

-(PVOReportNote*)initWithStatement:(sqlite3_stmt *)stmnt
{
    if (self = [self init])
    {
        int idx = 0;
        self.pvoReportNoteID = sqlite3_column_int(stmnt, idx);
        self.pvoReportNoteTypeID = sqlite3_column_int(stmnt, ++idx);
        self.reportNote = [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmnt, ++idx)];
    }
    return self;
}
@end
