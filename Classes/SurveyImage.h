//
//  SurveyImage.h
//  Survey
//
//  Created by Tony Brame on 8/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SurveyImage : NSObject {
//    int    imageID;
//    int custID;
//    int subID;
//    int photoType;
//    int refID;
//    NSString *path;
//
//    UIButton *imageButton;
}

@property (nonatomic) int imageID;
@property (nonatomic) int custID;
@property (nonatomic) int subID;
@property (nonatomic) int photoType;
@property (nonatomic) int refID;

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) UIButton *imageButton;

@end
