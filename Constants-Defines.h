//
//  Constants-Defines.h
//  Survey
//
//  Created by Brian Prescott on 9/7/16.
//
//

#ifndef Constants_Defines_h
#define Constants_Defines_h

#define SURVEY_APP_DELEGATE     (SurveyAppDelegate *)[[UIApplication sharedApplication] delegate]
#define SURVEY_DB               (SurveyDB *)(SURVEY_APP_DELEGATE).surveyDB
#define PRICING_DB              (PricingDB *)(SURVEY_APP_DELEGATE).pricingDB
#define SURVEY_SQLITE_DB        (sqlite3 *)SURVEY_DB.dbReference
#define CUSTOMER_ID             (SURVEY_APP_DELEGATE).customerID
#define APP_VERSION             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define APP_BUILD_NUMBER        [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]

#define TO_PRINTER(v) v
//#define TO_PRINTER(v) floor((v) / 72.0 * resolution)
#define MARGIN (72.0 * 0.2)

#define TO_PRINTER_PDF(v) floor((v) / 72.0 * _resolution)
#define MARGIN_PDF (72.0 * 0.2)

#define DEFAULT_FONT [UIFont systemFontOfSize:TO_PRINTER(12.0)]


















#endif /* Constants_Defines_h */
