//
//  DocLibraryEntry.m
//  Survey
//
//  Created by Tony Brame on 5/22/13.
//
//

#import "DocLibraryEntry.h"
#import "SurveyAppDelegate.h"

@implementation DocLibraryEntry

-(void)dealloc
{
    self.url = nil;
    self.docName = nil;
    self.docPath = nil;
    self.savedDate = nil;
    self.progressView = nil;
    self.fileContents = nil;
    self.delegate = nil;
}

-(void)downloadDoc
{
    
    self.progressView = [[SmallProgressView alloc] initWithDefaultFrame:@"Downloading Document..."];
    
    //download the document.  if it errors, don't save...
    self.fileContents = [NSMutableData data];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(NSString*)fullDocPath
{
    NSString *docs = [SurveyAppDelegate getDocsDirectory];
    NSString *path = [docs stringByAppendingPathComponent:self.docPath];
   
    return path;
}

-(void)saveDocument:(NSData*)fileData withCustomerID:(int)customerID
{
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSString *docsDir = [SurveyAppDelegate getDocsDirectory];
    
    for(int i = 0; true; i++)
    {
        self.docPath = [NSString stringWithFormat:@"%@/%@", DOC_LIB_FOLDER, [NSString stringWithFormat:DOC_LIB_FILENAME, i]];
        if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:self.docPath]])
            break;
    }
    
    
    
    if(![mgr fileExistsAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]])
        [mgr createDirectoryAtPath:[docsDir stringByAppendingPathComponent:DOC_LIB_FOLDER]
       withIntermediateDirectories:YES
                        attributes:nil
                             error:nil];
    
    [mgr createFileAtPath:[self fullDocPath] contents:fileData attributes:nil];
    
    //now save to the database
    SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.savedDate = [NSDate date];
    
    self.customerID = customerID;
    
    self.docEntryID = [del.surveyDB saveDocLibraryEntry:self];
    
}

- (void)saveDocument:(NSData *)fileData
{
    [self saveDocument:fileData withCustomerID:0];
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int state = [httpResponse statusCode];
    
    if (state >= 400 && state <600)//error
    {
        [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Error retrieving data for document %@, please confirm the URL entered.", self.description]
                           withTitle:@"Invalid URL"];
        self.fileContents = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.fileContents != nil)
        [self.fileContents appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [SurveyAppDelegate showAlert:[NSString stringWithFormat:@"Invalid URL provided for document %@.", self.description]
                       withTitle:@"Invalid URL"];
    
    [self.progressView removeFromSuperview];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(self.fileContents != nil && self.fileContents.length > 0)
    {
        [self saveDocument:self.fileContents];
        if(self.delegate != nil && [self.delegate respondsToSelector:@selector(documentDownloaded:)])
            [self.delegate documentDownloaded:self];
    }
    else if(self.fileContents != nil)
    {
        [SurveyAppDelegate showAlert:@"File Content Length is zero." withTitle:@"File Contents"];
    }
    
    [self.progressView removeFromSuperview];
}

@end
