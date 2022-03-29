//
//  OLSection.h
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//


#import <Foundation/Foundation.h>

@interface OLSection : NSObject {
    int sectionID;
    int sortKey;
    int listID;
    NSString *sectionName;
    NSString *serverListID;
    NSMutableArray *questions;
}

@property (nonatomic) int sectionID;
@property (nonatomic) int sortKey;
@property (nonatomic) int listID;
@property (nonatomic, retain) NSString *sectionName;
@property (nonatomic, retain) NSString *serverListID;
@property (nonatomic, retain) NSMutableArray *questions;

@end
