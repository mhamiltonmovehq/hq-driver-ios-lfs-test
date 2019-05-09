//
//  PVOReportNote.h
//  Survey
//
//  Created by Justin Little on 12/9/14.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>


#define PVO_REPORT_NOTE_TYPE_RIDER_EXCEPTIONS 1
#define PVO_REPORT_NOTE_TYPE_ORG_INVENTORY 2
#define PVO_REPORT_NOTE_TYPE_DEST_INVENTORY 3
#define PVO_REPORT_NOTE_TYPE_ORG_HIGH_VALUE 4
#define PVO_REPORT_NOTE_TYPE_DEST_HIGH_VALUE 5
#define PVO_REPORT_NOTE_TYPE_ESIGN_AGREEMENT 6
#define PVO_REPORT_NOTE_TYPE_CLAIM 7
#define PVO_REPORT_NOTE_TYPE_ROOM_CONDITIONS 8


@interface PVOReportNote : NSObject {
    
}

@property (nonatomic) int pvoReportNoteID;
@property (nonatomic) int pvoReportNoteTypeID;
@property (nonatomic, retain) NSString *reportNote;

-(PVOReportNote*)initWithStatement:(sqlite3_stmt*)stmnt;

//+(NSArray*)getReportNoteTypes:(BOOL)isOrigin;

@end
