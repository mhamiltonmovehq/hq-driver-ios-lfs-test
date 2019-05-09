//
//  PVOScanbotViewController.m
//  Survey
//
//  Created by Brian Prescott on 9/19/17.
//
//

#import "PVOScanbotViewController.h"

#import "GPUImage.h"
#import "Prefs.h"
#import "SurveyAppDelegate.h"
#import "UIImage+Utilities.h"

@interface PVOScanbotViewController ()

@property (nonatomic, retain) SBSDKScannerViewController *scannerViewController;
@property (nonatomic) BOOL viewAppeared;
@property (nonatomic, retain) CNPPopupController *popupController;
@property (nonatomic, retain) UIImageView *previewImageView;
@property (nonatomic, retain) UIScrollView *previewScrollView;
@property (nonatomic, retain) UIImage *outputImage;
@property (nonatomic) BOOL torchIsOn;
@property (nonatomic) BOOL scanbotDebugging;
@property (nonatomic) CGFloat brightnessSetting;
@property (nonatomic) CGFloat contrastSetting;
@property (nonatomic) CGFloat sharpnessSetting;
@property (nonatomic, retain) UISlider *brightnessSlider, *contrastSlider, *sharpnessSlider;
@property (nonatomic, retain) UILabel *brightnessLabel, *contrastLabel, *sharpnessLabel;

@end

@implementation PVOScanbotViewController

- (BOOL)deviceHasTorch
{
    BOOL retval = NO;
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        retval = ([device hasTorch] && [device hasFlash]);
    }
    
    return retval;
}

- (void)turnTorchOn:(BOOL)on
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash])
        {
            [device lockForConfiguration:nil];
            if (on)
            {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                _torchIsOn = YES;
            }
            else
            {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                _torchIsOn = NO;
            }
            
            [device unlockForConfiguration];
        }
    }
}

- (void)flashButton
{
    [self turnTorchOn:!_torchIsOn];
}

- (void)updateSettingsLabels
{
    _brightnessLabel.text = [NSString stringWithFormat:@"B: %.2f", _brightnessSetting];
    _contrastLabel.text = [NSString stringWithFormat:@"C: %.2f", _contrastSetting];
    _sharpnessLabel.text = [NSString stringWithFormat:@"S: %.2f", _sharpnessSetting];
}

- (void)brightnessSliderValueChanged:(UISlider *)sender
{
    _brightnessSetting = sender.value;
    [self updateSettingsLabels];
}

- (void)contrastSliderValueChanged:(UISlider *)sender
{
    _contrastSetting = sender.value;
    [self updateSettingsLabels];
}

- (void)sharpnessSliderValueChanged:(UISlider *)sender
{
    _sharpnessSetting = sender.value;
    [self updateSettingsLabels];
}

- (void)dismissController
{
    if (_delegate && [_delegate respondsToSelector:@selector(documentImageCancelled)])
    {
        [_delegate documentImageCancelled];
    }
}

- (CNPPopupButton *)createPopupButton:(NSString *)buttonText
{
    CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 25.0)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [button setTitle:buttonText forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:0.46 green:0.8 blue:1.0 alpha:1.0];
    button.layer.cornerRadius = 4;
    return button;
}

- (UIImage *)preprocessImage:(UIImage *)originalImage
{
    UIImage *step1 = [originalImage imageWithContrast:_contrastSetting brightness:_brightnessSetting];
    
    GPUImageSharpenFilter *sharpenFilter = [[GPUImageSharpenFilter alloc] init];
    sharpenFilter.sharpness = _sharpnessSetting;
    UIImage *step2 = [sharpenFilter imageByFilteringImage:step1];
    
//    GPUImageUnsharpMaskFilter *unsharpMaskFilter = [[GPUImageUnsharpMaskFilter alloc] init];
//    unsharpMaskFilter.intensity = 1.0;
//    UIImage *step3 = [unsharpMaskFilter imageByFilteringImage:step2];
    
    //UIImage *step3 = [step2 imageWithContrast:_contrastSetting brightness:_brightnessSetting];
    
    //UIImage *outputImage2 = [outputImage1 blackAndWhiteImage];
    
    //self.outputImage = [outputImage1 imageWithAutoLevels];
    //self.outputImage = outputImage1;
    //UIImage *outputImage = [outputImage1 imageWithBrightness:-0.5];
    //UIImage *outputImage = [outputImage1 imageWithContrast:0.5];
    
    //        GPUImageMonochromeFilter *monochromeFilter = [[GPUImageMonochromeFilter alloc] init];
    //        self.outputImage = [monochromeFilter imageByFilteringImage:outputImage1];
    
    UIImage *preprocessedImage = step2;
    
    return preprocessedImage;
}

