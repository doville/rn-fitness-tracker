#import "RNFitnessTracker.h"
#import "RNFitnessUtils.h"
#import <CoreMotion/CoreMotion.h>
#import "React/RCTBridge.h"

@interface RNFitnessTracker ()
@property (nonatomic, readonly) CMPedometer *pedometer;
@end

@implementation RNFitnessTracker

@synthesize bridge = _bridge;

- (instancetype)init {
    _pedometer = [CMPedometer new];
    return self;
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(isAuthorizedToUseCoreMotion:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    NSString *status = [self isCoreMotionAuthorized];
    resolve(status);
}

RCT_EXPORT_METHOD(isTrackingSupported:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    BOOL isStepCountingAvailable = [CMPedometer isStepCountingAvailable];
    BOOL isDistanceAvailable = [CMPedometer isDistanceAvailable];
    BOOL isFloorCountingAvailable = [CMPedometer isFloorCountingAvailable];
    
    resolve(@[isStepCountingAvailable ? @true : @false, isDistanceAvailable ? @true : @false, isFloorCountingAvailable? @true : @false]);
}

RCT_EXPORT_METHOD(isStepTrackingSupported:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    BOOL isStepTrackingAvailable = [CMPedometer isStepCountingAvailable];
    if (isStepTrackingAvailable == YES) {
        resolve(@true);
    } else {
        resolve(@false);
    }
}


RCT_EXPORT_METHOD(isDistanceTrackingSupported:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    BOOL isDistanceTrackingAvailable = [CMPedometer isDistanceAvailable];
    if (isDistanceTrackingAvailable == YES) {
        resolve(@true);
    } else {
        resolve(@false);
    }
}

RCT_EXPORT_METHOD(isFloorCountingSupported:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    BOOL isFloorCountingAvailable = [CMPedometer isFloorCountingAvailable];
    if (isFloorCountingAvailable == YES) {
        resolve(@true);
    } else {
        resolve(@false);
    }
}



RCT_EXPORT_METHOD(authorize:(RCTPromiseResolveBlock) resolve :
                  (RCTPromiseRejectBlock) reject) {
    BOOL isStepCountAvailable = [CMPedometer isStepCountingAvailable];
    if (isStepCountAvailable == YES) {
        NSDate *now = [NSDate new];
        NSDate *startDate = [RNFitnessUtils beginningOfDay:now];
        [_pedometer queryPedometerDataFromDate:(NSDate *)startDate toDate:(NSDate *)now withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error == nil) {
                resolve(@true);
            } else {
                resolve(@false);
            }
        }];
    } else {
        resolve(@false);
    }
}

-(void) rejectError:
(NSError * _Nullable) error :
(RCTPromiseRejectBlock) reject {
    reject([@(error.code) stringValue], error.localizedDescription, error);
}

-(void) pedometerUnavailable:
(RCTPromiseRejectBlock) reject {
    NSError * _Nullable error;
    reject(@"0", @"Pedometer unavailable", error);
}

-(void) queryPedometerData:
(NSDate *) startDate :
(NSDate *) endDate :
(int) dataType :
(RCTPromiseResolveBlock) resolve :
(RCTPromiseRejectBlock) reject {
    [_pedometer queryPedometerDataFromDate:(NSDate *)startDate toDate:(NSDate *)endDate withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        if (error == nil) {
            NSNumber *steps = pedometerData.numberOfSteps;
            NSNumber *distance = pedometerData.distance;
            NSNumber *flights = pedometerData.floorsAscended;
            NSArray *data = (@[steps, distance, flights]);
            resolve(data[dataType]);
        } else {
            [self rejectError:error :reject];
        }
    }];
}


-(void) getTodaysData:
(int) dataType :
(RCTPromiseResolveBlock) resolve :
(RCTPromiseRejectBlock) reject {
    if (_pedometer) {
        NSDate *now = [NSDate new];
        NSDate *startDate = [RNFitnessUtils beginningOfDay:now];
        [self queryPedometerData:startDate :now :dataType :resolve :reject];
    } else {
        [self pedometerUnavailable:reject];
    }
}

