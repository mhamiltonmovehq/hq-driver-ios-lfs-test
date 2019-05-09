//
//  CustomItemList.h
//  Survey
//
//  Created by Tony Brame on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CustomItemList : NSObject {
	int customItemListID;
	NSString *itemListName;	
}

@property (nonatomic) int customItemListID;
@property (nonatomic, retain) NSString *itemListName;

@end
