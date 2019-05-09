//
//  SignatureView.h
//  Survey
//
//  Created by Tony Brame on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SignatureView : UIImageView {
    
    CGPoint lastPoint;
    
    BOOL settingImageFirst;
    BOOL touchEventOccurred;
    
    UIButton *cmdClear;
}

@property (nonatomic, strong) UIButton *cmdClear;
@property (nonatomic) BOOL touchEventOccurred;

-(IBAction)clearSignature:(id)sender;

@end
