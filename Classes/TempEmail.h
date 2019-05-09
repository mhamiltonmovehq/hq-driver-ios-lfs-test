//
//  TempEmail.h
//  Survey
//
//  Created by DThomas on 8/12/14.
//
//

#import <Foundation/Foundation.h>

@interface TempEmail : NSObject{
    
    NSString *toEmail;
    NSString *toName;
    int custID;
    int EmailID;
    
}

@property(nonatomic, retain) NSString *toEmail;
@property(nonatomic, retain) NSString *toName;
@property (nonatomic) int custID;
@property (nonatomic) int EmailID;


@end
