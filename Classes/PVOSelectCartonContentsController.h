//
//  PVOSelectCartonContentsController.h
//  Survey
//
//  Created by Tony Brame on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PVONewCartonContentsController.h"
#import "PVOFavoriteCartonContentsController.h"

@class PVOSelectCartonContentsController;
@class PVOCartonContent;

@protocol PVOSelectCartonContentsControllerDelegate <NSObject>
@optional
-(void)contentsController:(PVOSelectCartonContentsController*)controller selectedContent:(PVOCartonContent*)item;
-(void)contentsController:(PVOSelectCartonContentsController*)controller selectedContents:(NSMutableArray *)items;
-(void)contentsControllerCanceled:(PVOSelectCartonContentsController*)controller;
@end


@interface PVOSelectCartonContentsController : UIViewController <PVONewCartonContentsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
    NSArray *keys;
    NSArray *allItems;
    NSDictionary *contentsDictionary;
    
    id<PVOSelectCartonContentsControllerDelegate> delegate;
    
    PVONewCartonContentsController *pvoCartonContentController;
    
    BOOL goAwayAfterLoad;
    BOOL createNewItemMode;
        
    int currentSegment;
    
    IBOutlet UISegmentedControl *segmentFilter;    
    PVOFavoriteCartonContentsController *favoriteItems;
}

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) BOOL keyboardVisible;

@property (nonatomic, retain) NSArray *keys;
@property (nonatomic, retain) NSArray *allItems;
@property (nonatomic, retain) NSDictionary *contentsDictionary;
@property (nonatomic, retain) PVONewCartonContentsController *pvoCartonContentController;
@property (nonatomic, retain) id<PVOSelectCartonContentsControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentFilter;

@property (nonatomic, retain) NSMutableArray *selectedItems;
@property (nonatomic) BOOL useCheckBoxes;

-(IBAction)addContentItem:(id)sender;
-(IBAction)cancel:(id)sender;

-(IBAction)addSelectedItems:(id)sender;
-(void)reloadContentsList;

-(IBAction)selectedItem:(PVOCartonContent*)content;
-(IBAction)segmentFilter_changed:(id)sender;

@end
