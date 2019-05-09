//
//  ePrint.h
//  ePrint Library
//
//  Copyright 2009 MICROTECH. All rights reserved.
//	iphone@microtech.co.jp
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
	ePrintPrintNoError = 0,
	ePrintPrintCancel = -1,
	ePrintPrintOpenError = -2,
	ePrintPrintCommunicationError = -3,
	ePrintMemoryError = -4,
	ePrintPrintSharingError = -5,
	
	ePrintEscprError = -100,
} ePrintError;

typedef enum {
	ePrintPrinterKindUNKNOWN		= 0,
	ePrintPrinterKindESCPAGECOLOR	= 1,
	ePrintPrinterKindESCPAGE		= 2,
	ePrintPrinterKindESCPR			= 3,
	ePrintPrinterKindPOSTSCRIPT		= 4,
	ePrintPrinterKindESCP2			= 5,
	ePrintPrinterKindESCP			= 6,
	ePrintPrinterKindLIPS			= 7,
	ePrintPrinterKindPCL			= 8,
	ePrintPrinterKindPCL3GUI		= 9,
	
	ePrintPrinterKindSharedPrinter	= 100
	
} ePrintPrinterKind;

typedef enum {
	ePrintBonjourCategoryManualIP		= 0,
	ePrintBonjourCategoryPrinter		= 1,
	ePrintBonjourCategoryAirPort		= 2,
	ePrintBonjourCategoryShared			= 3
} ePrintBonjourCategory;

typedef enum {
    ePrintSupportTypeNone				= 0,
    ePrintSupportTypeLpr				= 1 << 0,
    ePrintSupportTypePort9100			= 1 << 1,
    ePrintSupportTypeAirPort			= 1 << 2,
    ePrintSupportTypeSharedPrinter		= 1 << 3
} ePrintSupportType;

#pragma mark -

// print class
@interface ePrint : NSObject {
@private
	NSInteger			_printPageNumber;
	float				_pageProgress;
	float				_jobProgress;
}

// current print page
@property (nonatomic) NSInteger			printPageNumber;
@property (nonatomic) float				pageProgress;

// print
- (void)doPrint:(NSDictionary *)parameter target:(id)draw callback:(SEL)drawCallback;

- (float)jobProgress;

- (void)printCancel;

// printer Information
+ (NSDictionary *)printerInformation:(NSString *)ipAddress;

+ (NSInteger)resolutionFromKind:(NSDictionary *)pdlInformation kind:(NSInteger)kind;
+ (NSString *)pdlNameFromKind:(NSDictionary *)pdlInformation kind:(NSInteger)kind;
+ (NSArray *)mediaFromKind:(NSInteger)kind;
+ (NSArray *)paperSizeFromKind:(NSInteger)kind service:(NSDictionary *)service;

// printer supllies level
+ (NSArray *)printerSupplies:(NSString *)ipAddress bonjourInfo:(NSDictionary *)bonjourInfo;

@end

