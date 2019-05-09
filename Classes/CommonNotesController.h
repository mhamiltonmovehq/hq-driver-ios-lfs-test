//
//  CommonNotesController.h
//  Survey
//
//  Created by Tony Brame on 8/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommonNotesController : UITableViewController {
    int noteType;
    NSArray *options;
    NSObject *caller;
    SEL callback;
}

@property (nonatomic) int noteType;
@property (nonatomic) SEL callback;

@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) NSObject *caller;

-(void)enteredNewNote:(NSString*)newNote;

@end
