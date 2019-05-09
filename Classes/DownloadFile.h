//
//  DownloadFile.h
//  Survey
//
//  Created by Tony Brame on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DownloadFile : NSObject {    
    NSObject *caller;
    SEL sizeCallback;
    SEL messageCallback;
    SEL receivedDataCallback;
    SEL completedCallback;    
    SEL errorCallback;    
    NSURLConnection *conn;
    long long totalLength;
    long long received;
    long long writ;
    NSString *fileName;
    NSString *fullFilePath;
    NSString *downloadURL;
    NSString *downloadLocationFolder;
    FILE *fileRef;
}

@property (nonatomic) SEL sizeCallback;
@property (nonatomic) SEL messageCallback;
@property (nonatomic) SEL receivedDataCallback;
@property (nonatomic) SEL completedCallback;
@property (nonatomic) SEL errorCallback;
@property (nonatomic) long long totalLength;
@property (nonatomic) long long received;

@property (nonatomic) BOOL unzipFile;

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fullFilePath;
@property (nonatomic, strong) NSString *downloadLocationFolder;
@property (nonatomic, strong) NSString *downloadURL;
@property (nonatomic, strong) NSObject *caller;
@property (nonatomic, strong) NSURLConnection *conn;

-(void)receivedData;
-(void)updateMessage:(NSString*)updateString;
-(void)completed;
-(void)error;
-(void)cancel;

-(void)updateSize:(long long)size;

-(void)start;

@end
