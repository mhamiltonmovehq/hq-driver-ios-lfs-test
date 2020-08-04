//
//  PortraitNavController.h
//
//  Created by Tony Brame on 10/22/12.
//
//

#import <UIKit/UIKit.h>

@interface PortraitNavController : UINavigationController {
    NSObject *dismissDelegate;
    SEL dismissCallback;
}

@property (nonatomic) NSObject *dismissDelegate;
@property (nonatomic) SEL dismissCallback;

@end
