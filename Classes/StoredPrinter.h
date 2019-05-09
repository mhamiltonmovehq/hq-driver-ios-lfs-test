//
//  StoredPrinter.h
//  Survey
//
//  Created by Tony Brame on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoredPrinter : NSObject {
    int printerID;
    BOOL isDefault;
    int printerKind;
    BOOL isBonjour;
    int quality;
    NSString *address;
    NSString *name;
    NSDictionary *bonjourSettings;
    
    BOOL color;
}

@property (nonatomic) int printerID;
@property (nonatomic) int printerKind;
@property (nonatomic) int quality;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isBonjour;
@property (nonatomic) BOOL color;

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *bonjourSettings;

@end
