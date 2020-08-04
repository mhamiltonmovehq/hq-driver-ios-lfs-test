//
//  PVOImageParser.m
//  Survey
//
//  Created by Tony Brame on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SurveyAppDelegate.h"
#import "SurveyImageViewer.h"
#import "PVOImageParser.h"
#import "Base64.h"

@implementation PVOImageParser

@synthesize surveyedItemID, roomID, isWCF, locationID;

-(id)init
{
	if( self = [super init] )
	{
		currentString = [[NSMutableString alloc] init];
        isWCF = YES;
	}
	return self;
}


#pragma mark NSXMLParser Parsing Callbacks


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
	if([self thisElement:elementName isElement:@"Image"])
	{
        
    }
	else if((isWCF && [self thisElement:elementName isElement:@"ImageData"]) || 
			(isWCF && [self thisElement:elementName isElement:@"FileName"]) || 
            (!isWCF && [elementName isEqualToString:@"image_data"]))
	{
		//all root data
		storingData = YES;
        [currentString setString:@""];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	if((isWCF && [self thisElement:elementName isElement:@"Image"]) || 
       (!isWCF && [elementName isEqualToString:@"image"]))
	{
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        SurveyImageViewer *imageSaver = [[SurveyImageViewer alloc] init];
        
        imageSaver.customerID = del.customerID;
        
        //write out the image...
        if(surveyedItemID != 0)
        {
			imageSaver.photosType = IMG_SURVEYED_ITEMS;
			imageSaver.subID = surveyedItemID;
        }
        else if(roomID != 0)
        {
			imageSaver.photosType = IMG_ROOMS;
			imageSaver.subID = roomID;
        }
        else if(locationID != 0)
        {
			imageSaver.photosType = IMG_LOCATIONS;
			imageSaver.subID = locationID;
        }
        
        //save with the imageSaver...
        [imageSaver addPhotoToList:[UIImage imageWithData:currentImageData]];
        
        currentImageData = nil;
    }
	else if(storingData && 
            ((isWCF && [self thisElement:elementName isElement:@"ImageData"]) || 
            (!isWCF && [elementName isEqualToString:@"image_data"]))){
        //currentString has base64 image
        currentImageData = [Base64 decode64:currentString];
	}
	else if(storingData && [self thisElement:elementName isElement:@"FileName"]){
        
	}
	
	storingData = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	@throw parseError;
    // Handle errors as appropriate for your application.
}
#pragma mark JSON Parsing
-(void) parseJson:(NSDictionary*) jsonDictionary {
        SurveyAppDelegate *del = (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate];
        SurveyImageViewer *imageSaver = [[SurveyImageViewer alloc] init];
        imageSaver.customerID = del.customerID;
        
        //write out the image...
        if(surveyedItemID != 0)
        {
            imageSaver.photosType = IMG_SURVEYED_ITEMS;
            imageSaver.subID = surveyedItemID;
        }
        else if(roomID != 0)
        {
            imageSaver.photosType = IMG_ROOMS;
            imageSaver.subID = roomID;
        }
        else if(locationID != 0)
        {
            imageSaver.photosType = IMG_LOCATIONS;
            imageSaver.subID = locationID;
        }
    
    for (NSDictionary *imageRecord in jsonDictionary) {
        NSString *encodedImage = [imageRecord valueForKey:@"ImageData"];
        //save with the imageSaver...
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:encodedImage options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [UIImage imageWithData:imageData];
        [imageSaver addPhotoToList:image];
    }
}

@end
