//
//  PVOConditionEntry.m
//  Survey
//
//  Created by Tony Brame on 3/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PVOConditionEntry.h"


@implementation PVOConditionEntry

@synthesize conditions;
@synthesize locations;
@synthesize pvoItemID;
@synthesize pvoDamageID;
@synthesize damageType;

@synthesize pvoLoadID;
@synthesize pvoUnloadID;

-(id)init
{
    if (!(self = [super init])) return nil;
    if (self)
    {
        damageType = DAMAGE_LOADING;
    }
    return self;
}


-(NSArray*)conditionArray
{
    //will return one for a blank string, need to make sure that doesn't happen
    if(conditions == nil || [conditions length] == 0)
        return [NSArray array];
    else
        return [conditions componentsSeparatedByString:@","];
}

-(NSArray*)locationArray
{
    //will return one for a blank string, need to make sure that doesn't happen
    if(locations == nil || [locations length] == 0)
        return [NSArray array];
    else
        return [locations componentsSeparatedByString:@","];
}

-(void)addCondition:(NSString*)condition
{
    if(conditions == nil || [conditions length] == 0)
        self.conditions = condition;
    else
        self.conditions = [conditions stringByAppendingFormat:@",%@", condition];
}

-(void)addLocation:(NSString*)location
{
    if(locations == nil || [locations length] == 0)
        self.locations = location;
    else
        self.locations = [locations stringByAppendingFormat:@",%@", location];
}

-(NSString*)getLastCondition
{
    NSMutableArray *locs = [[NSMutableArray alloc] initWithArray:[locations componentsSeparatedByString:@","]];
    NSString *retval = [locs lastObject];
    
    return retval;
}

-(void)removeLastCondition
{
    
    if(conditions != nil && [conditions length] != 0)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] initWithArray:[conditions componentsSeparatedByString:@","]];
        [retval removeLastObject];
        
        self.conditions = [retval componentsJoinedByString:@","];
    }
}

-(NSString*)getLastLocation
{
    NSMutableArray *conds = [[NSMutableArray alloc] initWithArray:[locations componentsSeparatedByString:@","]];
    NSString *retval = [conds lastObject];
    
    return retval;
}

-(void)removeLastLocation
{
    
    if(locations != nil && [locations length] != 0)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] initWithArray:[locations componentsSeparatedByString:@","]];
        [retval removeLastObject];
        
        self.locations = [retval componentsJoinedByString:@","];
    }
}

-(void)removeLocation:(NSString*)location
{
    //remove from the back
    if(locations != nil && [locations length] != 0)
    {
        //remove from end, then beginnnig, then lonesome
        int originalLen = [locations length];
        
        self.locations = [locations stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@",%@", location]
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                   range:NSMakeRange(0, [locations length])];
        
        if(originalLen != [locations length])
            return;
        
        self.locations = [locations stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@,", location]
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                   range:NSMakeRange(0, [locations length])];
        
        if(originalLen != [locations length])
            return;
        
        self.locations = [locations stringByReplacingOccurrencesOfString:location 
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                   range:NSMakeRange(0, [locations length])];
        
        if(originalLen != [locations length])
            return;
        
    }
}

-(void)removeConditionFromArray:(NSString*)condition
{
    
    if(conditions != nil && [conditions length] != 0)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] initWithArray:[conditions componentsSeparatedByString:@","]];
        //        int toRemove = [retval indexOfObject:condition];
        [retval removeObject:condition];
        
        self.conditions = [retval componentsJoinedByString:@","];
    }
}

-(void)removeLocationFromArray:(NSString*)location
{
    
    if(locations != nil && [locations length] != 0)
    {
        NSMutableArray *retval = [[NSMutableArray alloc] initWithArray:[locations componentsSeparatedByString:@","]];
        //        int toRemove = [retval indexOfObject:location];
        [retval removeObject:location];
        
        self.locations = [retval componentsJoinedByString:@","];
    }
}

-(void)removeCondition:(NSString*)condition
{
    
    if(conditions != nil && [conditions length] != 0)
    {
        //remove from end, then beginnnig, then lonesome
        int originalLen = [locations length];
        
        self.conditions = [conditions stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@",%@", condition]
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                     range:NSMakeRange(0, [conditions length])];
        
        if(originalLen != [locations length])
            return;
        
        self.conditions = [conditions stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@,", condition]
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                     range:NSMakeRange(0, [conditions length])];
        
        if(originalLen != [locations length])
            return;
        
        self.conditions = [conditions stringByReplacingOccurrencesOfString:condition 
                                                              withString:@"" 
                                                                 options:NSBackwardsSearch 
                                                                     range:NSMakeRange(0, [conditions length])];
        
        if(originalLen != [locations length])
            return;
        
        
    }
}

-(BOOL)isEmpty
{
    if((conditions == nil || [conditions length] == 0) && 
       (locations == nil || [locations length] == 0))
        return TRUE;
    else
        return FALSE;
}

+(NSString*)pluralizeLocation:(NSDictionary*)locDict withKey:(NSString*)key
{
    if([key characterAtIndex:0] == '(')
    {
        NSString *retval = [locDict objectForKey:[PVOConditionEntry depluralizeLocationCode:key]];
        
        //make "Shelf" == "Shelves"
        if([retval characterAtIndex:[retval length]-1] == 'f')
            retval = [[retval substringToIndex:[retval length]-1] stringByAppendingString:@"ves"];
        else
            retval = [retval stringByAppendingString:@"s"];
        
        return retval;
    }
    else
        return [locDict objectForKey:key];
}

//change ([code]s) to [code]
+(NSString*)depluralizeLocationCode:(NSString*)code
{
    return [[[code stringByReplacingOccurrencesOfString:@"(" withString:@""]
             stringByReplacingOccurrencesOfString:@"s)" withString:@""]
            stringByReplacingOccurrencesOfString:@"S)" withString:@""];
}

@end
