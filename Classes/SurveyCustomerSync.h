//
//  SurveyCustomerSync.h
//  Survey
//
//  Created by Tony Brame on 8/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface SurveyCustomerSync : NSObject {
	
	int custID;
	BOOL createdOnDevice;
	BOOL sync;
	BOOL syncToQM;
    BOOL syncToPVO;
	
	NSString *generalSyncID;
	NSString *atlasShipID;
	NSString *atlasSurveyID;
}

@property (nonatomic) int custID;
@property (nonatomic) BOOL createdOnDevice;
@property (nonatomic) BOOL sync;
@property (nonatomic) BOOL syncToQM;
@property (nonatomic) BOOL syncToPVO;

@property (nonatomic, retain) NSString *generalSyncID;
@property (nonatomic, retain) NSString *atlasShipID;
@property (nonatomic, retain) NSString *atlasSurveyID;

-(void)flushToXML:(XMLWriter*)xml sendToQM:(BOOL)toQM;

@end
