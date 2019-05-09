//
//  TablePickerController.h
//  Survey
//
//  Created by Tony Brame on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TablePickerController : UITableViewController <UINavigationControllerDelegate> {
    id objects;
    id currentValue;
    id caller;
    SEL callback;
    
    BOOL showingModal;
    
    BOOL selectOnCheck;
    
    NSArray *keys;
}

@property (nonatomic) SEL callback;
@property (nonatomic) BOOL showingModal;
@property (nonatomic) BOOL selectOnCheck;
@property (nonatomic) BOOL skipInventoryProcess;
@property (nonatomic) BOOL exitWithSave;
@property (nonatomic, strong) id objects;
@property (nonatomic, strong) id currentValue;
@property (nonatomic, strong) id caller;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
