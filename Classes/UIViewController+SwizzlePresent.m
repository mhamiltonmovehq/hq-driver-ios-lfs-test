//
//  UIViewController+SwizzlePresent.m
//  Mobile Mover
//
//  Created by Matthew Hamilton on 1/3/20.
//

#import "UIViewController+SwizzlePresent.h"

#import <objc/runtime.h>


@implementation UIViewController (SwizzlePresent)

+ (void) swizzlePresent
{
    Class class = [self class];
    
    SEL originalSelector = @selector(presentViewController:animated:completion:);
    SEL swizzledSelector = @selector(swizzledPresentViewController:animated:completion:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
        class_addMethod(class,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void) swizzledPresentViewController:(UIViewController*)vc animated:(BOOL)isAnimated completion:(void(^)(void))completion
{
    //Example of what we're swizzling:
    //[del.navController presentViewController:syncViewController animated:YES completion:nil];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self swizzledPresentViewController:vc animated:isAnimated completion:completion];
}

@end
