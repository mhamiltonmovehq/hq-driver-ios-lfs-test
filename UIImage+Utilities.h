//
//  UIImage+Utilities.h
//  Survey
//
//  Created by Brian Prescott on 9/21/17.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Utilities)

- (UIImage*) imageWithAutoLevels;

- (UIImage*) imageWithBrightness:(CGFloat)brightnessFactor;

- (UIImage*) imageWithContrast:(CGFloat)contrastFactor;
- (UIImage*) imageWithContrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor;

- (UIImage *)blackAndWhiteImage;

@end
