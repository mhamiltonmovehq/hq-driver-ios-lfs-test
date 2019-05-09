//
//  SurveyDates.h
//  Survey
//
//  Created by Tony Brame on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLWriter.h"

@interface SurveyDates : NSObject {
    NSDate *packFrom;
    NSDate *packTo;
    NSDate *packPrefer;
    NSDate *loadFrom;
    NSDate *loadTo;
    NSDate *loadPrefer;
    NSDate *deliverFrom;
    NSDate *deliverTo;
    NSDate *deliverPrefer;
    NSDate *survey;
    NSDate *followUp;
    NSDate *decision;
    NSDate *inventory;
    int custID;
    BOOL noPack;
    BOOL noLoad;
    BOOL noDeliver;
}

@property (nonatomic) int custID;
@property (nonatomic) BOOL noPack;
@property (nonatomic) BOOL noLoad;
@property (nonatomic) BOOL noDeliver; 

@property (nonatomic, strong) NSDate *packFrom;
@property (nonatomic, strong) NSDate *packTo;
@property (nonatomic, strong) NSDate *packPrefer;
@property (nonatomic, strong) NSDate *loadFrom;
@property (nonatomic, strong) NSDate *loadTo;
@property (nonatomic, strong) NSDate *loadPrefer;
@property (nonatomic, strong) NSDate *deliverFrom;
@property (nonatomic, strong) NSDate *deliverTo;
@property (nonatomic, strong) NSDate *deliverPrefer;
@property (nonatomic, strong) NSDate *survey;
@property (nonatomic, strong) NSDate *followUp;
@property (nonatomic, strong) NSDate *decision;
@property (nonatomic, strong) NSDate *inventory;

-(void)setToToday;
-(void)setToToday:(BOOL)includePackLoadDelv;
-(void)flushToXML:(XMLWriter*)xml;

@end
