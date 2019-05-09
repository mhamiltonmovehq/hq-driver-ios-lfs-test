//
//  CubeSheet.h
//  Survey
//
//  Created by Tony Brame on 6/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CubeSheet : NSObject {
	int csID;
	int custID;
	double weightFactor;
}

@property (nonatomic) int csID;
@property (nonatomic) double weightFactor;
@property (nonatomic) int custID;

@end
