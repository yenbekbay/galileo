#import "AYFeedback.h"

#import <DeviceUtil/DeviceUtil.h>

@implementation AYFeedback

#pragma Initialization;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    _subject = [NSString stringWithFormat:@"%@ %@", self.appName, self.appVersion];
    
    return self;
}

#pragma mark Getters

- (NSString *)deviceModel {
    return [DeviceUtil hardwareDescription];
}

- (NSString *)operatingSystemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)appName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSString *)messageWithMetaData {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"\n\n------\n"];
    [result appendFormat:@"%@: %@ (%@)\n", NSLocalizedString(@"Device", nil), self.deviceModel, self.operatingSystemVersion];
    [result appendFormat:@"%@: %@\n", NSLocalizedString(@"Version", nil), self.appVersion];
    return [result copy];
}

@end