- (void)displayConfirmationWithGrayFilter:(UIImage *)originalImage
{
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Confirmation" attributes:@ { NSFontAttributeName : [UIFont boldSystemFontOfSize:16] }];
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = title;
    
    UIImage *preprocessedImage = [self preprocessImage:originalImage];
    
    [SBSDKImageProcessor filterImage:preprocessedImage filter:SBSDKImageFilterTypeBinarized completion:^(BOOL finished, NSError *error, NSDictionary *resultInfo) {
        self.outputImage = (UIImage *)resultInfo[SBSDKResultInfoDestinationImageKey];
        
        self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 250.0)];
        _previewImageView.image = _outputImage;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _previewImageView.opaque = YES;
        
        self.previewScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 250.0, 250.0)];
        _previewScrollView.minimumZoomScale = 1.0;
        _previewScrollView.maximumZoomScale = 8.0;
        _previewScrollView.contentSize = _previewImageView.frame.size;
        _previewScrollView.delegate = self;
        _previewScrollView.layer.borderWidth = 1.0;
        _previewScrollView.layer.borderColor = [UIColor grayColor].CGColor;
        [_previewScrollView addSubview:_previewImageView];
        
        CNPPopupButton *acceptButton = [self createPopupButton:@"Accept"];
        acceptButton.selectionHandler = ^(CNPPopupButton *button){
            [self imageWasConfirmed:_outputImage];
            [_popupController dismissPopupControllerAnimated:YES];
        };
        
        CNPPopupButton *retakeButton = [self createPopupButton:@"Retake"];
        retakeButton.selectionHandler = ^(CNPPopupButton *button){
            [_popupController dismissPopupControllerAnimated:YES];
        };
        
        self.popupController = [[CNPPopupController alloc] initWithContents:@ [ titleLabel, _previewScrollView, acceptButton, retakeButton ]];
        _popupController.theme = [CNPPopupTheme defaultTheme];
        _popupController.theme.popupStyle = CNPPopupStyleCentered;
        _popupController.delegate = self;
        [_popupController presentPopupControllerAnimated:YES];
    }];
}

- (void)imageWasConfirmed:(UIImage *)image
{
    if (_delegate && [_delegate respondsToSelector:@selector(documentImageCaptured:)])
    {
        [_delegate documentImageCaptured:image];
    }
}

#pragma mark - SBSDKScannerViewControllerDelegate

- (BOOL)scannerControllerShouldAnalyseVideoFrame:(SBSDKScannerViewController *)controller
{
    return self.viewAppeared && self.presentedViewController == nil;
}

- (void)scannerController:(SBSDKScannerViewController *)controller didCaptureDocumentImage:(UIImage *)documentImage
{
    [self displayConfirmationWithGrayFilter:documentImage];
}

- (UIView *)scannerController:(SBSDKScannerViewController *)controller viewForDetectionStatus:(SBSDKDocumentDetectionStatus)status
{
    return nil;
}

- (UIColor *)scannerController:(SBSDKScannerViewController *)controller polygonColorForDetectionStatus:(SBSDKDocumentDetectionStatus)status
{
    if (status == SBSDKDocumentDetectionStatusOK)
    {
        return [UIColor greenColor];
    }
    
    return [UIColor redColor];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.previewImageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _scanbotDebugging = ([Prefs betaPassword] != nil && [[Prefs betaPassword] rangeOfString:@"debugScanbot"].location != NSNotFound);
    //_scanbotDebugging = YES;
    
    self.scannerViewController = [[SBSDKScannerViewController alloc] initWithParentViewController:self imageStorage:nil];
    
    _scannerViewController.delegate = self;
    _scannerViewController.imageScale = 1.0f;
    
    _scannerViewController.autoCaptureSensitivity = 0.9;
    _scannerViewController.acceptedSizeScore = 80.0;
    _scannerViewController.acceptedAngleScore = 80.0;
    //_scannerViewController.imageMode = SBSDKImageModeGrayscale;
    
#define BUTTON_WIDTH        70.0
#define BUTTON_X_PADDING    10.0
#define BUTTON_HEIGHT       30.0
#define BUTTON_Y            30.0
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(BUTTON_X_PADDING, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor grayColor];
    cancelButton.layer.cornerRadius = 5.0;
    cancelButton.clipsToBounds = YES;
    [cancelButton addTarget:self action:@selector(dismissController) forControlEvents:UIControlEventTouchUpInside];
    [self.scannerViewController.view addSubview:cancelButton];
    
    if ([self deviceHasTorch])
    {
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(320.0 - BUTTON_WIDTH - BUTTON_X_PADDING, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)];
        [flashButton setTitle:@"Flash" forState:UIControlStateNormal];
        flashButton.backgroundColor = [UIColor grayColor];
        flashButton.layer.cornerRadius = 5.0;
        flashButton.clipsToBounds = YES;
        [flashButton addTarget:self action:@selector(flashButton) forControlEvents:UIControlEventTouchUpInside];
        [self.scannerViewController.view addSubview:flashButton];
    }
    
