//
//  SBSDKScanbotMinimalSDK.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 28.06.16.
//  Copyright © 2016 doo GmbH. All rights reserved.
//

#ifndef SBSDKScanbotMinimalSDK
#define SBSDKScanbotMinimalSDK

#import "SBSDKScanbotSDKConstants.h"

#import "ScanbotSDKClass.h"

#import "SBSDKDocumentDetector.h"
#import "SBSDKDocumentDetectorResult.h"
#import "SBSDKDocumentDetectionStatus.h"
#import "SBSDKImageFilterTypes.h"
#import "SBSDKDeviceInformation.h"
#import "SBSDKGeometryUtilities.h"
#import "SBSDKPolygon.h"
#import "SBSDKPolygonEdge.h"

#import "SBSDKCameraSession.h"
#import "SBSDKScannerViewController.h"
#import "SBSDKOrientationLock.h"
#import "SBSDKCropViewController.h"
#import "SBSDKImageEditingViewController.h"
#import "SBSDKPolygonLayer.h"
#import "SBSDKShutterButton.h"
#import "SBSDKDetectionStatusLabel.h"

#import "SBSDKImageProcessor.h"

#import "SBSDKOpticalTextRecognizer.h"
#import "SBSDKOCRResult.h"
#import "SBSDKPageAnalyzerResult.h"

#import "SBSDKPDFRenderer.h"

#import "UIImageSBSDK.h"
#import "UIViewControllerSBSDK.h"

#import "SBSDKImageFileFormat.h"
#import "SBSDKStorageLocation.h"
#import "SBSDKImageStoring.h"
#import "SBSDKImageStorage.h"
#import "SBSDKIndexedImageStorage.h"
#import "SBSDKKeyedImageStorage.h"

#import "SBSDKProcessingQueueFactory.h"
#import "SBSDKProgress.h"

#import "SBSDKImageMetadata.h"
#import "SBSDKImageMetadataProcessor.h"
#import "SBSDKLensCameraProperties.h"

#import "SBSDKTIFFImageWriter.h"

#import "SBSDKMachineReadableCodeMetadata.h"
#import "SBSDKMachineReadableCodeManager.h"
#import "SBSDKMachineReadableCodeParsing.h"
#import "SBSDKMachineReadableCode.h"

#import "SBSDKGenericBarcode.h"
#import "SBSDKGenericQRCode.h"
#import "SBSDKContactQRCode.h"
#import "SBSDKEventQRCode.h"
#import "SBSDKLocationQRCode.h"
#import "SBSDKMailMessageQRCode.h"
#import "SBSDKPhoneNumberQRCode.h"
#import "SBSDKShortMessageQRCode.h"
#import "SBSDKWebURLQRCode.h"
#import "SBSDKWiFiHotspotQRCode.h"

#endif
