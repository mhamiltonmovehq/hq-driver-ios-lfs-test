//
//  OpList.m
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//


#import "OpList.h"

@implementation OpList

@synthesize listID, serverListID, agent, name, businessLines, sections, commodity;

-(id)init
{
    
    if(self = [super init])
    {
        listID = -1;
        serverListID = nil;
    }
    
    return self;
}

-(void)dealloc
{

}

@end
