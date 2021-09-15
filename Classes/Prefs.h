//
//  Prefs.h
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define USERNAME_KEY @"igcUsername"
#define PASSWORD_KEY @"igcPassword"
#define QM_ADDRESS_KEY @"qmAddress"
#define QM_PORT_KEY @"qmPort"
#define QM_USERNAME_KEY @"qmUsername"
#define MAIL_BCC_SENDER_KEY @"bccSender"
#define MAIL_USE_CUSTOM_KEY @"customMail"
#define MAIL_SERVER_KEY @"mailServerAddress"
#define MAIL_USERNAME_KEY @"mailUsername"
#define MAIL_PASSWORD_KEY @"mailPassword"
#define MAIL_SSL_KEY @"mailUseSSL"
#define MAIL_PORT_KEY @"mailPort"
#define BETA_PASS_KEY @"betaPassword"
#define REPORTS_PASS_KEY @"reportsPassword"
#define BROTHER_PRINTER_KEY @"brotherPrinterIP"
#define CURRENT_PRICING_DB_VERSION  @"currentPricingDBVersion"


@interface Prefs : NSObject {

}

+(NSString*)username;
+(NSString*)password;

+(NSString*)qmAddress;
+(int)qmPort;
+(NSString*)qmUsername;

+(BOOL)bccSender;
+(BOOL)useCustomServer;
+(BOOL)useSSL;

+(NSString*)mailServer;
+(NSString*)mailUsername;
+(NSString*)mailPassword;
+(int)mailPort;

+(NSString*)betaPassword;
+(NSString*)reportsPassword;

+(NSMutableDictionary*)brotherSettings;
+(void)setBrotherSettings:(NSMutableDictionary*)values;

+(int)currentPricingDBVersion;
+(void)setCurrentPricingDBVersion:(NSInteger)i;

@end