// doPrint (NSDictionary)
UIKIT_EXTERN NSString * const ePrintParameterBonjourMode;		// Bonjour address mode YES:Bonjour, NO:manual IP address
UIKIT_EXTERN NSString * const ePrintParameterPrinterAddress;	// IP Address (String)
UIKIT_EXTERN NSString * const ePrintParameterPrinterKind;		// Printer kind (Number) ePrintPrinterKind
UIKIT_EXTERN NSString * const ePrintParameterColor;				// Color print (BOOL)
UIKIT_EXTERN NSString * const ePrintParameterPaperCode;			// Paper code (Dictionary) "Code" and "Command"
UIKIT_EXTERN NSString * const ePrintParameterOrientation;		// Orientation (Number) 0:Portrait, 1:Landscape
UIKIT_EXTERN NSString * const ePrintParameterDuplex;			// Duplex (BOOL) page printer only
UIKIT_EXTERN NSString * const ePrintParameterEffect;			// Effect (Number) 0:none, 1:sepia
UIKIT_EXTERN NSString * const ePrintParameterLPRZeroLength;		// LPR Protocol data. Set length is 0.
UIKIT_EXTERN NSString * const ePrintParameterMedia;				// Media type (Number) 0 ... 45 , 91, 92, 93, 99
UIKIT_EXTERN NSString * const ePrintParameterQuality;			// Quality (Number) 0:Draft, 1:Normal, 2:High
UIKIT_EXTERN NSString * const ePrintParameterLayout;			// Layout (Number) 0:Normal, 1:Borderless, 2:Border(3mm)
UIKIT_EXTERN NSString * const ePrintParameterBonjourInformation; // Bonjour information
UIKIT_EXTERN NSString * const ePrintParameterPrinterPort;		//  Print protcol (Number) 0:LPR, 1:Port9100
UIKIT_EXTERN NSString * const ePrintParameterQueueName;			// LPR Queue name (String)
UIKIT_EXTERN NSString * const ePrintParameterPort9100Number;	// Port9100 port number (Number) 
UIKIT_EXTERN NSString * const ePrintParameterTray;				// Feed from specific paper tray. (BOOL) 0:Normal, 1:Specific tray (HP inkjet only)

// printerInformation  (NSDictionary)
// ePrint get printer information from MIB. If printer does't support MIB or correspond OID is not supported,
// it may not get printer information correctly.
UIKIT_EXTERN NSString * const ePrintInformationModelName;		// Model name
UIKIT_EXTERN NSString * const ePrintInformationPDL;				// Printer Description Language (ePrintPrinterKind)
UIKIT_EXTERN NSString * const ePrintInformationPrinterKind;		// Printer kind (Number)
UIKIT_EXTERN NSString * const ePrintInformationDuplex;			// Duplex unit (BOOL)
UIKIT_EXTERN NSString * const ePrintInformationColor;			// Color (BOOL)
UIKIT_EXTERN NSString * const ePrintInformationResolution;		// Resolution (Number)
// Version 2.5
UIKIT_EXTERN NSString * const ePrintInformationSupplies;		// Supplies (Array)

// print complete notification
UIKIT_EXTERN NSString * const ePrintCompleteNotification;


#pragma mark -

// bonjour
@interface ePrintDiscoverPrinter : NSObject {
@private
	NSString		*_address;
	NSString		*_rpString;
	NSString		*_pdl;
	NSString		*_product;
	NSString		*_hostName;

	NSMutableArray		*_services;
	NSMutableDictionary *_serviceDetails;
	NSNetServiceBrowser *_netServiceBrowser;
	NSNetServiceBrowser *_netServiceBrowser2;
	NSNetServiceBrowser *_netServiceBrowser3;
	NSNetServiceBrowser *_netServiceBrowser4;
	NSNetService		*_ipResolve;
	NSInteger			_port;
	BOOL				_result;
	BOOL				_isRun;
	BOOL				_flag;

}

- (BOOL)startDiscover:(ePrintSupportType)supportType;
- (void)stopDiscover;
- (NSString *)nameAtIndex:(NSInteger)index;
- (NSDictionary *)serviceAtIndex:(NSInteger)index;
- (NSInteger)serviceCount;
- (NSInteger)serviceIndex:(NSString *)name;
- (NSString *)printerAddress:(NSDictionary *)serviceInfo port:(NSInteger *)outPort;
- (NSString *)rpString;
- (NSDictionary *)printerInformation:(NSDictionary *)serviceInfo;
+ (ePrintBonjourCategory)bonjourCategory:(NSDictionary *)serviceInfo;
+ (NSString *)bonjourDomain:(NSDictionary *)serviceInfo;
- (NSString *)bonjourHost:(NSDictionary *)serviceInfo;

@end


UIKIT_EXTERN NSString * const ePrintDiscoverPrinterUpdateListNotification;
UIKIT_EXTERN NSString * const ePrintDiscoverPrinterUpdateList2Notification;