RCT_EXPORT_METHOD(getStepsToday:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getTodaysData:0 :resolve :reject];
}
RCT_EXPORT_METHOD(getDistanceToday:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getTodaysData:1 :resolve :reject];
}
RCT_EXPORT_METHOD(getFloorsToday:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getTodaysData:2 :resolve :reject];
}


-(void) getWeekTotalData:
(int) dataType :
(RCTPromiseResolveBlock) resolve :
(RCTPromiseRejectBlock) reject {
    if (_pedometer) {
        NSDate *now = [NSDate new];
        NSDate *todayStart = [RNFitnessUtils beginningOfDay:now];
        NSDate *sevenDaysAgo = [RNFitnessUtils daysAgo: todayStart :7];
        
        [self queryPedometerData:sevenDaysAgo :now :dataType :resolve :reject];
    } else {
        [self pedometerUnavailable:reject];
    }
}

RCT_EXPORT_METHOD(getStepsWeekTotal:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getWeekTotalData :0 :resolve :reject];
}
RCT_EXPORT_METHOD(getDistanceWeekTotal:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getWeekTotalData :1 :resolve :reject];
}
RCT_EXPORT_METHOD(getFloorsWeekTotal:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    [self getWeekTotalData :2 :resolve :reject];
}


RCT_EXPORT_METHOD(getStepsDaily:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    if (_pedometer) {
        [self getDailyWeekData :[NSDate new] :0 :0 :[NSMutableDictionary new] :resolve :reject];
    } else {
        [self pedometerUnavailable:reject];
    }
}

RCT_EXPORT_METHOD(getDistanceDaily:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    if (_pedometer) {
        [self getDailyWeekData:[NSDate new] :0 :1 :[NSMutableDictionary new] :resolve :reject];
    } else {
        [self pedometerUnavailable:reject];
    }
}

RCT_EXPORT_METHOD(getFloorsDaily:(RCTPromiseResolveBlock) resolve :(RCTPromiseRejectBlock) reject) {
    if (_pedometer) {
        [self getDailyWeekData :[NSDate new] :0 :2 :[NSMutableDictionary new] :resolve :reject];
    } else {
        [self pedometerUnavailable :reject];
    }
}


-(void) getDailyWeekData:
(NSDate *)date :
(int) count :
(int) dataType :
(NSMutableDictionary *) data :
(RCTPromiseResolveBlock) resolve :
(RCTPromiseRejectBlock) reject {
    NSDate *start = [RNFitnessUtils beginningOfDay: date];
    NSDate *end = [RNFitnessUtils endOfDay: date];
    
    [_pedometer queryPedometerDataFromDate:(NSDate *)start toDate:(NSDate *)end withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        if (error == nil) {
            if (count < 7) {
                NSNumber *steps = pedometerData.numberOfSteps;
                NSNumber *distance = pedometerData.distance;
                NSNumber *flights = pedometerData.floorsAscended;
                NSArray *fitnessData = @[steps, distance, flights];
                NSString *dateString = [RNFitnessUtils formatIsoDateString:date];
                [data setValue:fitnessData[dataType] forKey:dateString];
                NSDate *previousDay = [RNFitnessUtils daysAgo: date :1];
                int newCount = count + 1;
                [self getDailyWeekData:previousDay :newCount :dataType :data :resolve :reject];
            } else {
                resolve(data);
            }
        } else {
            [self rejectError:error :reject];
        }
    }];
}

-(NSString *) isCoreMotionAuthorized {
    if (@available(iOS 11.0, *)) {
        CMAuthorizationStatus status = [CMPedometer authorizationStatus];
        if (status == CMAuthorizationStatusAuthorized) {
            return @"authorized";
        } else if (status == CMAuthorizationStatusNotDetermined) {
            return @"notDetermined";
        } else if (status == CMAuthorizationStatusDenied) {
            return @"denied";
        } else if (status == CMAuthorizationStatusRestricted) {
            return @"restricted";
        }
    } else {
        if([CMSensorRecorder isAuthorizedForRecording]) {
            return @"authorized";
        } else {
            return @"unauthorized";
        }
    }
    return @"undefined";
}

@end
