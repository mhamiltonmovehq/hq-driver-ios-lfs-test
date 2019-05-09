//
//  DocLibraryEntry.h
//  Survey
//
//  Created by Tony Brame on 5/22/13.
//
//

#import <Foundation/Foundation.h>
#import "SmallProgressView.h"

#define DOC_LIB_FOLDER @"/DocLibrary"
#define DOC_LIB_FILENAME @"Doc[%d].pdf"

#define DOC_LIB_TYPE_GLOBAL 0
#define DOC_LIB_TYPE_CUST 1



@class DocLibraryEntry;
@protocol DocumentLibraryEntryDelegate <NSObject>
@optional
-(void)documentDownloaded:(DocLibraryEntry*)entry;
@end

@interface DocLibraryEntry : NSObject

@property (nonatomic) int docEntryID;
@property (nonatomic) int docEntryType;
@property (nonatomic) int customerID;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *docName;
@property (nonatomic, retain) NSString *docPath;
//also when doc is updated, date is updated (if it is a global doc w/url)
@property (nonatomic, retain) NSDate *savedDate;
@property (nonatomic, retain) NSMutableData *fileContents;
@property (nonatomic, retain) SmallProgressView *progressView;
@property (nonatomic, retain) id<DocumentLibraryEntryDelegate> delegate;

//indicating it has been uploaded to the server
@property (nonatomic) BOOL synchronized;

-(void)saveDocument:(NSData*)fileData withCustomerID:(int)customerID;
-(void)saveDocument:(NSData*)fileData;
-(NSString*)fullDocPath;
-(void)downloadDoc;

@end
