//
//  CustomerListItem.h
//  Survey
//
//  Created by Tony Brame on 5/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomerListItem : NSObject {
	NSString *name;
	NSDate *date;
	int custID;
    NSString *orderNumber;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *orderNumber;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) int custID;

@end
