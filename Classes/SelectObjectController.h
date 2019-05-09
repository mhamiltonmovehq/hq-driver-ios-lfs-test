//
//  SelectObjectController.h
//  Survey
//
//  Created by Tony Brame on 10/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectObjectController;
@protocol SelectObjectControllerDelegate <NSObject>
@optional
-(void)objectsSelected:(SelectObjectController*)controller withObjects:(NSArray*)collection;
-(NSMutableArray*)selectObjectControllerPreSelectedItems:(SelectObjectController*)controller;
-(BOOL)selectObjectControllerShouldDismiss:(SelectObjectController*)controller;
@end

@interface SelectObjectController : UITableViewController
{
    NSArray *choices;
    SEL displayMethod;
    BOOL multipleSelection;
    NSMutableArray *selectedItems;
    
    BOOL controllerPushed;
    
    BOOL allowsNoSelection;
    
    id<SelectObjectControllerDelegate> delegate;
}

@property (nonatomic, retain) NSArray *choices;
@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic, retain) id<SelectObjectControllerDelegate> delegate;
@property (nonatomic) SEL displayMethod;
@property (nonatomic) BOOL multipleSelection;
@property (nonatomic) BOOL controllerPushed;
@property (nonatomic) BOOL allowsNoSelection;

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

@end
