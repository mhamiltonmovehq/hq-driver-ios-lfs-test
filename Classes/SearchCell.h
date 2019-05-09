//
//  SearchCell.h
//  Survey
//
//  Created by Tony Brame on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchCell : UITableViewCell
{
    IBOutlet UISearchBar *searchBar;
    IBOutlet UIButton *cmdSearch;
}

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIButton *cmdSearch;

@end
