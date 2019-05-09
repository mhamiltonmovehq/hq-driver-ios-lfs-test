//
//  ISktScanObject.h
//  ScanApi
//
//  Created by Jimmy Yang on 11-1-26.
//  Copyright 2011 SocketMobile. All rights reserved.
//

#import "ISktScanMsg.h"
#import "ISktScanProperty.h"

@protocol ISktScanObject

-(id<ISktScanMsg>) Msg;
-(id<ISktScanProperty>) Property;
 
@end
