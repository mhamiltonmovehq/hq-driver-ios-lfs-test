//
//  ISktScanEvent.h
//  ScanApi
//
//  Created by Eric Glaenzer on 5/19/11.
//  Copyright 2011 SocketMobile. All rights reserved.
//
#import "SktScanTypes.h"
#import "ISktScanDecodedData.h"

@protocol ISktScanEvent

-(enum ESktScanEventID)ID;
-(enum ESktEventDataType)getDataType;
-(NSString*)getDataString;
-(uint8_t)getDataByte;
-(uint8_t*)getDataArrayValue;
-(uint32_t)getDataArraySize;
-(uint32_t)getDataLong;
-(id<ISktScanDecodedData>)getDataDecodedData;
@end
