//
//  OLQuestion.h
//  Mobile Mover Auto Enterprise
//
//  Created by Xavier Shelton on 2/5/19.
//


#define QUESTION_TYPE_TEXT 1
#define QUESTION_TYPE_YESNO 2
#define QUESTION_TYPE_DATE 3
#define QUESTION_TYPE_QTY 4
#define QUESTION_TYPE_MULT 5
#define QUESTION_TYPE_DATETIME 6
#define QUESTION_TYPE_TIME 7
#define QUESITON_TYPE_QTY_DECIMAL 8


@interface OLQuestion : NSObject {
    int questionID;
    int questionType;
    NSString *question;
    NSMutableArray *mutlChoiceOptions;
    NSString *defaultAnswer;
    BOOL isLimit;
    int sortKey;
    NSString *serverListID;
}

@property (nonatomic) int questionID;
@property (nonatomic) int questionType;
@property (nonatomic) int sortKey;
@property (nonatomic) BOOL isLimit;
@property (nonatomic, retain) NSString *question;
@property (nonatomic, retain) NSString *defaultAnswer;
@property (nonatomic, retain) NSString *serverListID;
@property (nonatomic, retain) NSMutableArray *multChoiceOptions;

@end
