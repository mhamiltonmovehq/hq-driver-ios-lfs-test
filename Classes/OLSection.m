//
//  OLSection.m
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//

#import "OLSection.h"

@implementation OLSection

@synthesize sectionID, sectionName, questions, sortKey, listID, serverListID;

-(id)init
{
    
    if(self = [super init])
    {
        listID = -1;
    }
    
    return self;
}

-(void)dealloc
{

}

@end
