//
//  Prefs.m
//  Survey
//
//  Created by Tony Brame on 8/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Prefs.h"


@implementation Prefs

+(NSString*)username
{
#if defined(OVERRIDE_USER_NAME)
    return OVERRIDE_USER_NAME;
#else
    return [[NSUserDefaults standardUserDefaults] objectForKey:USERNAME_KEY];
#endif
}

+(NSString*)password
{
#if defined(OVERRIDE_PASSWORD)
    return OVERRIDE_PASSWORD;
#else
    return [[NSUserDefaults standardUserDefaults] objectForKey:PASSWORD_KEY];
#endif
}

+(NSString*)qmAddress
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:QM_ADDRESS_KEY];	
}

+(int)qmPort
{
	NSString *temp = [[NSUserDefaults standardUserDefaults] objectForKey:QM_PORT_KEY];
	return [temp intValue];	
}

+(NSString*)qmUsername
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:QM_USERNAME_KEY];	
}

+(BOOL)bccSender
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MAIL_BCC_SENDER_KEY] intValue] > 0;
}

+(BOOL)useCustomServer
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MAIL_USE_CUSTOM_KEY] intValue] > 0;
}

+(BOOL)useSSL
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MAIL_SSL_KEY] intValue] > 0;
}

+(NSString*)mailServer
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MAIL_SERVER_KEY];	
}

+(NSString*)mailUsername
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MAIL_USERNAME_KEY];	
}

+(NSString*)mailPassword
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:MAIL_PASSWORD_KEY];	
}

+(int)mailPort
{
	NSString *temp = [[NSUserDefaults standardUserDefaults] objectForKey:MAIL_PORT_KEY];
	return [temp intValue];	
}

+(NSString*)betaPassword
{
#if defined(OVERRIDE_BETA_PASSWORD)
    return OVERRIDE_BETA_PASSWORD;
#else
    return [[NSUserDefaults standardUserDefaults] objectForKey:BETA_PASS_KEY];
#endif
}

+(NSString*)reportsPassword
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:REPORTS_PASS_KEY];	
}

+(NSMutableDictionary*)brotherSettings
{
    return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:BROTHER_PRINTER_KEY]];
}

+(void)setBrotherSettings:(NSMutableDictionary*)values
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:values forKey:BROTHER_PRINTER_KEY];
    [defaults synchronize];
}


@end
