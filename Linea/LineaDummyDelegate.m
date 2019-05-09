//
//  LineaDummyDelegate.m
//  Survey
//
//  Created by Tony Brame on 4/24/13.
//
//

#import "LineaDummyDelegate.h"
#import "SurveyAppDelegate.h"

@implementation LineaDummyDelegate


#pragma mark - LineaDelegate methods

-(void)connectionState:(int)state {
//    switch (state) {
//        case CONN_DISCONNECTED:
//            [SurveyAppDelegate showAlert:@"Disconnected!" withTitle:@"Linea"];
//            break;
//        case CONN_CONNECTING:
//            [SurveyAppDelegate showAlert:@"Connecting!" withTitle:@"Linea"];
//            break;
//        case CONN_CONNECTED:
//            [SurveyAppDelegate showAlert:@"Connected!" withTitle:@"Linea"];
//            break;
//    }
}

-(void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
    [self barcodeData:barcode type:-1];//dont care about type...
}

-(void)barcodeData:(NSString *)barcode type:(int)type
{
    
    
}

@end
