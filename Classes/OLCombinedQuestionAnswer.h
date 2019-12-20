//
//  OLCombinedQuestionAnswer.h
//  Survey
//
//  Created by Matthew Hamilton on 3/27/19.
//

#import <Foundation/Foundation.h>
#import "OLQuestion.h"
#import "OLAppliedItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface OLCombinedQuestionAnswer : NSObject

@property (nonatomic) int questionId;
@property (nonatomic) int sectionId;
@property (nonatomic) int customerId;

@property (nonatomic, retain) OLQuestion *question;
@property (nonatomic, retain) OLAppliedItem *answer;

@end

NS_ASSUME_NONNULL_END
