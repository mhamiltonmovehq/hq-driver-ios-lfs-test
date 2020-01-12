//
//  CrewViewController.m
//  Mobile Mover
//
//  Created by Matthew Hamilton on 1/12/20.
//

#import "CrewViewController.h"
#import "CrewCell.h"

@interface CrewViewController ()

@end

@implementation CrewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Crew"
     style:UIBarButtonItemStylePlain
    target:self
    action:nil];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CrewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CrewCell"];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CrewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    
    switch (indexPath.row) {
        case 0:
            cell.labelName.text = @"Bill Edison";
            cell.labelType.text = @"Packer";
            break;
        case 1:
            cell.labelName.text = @"Joe Smith";
            cell.labelType.text = @"Driver";
            break;
        case 2:
            cell.labelName.text = @"Neil Dobbs";
            cell.labelType.text = @"Helper";
            break;
        default:
            break;
    }
    
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Crew Members";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

@end
