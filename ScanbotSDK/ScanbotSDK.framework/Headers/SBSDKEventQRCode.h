//
//  SBSDKEventQRCode.h
//  ScanbotSDK
//
//  Created by Sebastian Husche on 24.06.14.
//  Copyright (c) 2014 doo. All rights reserved.
//

#import "SBSDKMachineReadableCode.h"
#import <EventKit/EventKit.h>

/**
 * A specific subclass of SBSDKMachineReadableCode that represents a QR codes with iCal compatible
 * events (VCALENDER: VEVENT:).
 */
@interface SBSDKEventQRCode : SBSDKMachineReadableCode

/**
 * The shared EKEventStore instance which is needed to add events to the calendar.
 */
+ (EKEventStore *)sharedEventStore;

/**
 * Returns a new instance of an EventKit event that can be added to the calendar.
 */
@property(nonatomic, readonly) EKEvent *event;

/**
 * The summary or title of the event.
 */
@property(nonatomic, copy) NSString *summary;

/**
 * The location of the event. Can be a rooms name or an adress.
 */
@property(nonatomic, copy) NSString *location;

/**
 * The notes of the event. A longer description of the event.
 */
@property(nonatomic, copy) NSString *notes;

/**
 * The URL of the event. A website regarding the event.
 */
@property(nonatomic, strong) NSURL *url;

/**
 * The start date and time of the event. Must not be nil.
 */
@property(nonatomic, strong) NSDate *startDate;

/**
 * The end date and time of the event. Is nil if allDay is YES.
 */
@property(nonatomic, strong) NSDate *endDate;

/**
 * Wether the event is an all day event or not. Is set automatically on initialization
 * if the event contains no end date or if start date and end date are equal.
 */
@property(nonatomic, assign) BOOL allDay;

/**
 * The final timezone the event takes places in.
 */
@property(nonatomic, strong) NSTimeZone *timezone;


/**
 * The recurrence rule of the event.
 */
@property(nonatomic, strong) EKRecurrenceRule *recurrenceRule;

@end
