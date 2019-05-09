//
//  BrotherOldSDKStructs.h
//  Survey
//
//  Created by Tony Brame on 2/6/15.
//
//

#import <Foundation/Foundation.h>

@class BRPtouchPrintInfo;

typedef enum
{
    kPaperSizeLetter=1,
    kPaperSizeLegal,
    kPaperSizeA4,
} PJPAPERSIZE;

typedef enum
{
    kPaperTypeRoll = 1,
    kPaperTypeCutsheet,
    kPaperTypePerfRoll,
    kPaperTypePerfRollRetract
} PJPAPERTYPE;

typedef enum
{
    kFormFeedModeNoFeed=1,
    kFormFeedModeFixedPage,
    kFormFeedModeEndOfPage,
    kFormFeedModeEndOfPageRetract
} PJFORMFEEDMODE;

typedef enum
{
    kDensity0 = 0, // start this one at 0 rather than 1. "stringFromDensity" in particular requires this.
    kDensity1,
    kDensity2,
    kDensity3,
    kDensity4,
    kDensity5,
    kDensity6,
    kDensity7,
    kDensity8,
    kDensity9,
    kDensity10,
    kDensityUsePrinterSetting
} PJDENSITY;


typedef enum
{
    kHalftoneThreshold = 1,
    kHalftoneDiffusion
} HALFTONE;

typedef enum
{
    kScaleModeActualSize = 1,
    kScaleModeFitPage,
    kScaleModeFitPageAspects
} SCALEMODE;

typedef enum
{
    kOrientationPortrait = 1,
    kOrientationLandscape
} ORIENTATION;

typedef struct
{
    int top;
    int left;
    int bottom;
    int right;
} MARGINS, *pMARGINS;

@class PJ673PrintSettings;
@protocol PJ673PrintSettingsDelegate <NSObject>
@optional
-(void)pj673SettingsFoundReadyPrinter:(NSNumber*)printerFound;
@end

@interface PJ673PrintSettings : NSObject

@property (nonatomic, copy) NSString *IPAddress;
@property (nonatomic, assign) int IPPort;

@property (nonatomic, assign) SCALEMODE scaleMode;
@property (nonatomic, assign) ORIENTATION orientation;
@property (nonatomic, assign) MARGINS marginDots;

@property (nonatomic, assign) HALFTONE halftone;
// INCREASE this value to make printout darker. Decrease to make it lighter. Default is 128.
@property (nonatomic, assign) Byte threshold;
@property (nonatomic, assign) BOOL compress;


@property (nonatomic, assign) PJPAPERSIZE paperSize;
@property (nonatomic, assign) PJPAPERTYPE paperType;
@property (nonatomic, assign) PJFORMFEEDMODE formFeedMode;
@property (nonatomic,assign) int extraFeed; // used with kFormFeedModeNoFeed only
@property (nonatomic, assign) PJDENSITY density;

@property (nonatomic, copy) NSString *strPaperType;

+(BRPtouchPrintInfo *)defaultPrintInfo;
+(void)hasBrotherAttachedWithDelegate:(id<PJ673PrintSettingsDelegate>)delegate;

-(void)loadPreferences;
-(void)saveIPAddress:(NSString*)address;
-(void)savePaperType:(NSString*)type;

@end
