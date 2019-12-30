//
//  OpList.h
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//

#import <Foundation/Foundation.h>

#define MOVE_TYPE_INTERSTATE 0
#define MOVE_TYPE_INTRASTATE 1
#define MOVE_TYPE_OI 2
#define MOVE_TYPE_LOCAL_US 1
#define MOVE_TYPE_MILITARY 4
#define MOVE_TYPE_CROSS_BORDER 5
#define MOVE_TYPE_ALASKA 6
#define MOVE_TYPE_HAWAII 7
#define MOVE_TYPE_INTERNATIONAL 8
#define MOVE_TYPE_MAX3 9
#define MOVE_TYPE_MAX4 10

@interface OpList : NSObject {
    int listID;
    NSString *serverListID;
    
    NSString *agent;
    NSString *name;
    
    NSString *commodity;
    
    NSMutableArray *businessLines;
    NSMutableArray *sections;
}

@property (nonatomic) int listID;
@property (nonatomic, retain) NSString *serverListID;

@property (nonatomic, retain) NSString *agent;
@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSMutableArray *businessLines;
@property (nonatomic, retain) NSMutableArray *sections;

@property (nonatomic, retain) NSString *commodity;

@end
