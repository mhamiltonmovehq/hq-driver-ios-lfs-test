//
//  UIImage+Utilities.m
//  Survey
//
//  Created by Brian Prescott on 9/21/17.
//
//

#import "UIImage+Utilities.h"

@implementation UIImage (Utilities)

#define SAFECOLOR(color) MIN(255,MAX(0,color))

void CalculateAutocorretionValues(CGImageRef image, CGFloat *whitePoint, CGFloat *blackPoint) {
    
    UInt8* imageData = malloc(100 * 100 * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(imageData, 100, 100, 8, 4 * 100, colorSpace, kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, 100, 100), image);
    
    int histogramm[256];
    bzero(histogramm, 256 * sizeof(int));
    
    for (int i = 0; i < 100 * 100 * 4; i += 4) {
        UInt8 value = (imageData[i] + imageData[i+1] + imageData[i+2]) / 3;
        histogramm[value]++;
    }
    
    CGContextRelease(ctx);
    free(imageData);
    
    int black = 0;
    int counter = 0;
    
    // count up to 200 (2%) values from the black side of the histogramm to find the black point
    while ((counter < 200) && (black < 256)) {
        counter += histogramm[black];
        black ++;
    }
    
    int white = 255;
    counter = 0;
    
    // count up to 200 (2%) values from the white side of the histogramm to find the white point
    while ((counter < 200) && (white > 0)) {
        counter += histogramm[white];
        white --;
    }
    
    *blackPoint = 0.0 - (black / 256.0);
    *whitePoint = 1.0 + ((255-white) / 256.0);
    
}

- (UIImage*) imageWithAutoLevels {
    
    CGFloat whitePoint;
    CGFloat blackPoint;
    
    CalculateAutocorretionValues(self.CGImage, &whitePoint, &blackPoint);
    
    const CGFloat decode[6] = {blackPoint,whitePoint,blackPoint,whitePoint,blackPoint,whitePoint};
    
    CGImageRef decodedImage;
    
    decodedImage = CGImageCreate(CGImageGetWidth(self.CGImage),
                                 CGImageGetHeight(self.CGImage),
                                 CGImageGetBitsPerComponent(self.CGImage),
                                 CGImageGetBitsPerPixel(self.CGImage),
                                 CGImageGetBytesPerRow(self.CGImage),
                                 CGImageGetColorSpace(self.CGImage),
                                 CGImageGetBitmapInfo(self.CGImage),
                                 CGImageGetDataProvider(self.CGImage),
                                 decode,
                                 YES,
                                 CGImageGetRenderingIntent(self.CGImage)
                                 );
    
    UIImage* newImage = [UIImage imageWithCGImage:decodedImage];
    
    CGImageRelease(decodedImage);
    
    return newImage;
    
}

- (UIImage*) imageWithBrightness:(CGFloat)brightnessFactor {
    
    if ( brightnessFactor == 0 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i;
        uint8_t* green = rawData + (i + 1);
        uint8_t* blue = rawData + (i + 2);
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * brightnessFactor))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * brightnessFactor))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * brightnessFactor))));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
    
}

- (UIImage*) imageWithContrast:(CGFloat)contrastFactor {
    
    if ( contrastFactor == 1 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i;
        uint8_t* green = rawData + (i + 1);
        uint8_t* blue = rawData + (i + 2);
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
    
}

- (UIImage*) imageWithContrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor {
    
    if ( contrastFactor == 1 && brightnessFactor == 0 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i;
        uint8_t* green = rawData + (i + 1);
        uint8_t* blue = rawData + (i + 2);
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * brightnessFactor))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * brightnessFactor))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * brightnessFactor))));
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
    
}

- (UIImage *)blackAndWhiteImage
{
    UIGraphicsBeginImageContextWithOptions(self.size, YES, 1.0);
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    // Draw the image with the luminosity blend mode.
    [self drawInRect:imageRect blendMode:kCGBlendModeLuminosity alpha:1.0];
    // Get the resulting image.
    UIImage *filteredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return filteredImage;
}

@end
