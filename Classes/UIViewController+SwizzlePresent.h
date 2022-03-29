//
//  UIViewController+SwizzlePresent.h
//  Mobile Mover
//
//  Created by Matthew Hamilton on 1/3/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (SwizzlePresent)

+ (void) swizzlePresent;
- (void) swizzledPresentViewController:(UIViewController*)vc animated:(BOOL)isAnimated completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