#define SLIDER_WIDTH            140.0
#define SLIDER_LABEL_Y_OFFSET   30.0
#define SLIDER_Y                460.0
#define SLIDER_LABEL_Y          (SLIDER_Y - SLIDER_LABEL_Y_OFFSET)
#define SLIDER_LABEL_WIDTH      100.0
#define SHARPNESS_Y             (SLIDER_Y - 140.0)
#define SHARPNESS_LABEL_Y       (SHARPNESS_Y - SLIDER_LABEL_Y_OFFSET)
    
    _brightnessSetting = 0.20;
    _contrastSetting = 0.77;
    _sharpnessSetting = 1.70;

    if (_scanbotDebugging)
    {
        self.sharpnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(BUTTON_X_PADDING, SHARPNESS_Y, SLIDER_WIDTH, 10.0)];
        _sharpnessSlider.minimumValue = 0.0;
        _sharpnessSlider.maximumValue = 4.0;
        _sharpnessSlider.value = _sharpnessSetting;
        [self.scannerViewController.view addSubview:_sharpnessSlider];
        [_sharpnessSlider addTarget:self action:@selector(sharpnessSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        self.sharpnessLabel = [UILabel alloc] initWithFrame:CGRectMake(BUTTON_X_PADDING, SHARPNESS_LABEL_Y, SLIDER_LABEL_WIDTH, 20.0)];
        _sharpnessLabel.text = @"";
        _sharpnessLabel.textColor = [UIColor whiteColor];
        _sharpnessLabel.textAlignment = NSTextAlignmentLeft;
        [self.scannerViewController.view addSubview:_sharpnessLabel];
        
        self.brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(BUTTON_X_PADDING, SLIDER_Y, SLIDER_WIDTH, 10.0)];
        _brightnessSlider.minimumValue = -1.0;
        _brightnessSlider.maximumValue = 1.0;
        _brightnessSlider.value = _brightnessSetting;
        [self.scannerViewController.view addSubview:_brightnessSlider];
        [_brightnessSlider addTarget:self action:@selector(brightnessSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        self.brightnessLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUTTON_X_PADDING, SLIDER_LABEL_Y, SLIDER_LABEL_WIDTH, 20.0)];
        _brightnessLabel.text = @"";
        _brightnessLabel.textColor = [UIColor whiteColor];
        _brightnessLabel.textAlignment = NSTextAlignmentLeft;
        [self.scannerViewController.view addSubview:_brightnessLabel];
        
        self.contrastSlider = [[UISlider alloc] initWithFrame:CGRectMake(320.0 - BUTTON_X_PADDING - SLIDER_WIDTH, SLIDER_Y, SLIDER_WIDTH, 10.0)];
        _contrastSlider.minimumValue = 0.0;
        _contrastSlider.maximumValue = 1.0;
        _contrastSlider.value = _contrastSetting;
        [_contrastSlider addTarget:self action:@selector(contrastSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scannerViewController.view addSubview:_contrastSlider];
        
        self.contrastLabel = [[UILabel alloc] initWithFrame:CGRectMake(320.0 - BUTTON_X_PADDING - SLIDER_LABEL_WIDTH, SLIDER_LABEL_Y, SLIDER_LABEL_WIDTH, 20.0)];
        _contrastLabel.text = @"";
        _contrastLabel.textColor = [UIColor whiteColor];
        _contrastLabel.textAlignment = NSTextAlignmentRight;
        [self.scannerViewController.view addSubview:_contrastLabel];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.viewAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_scanbotDebugging)
    {
        [self updateSettingsLabels];
    }
    
    self.viewAppeared = YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//- (void)dealloc
//{
//    [_scannerViewController release];
//    [_popupController release];
//    [_previewImageView release];
//    [_previewScrollView release];
//    [_outputImage release];
//    [_brightnessLabel release];
//    [_brightnessSlider release];
//    [_contrastLabel release];
//    [_contrastSlider release];
//    [_sharpnessLabel release];
//    [_sharpnessSlider release];
//
//    [super dealloc];
//}

@end
