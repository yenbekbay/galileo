@interface AYFeedback : NSObject

@property (nonatomic, readonly) NSString *subject;
@property (nonatomic, readonly) NSString *deviceModel;
@property (nonatomic, readonly) NSString *operatingSystemVersion;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *messageWithMetaData;

@end
