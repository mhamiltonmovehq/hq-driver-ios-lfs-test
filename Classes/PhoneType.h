//
//  PhoneType.h
//  Survey
//
//  Created by Tony Brame on 5/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PhoneType : NSObject {
	NSInteger phoneTypeID;
	NSString *name;
}

@property (nonatomic) NSInteger phoneTypeID;
@property (nonatomic, retain) NSString *name;

@end
